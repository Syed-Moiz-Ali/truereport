package com.truereport.localization;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.localization.api.ContentGenerationDtos.ContentGenerationDto;
import com.truereport.localization.api.ContentGenerationDtos.GenerateContentRequest;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.TranslationItemDto;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.uimessages.UiTextTokenProtector;
import com.truereport.uimessages.UiTextTranslationProvider;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Google generation for dynamic content translations. English source text is
 * read from the neutral content columns, translated with the shared provider,
 * and stored in {@code platform_translations} as DRAFT/TRANSLATING. Results are
 * never auto-approved.
 */
@Service
public class ContentTranslationGenerationService {

    private static final Set<String> ENTITY_TYPES = TranslationBacklogService.ENTITY_TYPES;
    private static final List<String> GROUP_ORDER = List.of(
            "CATEGORY", "ITEM", "OPTION_SET", "OPTION_VALUE", "TEMPLATE",
            "DOCUMENT_TYPE", "ISSUE_FIELD");
    private static final String QUEUED = "QUEUED";
    private static final String RUNNING = "RUNNING";
    private static final String COMPLETED = "COMPLETED";
    private static final String FAILED = "FAILED";
    private static final String CANCELLED = "CANCELLED";
    private static final String INTERRUPTED = "INTERRUPTED";
    private static final String TRANSLATION_FAILED = "TRANSLATION_FAILED";

    public record StartResult(ContentGenerationDto generation, boolean accepted) {
    }

    private record JobRow(String id, String language, String status, int totalKeys,
                          int translatedKeys, List<String> failedKeys, String errorMessage,
                          String entityTypes, String createdAt, String updatedAt) {
    }

    private record WorkItem(String entityType, String entityId, String field, String sourceText) {
    }

    private final LanguageRepository languages;
    private final TranslationBacklogService backlog;
    private final TranslationRepository translations;
    private final UiTextTranslationProvider provider;
    private final UiTextTokenProtector protector;
    private final FieldAuditService audit;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final boolean synchronous;
    private final Map<String, Boolean> active = new ConcurrentHashMap<>();
    private final ExecutorService executor = Executors.newFixedThreadPool(2, runnable -> {
        Thread thread = new Thread(runnable, "content-translation-generation");
        thread.setDaemon(true);
        return thread;
    });

    public ContentTranslationGenerationService(
            LanguageRepository languages,
            TranslationBacklogService backlog,
            TranslationRepository translations,
            UiTextTranslationProvider provider,
            UiTextTokenProtector protector,
            FieldAuditService audit,
            JdbcTemplate jdbc,
            ObjectMapper objectMapper,
            @Value("${truereport.i18n.generation.synchronous:false}") boolean synchronous) {
        this.languages = languages;
        this.backlog = backlog;
        this.translations = translations;
        this.provider = provider;
        this.protector = protector;
        this.audit = audit;
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.synchronous = synchronous;
    }

    @PreDestroy
    void shutdown() {
        executor.shutdownNow();
    }

    @EventListener(ApplicationReadyEvent.class)
    void recoverInterrupted() {
        jdbc.update("""
                UPDATE platform_content_generation_jobs
                SET status = ?, error_message = ?, updated_at = CURRENT_TIMESTAMP
                WHERE status IN ('QUEUED', 'RUNNING')
                """, FAILED, "Generation was interrupted before completion; retry failed keys.");
    }

    public StartResult generate(CurrentUser actor, String code, GenerateContentRequest request) {
        LanguageDto language = requireLanguage(code);
        String defaultCode = languages.defaultCode() == null ? "en" : languages.defaultCode();
        if (language.code().equals(defaultCode)) {
            throw validation("language", "TRANSLATION_SOURCE_INVALID", "error.validation.failed");
        }
        List<String> entityTypes = resolveEntityTypes(request == null ? null : request.entityTypes());
        boolean force = request != null && Boolean.TRUE.equals(request.force());
        List<WorkItem> work = workItems(language.code(), entityTypes, force);
        requireSources(work);
        synchronized (this) {
            if (latestActiveJob(language.code()) != null) {
                throw ApiException.conflict("CONTENT_GENERATION_IN_PROGRESS",
                        "Content translation generation is already running for " + language.code());
            }
        }
        JobRow job = insertJob(language.code(), QUEUED, work.size(), 0, List.of(),
                entityTypes, null, actor);
        if (synchronous) {
            run(job, language, work);
            job = reload(job.id());
        } else {
            final JobRow queued = job;
            executor.submit(() -> run(queued, language, work));
        }
        return new StartResult(toDto(job, language), !synchronous);
    }

    public ContentGenerationDto status(String code) {
        LanguageDto language = requireLanguage(code);
        JobRow job = latestJob(language.code());
        if (job == null) {
            throw ApiException.notFound();
        }
        return toDto(job, language);
    }

