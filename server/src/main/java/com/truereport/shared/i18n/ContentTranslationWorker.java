package com.truereport.shared.i18n;

import com.truereport.shared.i18n.ContentTranslationStore.RegistryField;
import com.truereport.shared.i18n.ContentTranslationStore.TranslationRow;
import com.truereport.shared.i18n.TranslationGlossaryStore.Entry;
import com.truereport.shared.i18n.TranslationJobStore.JobRow;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import javax.sql.DataSource;
import java.sql.Connection;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Single worker loop with short claim/persist transactions. The provider call
 * runs outside any transaction; a provider failure never rolls back the claim.
 */
@Service
public class ContentTranslationWorker {

    private static final Logger log = LoggerFactory.getLogger(ContentTranslationWorker.class);

    /** A hostile {@code Retry-After} must not park the worker for a day. */
    private static final long MAX_RATE_LIMIT_PAUSE_SECONDS = 900;

    private final ContentTranslationStore translations;
    private final TranslationJobStore jobs;
    private final ContentSourceCatalog sources;
    private final ContentChangePublisher changes;
    private final LanguageCatalog languages;
    private final ContentTranslationService service;
    private final ContentProtector protector;
    private final TranslationGlossaryStore glossary;
    private final ObjectProvider<TranslationProvider> provider;
    private final TransactionTemplate transaction;
    private final boolean enabled;
    private final boolean skipLocked;
    private final int batchSize;
    private final int maxAttempts;
    private final int backoffSeconds;
    private final int staleTimeoutSeconds;

    /** Set when the provider answered 429; every pass is skipped until it elapses. */
    private volatile Instant pausedUntil = Instant.EPOCH;

    public ContentTranslationWorker(ContentTranslationStore translations,
                                    TranslationJobStore jobs,
                                    ContentSourceCatalog sources,
                                    ContentChangePublisher changes,
                                    LanguageCatalog languages,
                                    ContentTranslationService service,
                                    ContentProtector protector,
                                    TranslationGlossaryStore glossary,
                                    ObjectProvider<TranslationProvider> provider,
                                    PlatformTransactionManager transactionManager,
                                    DataSource dataSource,
                                    @Value("${truereport.i18n.translation.worker-enabled:true}")
                                    boolean enabled,
                                    @Value("${truereport.i18n.translation.batch-size:25}")
                                    int batchSize,
                                    @Value("${truereport.i18n.translation.max-attempts:3}")
                                    int maxAttempts,
                                    @Value("${truereport.i18n.translation.backoff-seconds:30}")
                                    int backoffSeconds,
                                    @Value("${truereport.i18n.translation.stale-timeout-seconds:300}")
                                    int staleTimeoutSeconds) {
        this.translations = translations;
        this.jobs = jobs;
        this.sources = sources;
        this.changes = changes;
        this.languages = languages;
        this.service = service;
        this.protector = protector;
        this.glossary = glossary;
        this.provider = provider;
        this.transaction = new TransactionTemplate(transactionManager);
        this.enabled = enabled;
        this.batchSize = Math.max(1, batchSize);
        this.maxAttempts = Math.max(1, maxAttempts);
        this.backoffSeconds = Math.max(0, backoffSeconds);
        this.staleTimeoutSeconds = Math.max(1, staleTimeoutSeconds);
        this.skipLocked = isMySql(dataSource);
    }

    @Scheduled(fixedDelayString = "${truereport.i18n.translation.fixed-delay-ms:15000}")
    public void scheduled() {
        if (!enabled) {
            return;
        }
        try {
            workOnce();
        } catch (RuntimeException exception) {
            log.warn("Translation worker pass failed: {}", exception.getMessage(), exception);
        }
    }