    public ContentGenerationDto cancel(CurrentUser actor, String code) {
        LanguageDto language = requireLanguage(code);
        JobRow job = latestActiveJob(language.code());
        if (job == null) {
            throw ApiException.conflict("CONTENT_GENERATION_NOT_ACTIVE",
                    "No active content generation for " + language.code());
        }
        jdbc.update("""
                UPDATE platform_content_generation_jobs
                SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
                """, CANCELLED, job.id());
        audit.record(actor, "CONTENT_GENERATION_CANCELLED", "LANGUAGE", language.code(),
                Map.of("jobId", job.id()), Map.of("status", CANCELLED), null, null);
        return toDto(reload(job.id()), language);
    }

    public ContentGenerationDto retryFailed(CurrentUser actor, String code) {
        LanguageDto language = requireLanguage(code);
        JobRow previous = latestJob(language.code());
        if (previous == null) {
            throw ApiException.notFound();
        }
        if (QUEUED.equals(previous.status()) || RUNNING.equals(previous.status())) {
            throw ApiException.conflict("CONTENT_GENERATION_IN_PROGRESS",
                    "Content generation is already running for " + language.code());
        }
        List<String> types = parseEntityTypes(previous.entityTypes());
        List<WorkItem> work = workItems(language.code(), types, false);
        requireSources(work);
        synchronized (this) {
            if (latestActiveJob(language.code()) != null) {
                throw ApiException.conflict("CONTENT_GENERATION_IN_PROGRESS",
                        "Content generation is already running for " + language.code());
            }
        }
        JobRow job = insertJob(language.code(), QUEUED, work.size(), 0, List.of(), types,
                null, actor);
        if (synchronous) {
            run(job, language, work);
            job = reload(job.id());
        } else {
            final JobRow queued = job;
            executor.submit(() -> run(queued, language, work));
        }
        return toDto(job, language);
    }

    private void run(JobRow job, LanguageDto language, List<WorkItem> work) {
        active.put(language.code(), Boolean.TRUE);
        updateStatus(job.id(), RUNNING, work.size(), 0, List.of(), null);
        List<String> failures = new ArrayList<>();
        int successes = 0;
        try {
            for (WorkItem item : work) {
                if (isCancelled(job.id())) {
                    updateStatus(job.id(), CANCELLED, work.size(), successes,
                            List.copyOf(failures), null);
                    return;
                }
                try {
                    String translated = translate(item.sourceText(), language.code());
                    translations.upsert(item.entityType(), item.entityId(), item.field(),
                            language.code(), translated, "TRANSLATING");
                    successes++;
                } catch (RuntimeException error) {
                    failures.add(item.entityType() + "|" + item.entityId() + "|" + item.field());
                }
                updateStatus(job.id(), RUNNING, work.size(), successes,
                        List.copyOf(failures), null);
            }
            if (!failures.isEmpty()) {
                updateStatus(job.id(), FAILED, work.size(), successes, List.copyOf(failures),
                        "Translation failed for " + failures.size() + " field(s)");
                return;
            }
            String resultingStatus = language.status();
            if ("DRAFT".equals(resultingStatus)) {
                languages.setStatus(language.code(), "TRANSLATING");
                resultingStatus = "TRANSLATING";
            }
            audit.record(null, "CONTENT_TRANSLATIONS_GENERATED", "LANGUAGE", language.code(),
                    Map.of("status", language.status()),
                    Map.of("status", resultingStatus, "fields", successes), null, null);
            updateStatus(job.id(), COMPLETED, work.size(), successes, List.of(), null);
        } catch (RuntimeException error) {
            updateStatus(job.id(), FAILED, work.size(), successes, List.copyOf(failures),
                    error.getMessage() == null ? "Content generation failed" : error.getMessage());
        } finally {
            active.remove(language.code());
        }
    }

    private String translate(String value, String language) {
        if (protector.shouldSkip(value)) {
            return value;
        }
        UiTextTokenProtector.Prepared prepared = protector.protect(value);
        String translated = provider.translate(prepared.text(), language);
        return protector.restoreAndValidate(prepared, translated);
    }

    private List<WorkItem> workItems(String language, List<String> entityTypes, boolean force) {
        List<WorkItem> work = new ArrayList<>();
        for (var group : backlog.backlog(language).groups()) {
            if (!entityTypes.contains(group.entityType())) {
                continue;
            }
            for (TranslationItemDto item : group.items()) {
                boolean approved = "APPROVED".equals(item.status());
                boolean hasText = item.text() != null && !item.text().isBlank();
                if (!force && approved && hasText) {
                    continue;
                }
                work.add(new WorkItem(item.entityType(), item.entityId(), item.field(),
                        item.defaultText()));
            }
        }
        return work;
    }

    private void requireSources(List<WorkItem> work) {
        List<FieldIssue> missing = new ArrayList<>();
        for (WorkItem item : work) {
            if (item.sourceText() == null || item.sourceText().isBlank()) {
                missing.add(FieldIssue.of(item.entityType() + "." + item.field(),
                        "TRANSLATION_SOURCE_MISSING", "error.translation.sourceRequired"));
            }
        }
        if (!missing.isEmpty()) {
            throw ApiException.validation("TRANSLATION_SOURCE_MISSING",
                    "English source text is missing; edit the source record first", missing);
        }
    }