    /**
     * One pass: claim (short tx) → provider (no tx) → persist (short tx).
     * Tests call this directly; the scheduler is disabled in tests.
     */
    public int workOnce() {
        TranslationProvider active = provider.getIfAvailable();
        if (active == null) {
            return 0;
        }
        if (Instant.now().isBefore(pausedUntil)) {
            return 0;
        }
        transaction.executeWithoutResult(status -> jobs.recoverStale(staleTimeoutSeconds));
        List<JobRow> claimed = transaction.execute(status -> claim());
        if (claimed == null || claimed.isEmpty()) {
            return 0;
        }
        Map<String, List<JobRow>> groups = new LinkedHashMap<>();
        for (JobRow job : claimed) {
            groups.computeIfAbsent(job.direction() + "|" + job.lang(),
                    key -> new ArrayList<>()).add(job);
        }
        int processed = 0;
        for (List<JobRow> group : groups.values()) {
            try {
                List<Outcome> outcomes = translateGroup(active, group);
                transaction.executeWithoutResult(status -> persist(outcomes));
            } catch (RuntimeException exception) {
                transaction.executeWithoutResult(status -> retryGroup(group, exception));
            }
            processed += group.size();
        }
        return processed;
    }

    private List<JobRow> claim() {
        List<JobRow> due = jobs.due(claimLimit(), skipLocked);
        for (JobRow job : due) {
            jobs.markRunning(job.id());
        }
        return due;
    }

    private List<Outcome> translateGroup(TranslationProvider provider, List<JobRow> group) {
        JobRow first = group.get(0);
        String sourceLang;
        String targetLang;
        if (TranslationJobStore.TO_CANONICAL.equals(first.direction())) {
            sourceLang = first.lang();
            targetLang = languages.defaultLanguage();
        } else {
            sourceLang = languages.defaultLanguage();
            targetLang = first.lang();
        }
        List<Entry> entries = glossary.find(sourceLang, targetLang);
        List<ContentProtector.GlossaryTerm> locked = entries.stream()
                .filter(Entry::locked)
                .map(entry -> new ContentProtector.GlossaryTerm(entry.term(), entry.translation(),
                        entry.caseSensitive(), true))
                .toList();

        List<Prepared> inputs = new ArrayList<>();
        List<Outcome> outcomes = new ArrayList<>();
        for (JobRow job : group) {
            String source = sourceText(job);
            if (source == null || source.isBlank()) {
                outcomes.add(new Outcome(job, null, null, null));
                continue;
            }
            if (alreadyCurrent(job, source, targetLang)) {
                outcomes.add(new Outcome(job, source, null, null));
                continue;
            }
            String patterns = translations.field(job.entityType(), job.field())
                    .map(RegistryField::protectPatterns).orElse(null);
            ContentProtector.Protection protection = protector.protect(source, patterns, locked);
            inputs.add(new Prepared(job, source, protection,
                    normalizeAmpersands(protection.text()), entries));
        }
        for (int start = 0; start < inputs.size(); start += batchSize) {
            List<Prepared> chunk = inputs.subList(start, Math.min(inputs.size(), start + batchSize));
            List<String> texts = chunk.stream().map(Prepared::providerText).toList();
            Map<String, String> translated = provider.translate(texts, sourceLang, targetLang);
            validate(texts, translated);
            for (Prepared input : chunk) {
                try {
                    // Post-edit runs while placeholders are still tokens, so it can
                    // never rewrite a restored URL/VIN/measurement or another token.
                    String edited = glossary.applyPostEdit(
                            translated.get(input.providerText()), input.entries());
                    String restored = protector.restore(edited, input.protection());
                    outcomes.add(new Outcome(input.job(), input.source(), restored, null));
                } catch (ContentProtector.PlaceholderLostException exception) {
                    outcomes.add(new Outcome(input.job(), input.source(), null,
                            exception.getMessage()));
                }
            }
        }
        return outcomes;
    }

    private void persist(List<Outcome> outcomes) {
        TranslationProvider active = provider.getIfAvailable();
        String providerId = active == null ? "unknown" : active.id();
        for (Outcome outcome : outcomes) {
            JobRow job = outcome.job();
            // Interface labels are short and often legitimately identical across
            // languages, so prose guards would reject good translations.
            boolean lenient = sources.lenientMachineGuards(job.entityType());
            if (outcome.error() != null) {
                jobs.markFailed(job.id(), outcome.error());
                continue;
            }
            if (outcome.output() == null) {
                jobs.markDone(job.id());
                continue;
            }
            if (TranslationJobStore.TO_CANONICAL.equals(job.direction())) {
                if (unchanged(outcome.source(), outcome.output())) {
                    // The provider echoed the authored text instead of deriving
                    // English; writing it would corrupt the canonical column.
                    jobs.markFailed(job.id(), "NO_CHANGE");
                    continue;
                }
                boolean updated = sources.updateSource(job.entityType(), job.entityId(),
                        job.field(), outcome.output());
                if (!updated) {
                    jobs.markFailed(job.id(), "Cannot update canonical source for "
                            + job.entityType() + "." + job.field());
                    continue;
                }
                translations.upsert(job.entityType(), job.entityId(), job.field(), languages.defaultLanguage(),
                        outcome.output(), "MACHINE", "PENDING_REVIEW", job.lang(),
                        service.hash(outcome.output()), providerId, null);
                translations.upsert(job.entityType(), job.entityId(), job.field(), job.lang(),
                        outcome.source(), "AUTHORED", "REVIEWED", job.lang(),
                        service.hash(outcome.output()), null, null);
                changes.canonicalChanged(job.entityType(), job.entityId(), job.field(),
                        outcome.output(), job.lang());
            } else if (!lenient && unchanged(outcome.source(), outcome.output())) {
                // The provider returned the source (or only changed case/spacing).
                // Storing it would serve English as if it were translated, and the
                // job must not retry forever.
                translations.delete(job.entityType(), job.entityId(), job.field(), job.lang());
                service.invalidate(job.entityType(), job.entityId());
                jobs.markFailed(job.id(), "NO_CHANGE");
                continue;
            } else if (truncated(outcome.source(), outcome.output(),
                    lenient && shortLabel(outcome.source()))) {
                // The provider dropped content (short output or a dangling
                // conjunction). Never store it; a later run can retry after the
                // provider/glossary is fixed. Short labels skip the word-count
                // ratio: French and German often need fewer words than English.
                translations.delete(job.entityType(), job.entityId(), job.field(), job.lang());
                service.invalidate(job.entityType(), job.entityId());
                jobs.markFailed(job.id(), "TRUNCATED");
                continue;
            } else {
                translations.upsert(job.entityType(), job.entityId(), job.field(), job.lang(),
                        outcome.output(), "MACHINE", "PENDING_REVIEW",
                        languages.defaultLanguage(), service.hash(outcome.source()),
                        providerId, null);
            }
            service.invalidate(job.entityType(), job.entityId());
            jobs.markDone(job.id());
        }
    }

    private void retryGroup(List<JobRow> group, RuntimeException exception) {
        String message = exception.getMessage() == null
                ? exception.getClass().getSimpleName() : exception.getMessage();
        boolean retryable = !(exception instanceof TranslationProviderException providerException)
                || providerException.retryable();
        long retryAfter = exception instanceof TranslationProviderException providerException
                ? providerException.retryAfterSeconds() : 0;
        if (retryable && retryAfter > 0) {
            // The provider told us when to come back (429 Retry-After). Pause
            // every language so we do not keep hammering it, and requeue this
            // batch for that moment without spending a retry attempt: the work
            // resumes exactly where it stopped.
            long delay = Math.min(retryAfter, MAX_RATE_LIMIT_PAUSE_SECONDS);
            pausedUntil = Instant.now().plusSeconds(delay);
            LocalDateTime resumeAt = LocalDateTime.now().plusSeconds(delay);
            for (JobRow job : group) {
                jobs.requeueRateLimited(job.id(), resumeAt);
            }
            log.warn("Translation provider rate limited ({}); pausing {}s and resuming "
                    + "{} job(s) at {}", message, delay, group.size(), resumeAt);
            return;
        }
        log.warn("Translation batch failed for {} job(s) (retryable={}): {}",
                group.size(), retryable, message);
        for (JobRow job : group) {
            if (!retryable) {
                jobs.markFailed(job.id(), message);
                continue;
            }
            int attempts = job.attempts() + 1;
            if (attempts >= maxAttempts) {
                jobs.markFailed(job.id(), message);
            } else {
                long delay = (long) backoffSeconds * attempts;
                jobs.markPending(job.id(), LocalDateTime.now().plusSeconds(delay));
            }
        }
    }

    private String sourceText(JobRow job) {
        if (TranslationJobStore.TO_CANONICAL.equals(job.direction())) {
            return translations.find(job.entityType(), job.entityId(), job.field(), job.lang())
                    .map(TranslationRow::body).orElse(null);
        }
        return sources.source(job.entityType(), job.entityId(), job.field(),
                languages.defaultLanguage());
    }