    private List<String> resolveEntityTypes(List<String> requested) {
        if (requested == null || requested.isEmpty()) {
            return GROUP_ORDER;
        }
        LinkedHashSet<String> result = new LinkedHashSet<>();
        for (String raw : requested) {
            if (raw == null) {
                continue;
            }
            String type = raw.trim().toUpperCase(Locale.ROOT);
            if (!ENTITY_TYPES.contains(type)) {
                throw validation("entityTypes", "TRANSLATION_ENTITY_INVALID",
                        "error.validation.failed");
            }
            result.add(type);
        }
        return result.isEmpty() ? GROUP_ORDER : List.copyOf(result);
    }

    private LanguageDto requireLanguage(String code) {
        if (code == null || code.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        return languages.find(code.trim().toLowerCase(Locale.ROOT))
                .orElseThrow(() -> validation("language", "LANGUAGE_UNKNOWN",
                        "error.locale.invalid"));
    }

    private JobRow insertJob(String code, String status, int total, int translated,
                             List<String> failed, List<String> entityTypes, String error,
                             CurrentUser actor) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_content_generation_jobs
                    (id, language_code, entity_types_json, status, total_keys, translated_keys,
                     failed_keys_json, error_message, requested_by, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, id, code, json(entityTypes), status, total, translated, json(failed), error,
                actor == null || actor.userId() == null ? null : actor.userId().toString());
        return reload(id);
    }

    private void updateStatus(String jobId, String status, int total, int translated,
                              List<String> failed, String error) {
        jdbc.update("""
                UPDATE platform_content_generation_jobs
                SET status = ?, total_keys = ?, translated_keys = ?, failed_keys_json = ?,
                    error_message = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
                """, status, total, translated, json(failed), error, jobId);
    }

    private JobRow latestJob(String code) {
        return jdbc.query("""
                SELECT id, language_code, status, total_keys, translated_keys, failed_keys_json,
                       error_message, entity_types_json, created_at, updated_at
                FROM platform_content_generation_jobs
                WHERE language_code = ? ORDER BY created_at DESC, id DESC LIMIT 1
                """, (rs, i) -> map(rs), code).stream().findFirst().orElse(null);
    }

    private JobRow latestActiveJob(String code) {
        return jdbc.query("""
                SELECT id, language_code, status, total_keys, translated_keys, failed_keys_json,
                       error_message, entity_types_json, created_at, updated_at
                FROM platform_content_generation_jobs
                WHERE language_code = ? AND status IN ('QUEUED', 'RUNNING')
                ORDER BY created_at DESC LIMIT 1
                """, (rs, i) -> map(rs), code).stream().findFirst().orElse(null);
    }

    private JobRow reload(String jobId) {
        return jdbc.query("""
                SELECT id, language_code, status, total_keys, translated_keys, failed_keys_json,
                       error_message, entity_types_json, created_at, updated_at
                FROM platform_content_generation_jobs WHERE id = ?
                """, (rs, i) -> map(rs), jobId).stream().findFirst()
                .orElseThrow(ApiException::notFound);
    }

    private JobRow map(java.sql.ResultSet rs) throws java.sql.SQLException {
        Timestamp created = rs.getTimestamp("created_at");
        Timestamp updated = rs.getTimestamp("updated_at");
        return new JobRow(rs.getString("id"), rs.getString("language_code"),
                rs.getString("status"), rs.getInt("total_keys"), rs.getInt("translated_keys"),
                parseStringList(rs.getString("failed_keys_json")),
                rs.getString("error_message"), rs.getString("entity_types_json"),
                created == null ? null : created.toInstant().toString(),
                updated == null ? null : updated.toInstant().toString());
    }

    private boolean isCancelled(String jobId) {
        try {
            String status = jdbc.queryForObject("""
                    SELECT status FROM platform_content_generation_jobs WHERE id = ?
                    """, String.class, jobId);
            return CANCELLED.equals(status);
        } catch (RuntimeException error) {
            return false;
        }
    }

    private ContentGenerationDto toDto(JobRow job, LanguageDto language) {
        return new ContentGenerationDto(job.language(), job.id(), job.status(),
                parseEntityTypes(job.entityTypes()), job.totalKeys(), job.translatedKeys(),
                job.failedKeys(), language.status(), job.errorMessage(),
                job.createdAt(), job.updatedAt());
    }

    private List<String> parseEntityTypes(String raw) {
        List<String> parsed = parseStringList(raw);
        return parsed.isEmpty() ? GROUP_ORDER : parsed;
    }

    private List<String> parseStringList(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(raw, new TypeReference<List<String>>() {
            });
        } catch (JsonProcessingException error) {
            return List.of();
        }
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value == null ? List.of() : value);
        } catch (JsonProcessingException error) {
            return "[]";
        }
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid content generation request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }

    @SuppressWarnings("unused")
    private static String statusOf(String value) {
        return value == null ? "" : value;
    }
}