    private boolean alreadyCurrent(JobRow job, String source, String targetLang) {
        String hash = service.hash(source);
        if (TranslationJobStore.FROM_CANONICAL.equals(job.direction())) {
            return translations.find(job.entityType(), job.entityId(), job.field(), job.lang())
                    .map(row -> !"STALE".equals(row.status())
                            && row.body() != null && !row.body().isBlank()
                            && hash.equals(row.sourceHash()))
                    .orElse(false);
        }
        // TO_CANONICAL: skip when the canonical column already matches the
        // derived row (and that row was not marked STALE by a newer authoring write).
        TranslationRow canonical = translations.find(job.entityType(), job.entityId(),
                job.field(), targetLang).orElse(null);
        if (canonical == null || "STALE".equals(canonical.status())
                || canonical.body() == null || canonical.body().isBlank()) {
            return false;
        }
        String canonicalText = sources.source(job.entityType(), job.entityId(), job.field(),
                targetLang);
        return canonical.body().equals(canonicalText);
    }

    /**
     * Turn a textual ampersand into the word "and" before the provider sees it.
     * URLs/codes/VINs are already placeholders, so their {@code &} is untouched.
     * LibreTranslate otherwise drops the word after {@code &} or turns it into a
     * quote.
     */
    static String normalizeAmpersands(String text) {
        String value = text == null ? "" : text;
        return value.replaceAll("\\s*&\\s*", " and ").replaceAll("[ \\t]{2,}", " ");
    }

    /**
     * True when the provider carried no translation: same text after trimming,
     * collapsing whitespace and case folding. A translated sentence that happens
     * to contain a product name is not affected.
     */
    static boolean unchanged(String source, String output) {
        return normalizeForComparison(source).equals(normalizeForComparison(output));
    }

    /**
     * Content-loss guard: less than 60% of the source words, or a dangling
     * conjunction/punctuation left by the model. {@code shortLabelExempt} skips
     * only the word-count ratio, for interface labels that compress naturally.
     */
    static boolean truncated(String source, String output, boolean shortLabelExempt) {
        String candidate = output == null ? "" : output.trim();
        if (candidate.isEmpty()) {
            return source != null && !source.isBlank();
        }
        int sourceWords = wordCount(source);
        if (!shortLabelExempt && sourceWords >= 2 && wordCount(candidate) * 5 < sourceWords * 3) {
            return true;
        }
        String tail = candidate.toLowerCase(java.util.Locale.ROOT);
        if (tail.endsWith("&") || tail.endsWith(",") || tail.endsWith(";")
                || tail.endsWith("-")) {
            return true;
        }
        return tail.matches(".*\\b(and|y)$");
    }

    private static int wordCount(String value) {
        String trimmed = value == null ? "" : value.trim();
        return trimmed.isEmpty() ? 0 : trimmed.split("\\s+").length;
    }

    /** A button/menu label: one to three words. */
    static boolean shortLabel(String source) {
        int words = wordCount(source);
        return words > 0 && words <= 3;
    }

    private static String normalizeForComparison(String value) {
        return value == null ? ""
                : value.trim().replaceAll("\\s+", " ").toLowerCase(java.util.Locale.ROOT);
    }

    private void validate(List<String> texts, Map<String, String> translated) {
        if (translated == null) {
            throw new IllegalStateException("Translation provider returned no result");
        }
        for (String text : texts) {
            if (!translated.containsKey(text) || translated.get(text) == null) {
                throw new IllegalStateException(
                        "Translation provider size mismatch: missing result for an input");
            }
        }
    }

    private int claimLimit() {
        return batchSize * Math.max(1, languages.languages().size());
    }

    private static boolean isMySql(DataSource dataSource) {
        try (Connection connection = dataSource.getConnection()) {
            return connection.getMetaData().getDatabaseProductName()
                    .toLowerCase(java.util.Locale.ROOT).contains("mysql");
        } catch (Exception exception) {
            return false;
        }
    }

    private record Prepared(JobRow job, String source, ContentProtector.Protection protection,
                            String providerText, List<Entry> entries) {
    }

    private record Outcome(JobRow job, String source, String output, String error) {
    }
}
