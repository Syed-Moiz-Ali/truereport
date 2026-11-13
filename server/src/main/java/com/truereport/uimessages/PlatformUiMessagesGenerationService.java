package com.truereport.uimessages;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.uimessages.UiMessageLanguageGateway.Language;
import com.truereport.uimessages.api.UiMessageGenerationDtos.GenerateUiMessagesRequest;
import com.truereport.uimessages.api.UiMessageGenerationDtos.UiMessageGenerationDto;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Service
public class PlatformUiMessagesGenerationService {

    private static final Set<String> REVIEW_STATUSES =
            Set.of("DRAFT", "TRANSLATING", "REVIEW");
    private static final String DEFAULT_REVIEW_STATUS = "TRANSLATING";
    private static final String QUEUED = "QUEUED";
    private static final String RUNNING = "RUNNING";
    private static final String COMPLETED = "COMPLETED";
    private static final String FAILED = "FAILED";
    private static final String CANCELLED = "CANCELLED";
    private static final String INTERRUPTED = "INTERRUPTED";
    private static final String TRANSLATION_FAILED = "TRANSLATION_FAILED";

    public record StartResult(UiMessageGenerationDto generation, boolean accepted) {
    }

    private record JobRow(
            String id,
            String language,
            String status,
            int totalKeys,
            int translatedKeys,
            List<String> failedKeys,
            String errorCode,
            String errorMessage,
            String requestedBy,
            Instant createdAt,
            Instant updatedAt) {
    }

    private enum Mode { GENERATE, RETRY_FAILED }

    private final UiMessageLanguageGateway languages;
    private final PlatformUiMessageCatalog catalog;
    private final UiTextTranslationProvider provider;
    private final UiTextTokenProtector protector;
    private final FieldAuditService audit;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final boolean synchronous;
    private final Map<String, Boolean> active = new ConcurrentHashMap<>();
    private final ExecutorService executor = Executors.newFixedThreadPool(2, runnable -> {
        Thread thread = new Thread(runnable, "ui-message-generation");
        thread.setDaemon(true);
        return thread;
    });

    public PlatformUiMessagesGenerationService(UiMessageLanguageGateway languages,
                                               PlatformUiMessageCatalog catalog,
                                               UiTextTranslationProvider provider,
                                               UiTextTokenProtector protector,
                                               FieldAuditService audit,
                                               JdbcTemplate jdbc,
                                               ObjectMapper objectMapper,
                                               @Value("${truereport.i18n.generation.synchronous:false}")
                                               boolean synchronous) {
        this.languages = languages;
        this.catalog = catalog;
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
                UPDATE platform_ui_message_generation_jobs
                SET status = ?, error_code = ?, error_message = ?, updated_at = CURRENT_TIMESTAMP
                WHERE status IN ('QUEUED', 'RUNNING')
                """, FAILED, INTERRUPTED,
                "Generation was interrupted before completion; retry failed keys.");
    }

    public StartResult generate(CurrentUser actor, String code,
                                GenerateUiMessagesRequest request) {
        Language language = requireLanguage(code);
        boolean force = request != null && Boolean.TRUE.equals(request.force());
        String reviewStatus = normalizeReviewStatus(
                request == null ? null : request.reviewStatus());
        String path = targetPath(language);

        if (!force && catalog.exists(path)) {
            boolean valid = true;
            try {
                catalog.load(path);
            } catch (RuntimeException broken) {
                valid = false;
            }
            if (valid) {
                if (language.uiMessagesPath() == null
                        || language.uiMessagesPath().isBlank()) {
                    languages.setUiMessagesPath(language.code(), path);
                }
                JobRow job = insertJob(language.code(), COMPLETED,
                        sourceKeyCount(), sourceKeyCount(), List.of(), null, null, actor);
                return new StartResult(toDto(job, language), false);
            }
        }

        catalog.requireWritable();
        if (force) {
            deleteStaging(path);
        }
        JobRow job = createJob(actor, language.code(), Mode.GENERATE);
        start(job, language, path, reviewStatus, Mode.GENERATE, force);
        return new StartResult(toDto(reload(job.id(), language), language), true);
    }

    public UiMessageGenerationDto status(String code) {
        Language language = requireLanguage(code);
        JobRow job = latestJob(language.code());
        if (job == null) {
            throw ApiException.notFound();
        }
        return toDto(job, language);
    }

    public UiMessageGenerationDto cancel(CurrentUser actor, String code) {
        Language language = requireLanguage(code);
        JobRow job = latestActiveJob(language.code());
        if (job == null) {
            throw ApiException.conflict("UI_MESSAGE_GENERATION_NOT_ACTIVE",
                    "No active UI message generation for " + language.code());
        }
        jdbc.update("""
                UPDATE platform_ui_message_generation_jobs
                SET status = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, CANCELLED, job.id());
        audit.record(actor, "UI_MESSAGES_GENERATION_CANCELLED", "LANGUAGE",
                language.code(), Map.of("jobId", job.id()),
                Map.of("status", CANCELLED), null, null);
        return toDto(reload(job.id(), language), language);
    }

    public UiMessageGenerationDto retryFailed(CurrentUser actor, String code) {
        Language language = requireLanguage(code);
        JobRow previous = latestJob(language.code());
        if (previous == null) {
            throw ApiException.notFound();
        }
        if (QUEUED.equals(previous.status()) || RUNNING.equals(previous.status())) {
            throw ApiException.conflict("UI_MESSAGE_GENERATION_IN_PROGRESS",
                    "UI message generation is already running for " + language.code());
        }
        if (!FAILED.equals(previous.status()) && !CANCELLED.equals(previous.status())) {
            throw ApiException.conflict("UI_MESSAGE_GENERATION_NOT_RETRYABLE",
                    "Only failed or cancelled generations can be retried");
        }
        catalog.requireWritable();
        String path = targetPath(language);
        JobRow job = createJob(actor, language.code(), previous.failedKeys());
        start(job, language, path, DEFAULT_REVIEW_STATUS, Mode.RETRY_FAILED, false);
        return toDto(reload(job.id(), language), language);
    }

    private JobRow createJob(CurrentUser actor, String code, Mode mode) {
        return createJob(actor, code, List.of());
    }

    private JobRow createJob(CurrentUser actor, String code, List<String> failedKeys) {
        synchronized (this) {
            JobRow activeJob = latestActiveJob(code);
            if (activeJob != null) {
                throw ApiException.conflict("UI_MESSAGE_GENERATION_IN_PROGRESS",
                        "UI message generation is already running for " + code);
            }
            return insertJob(code, QUEUED, 0, 0, failedKeys, null, null, actor);
        }
    }

    private void start(JobRow job, Language language, String path,
                       String reviewStatus, Mode mode, boolean force) {
        if (synchronous) {
            run(job, language, path, reviewStatus, mode, force);
        } else {
            executor.submit(() -> run(job, language, path, reviewStatus, mode, force));
        }
    }

    private void run(JobRow job, Language language, String path,
                     String reviewStatus, Mode mode, boolean force) {
        active.put(language.code(), Boolean.TRUE);
        updateStatus(job.id(), RUNNING, 0, 0, List.of(), null, null);
        try {
            Map<String, String> source = catalog.loadFlat(
                    PlatformUiMessageCatalog.SOURCE_PATH);
            if (mode == Mode.GENERATE && force) {
                deleteStaging(path);
            }
            Map<String, String> staging = new LinkedHashMap<>();
            String stagingPath = stagingPath(path);
            if (mode == Mode.RETRY_FAILED) {
                Map<String, String> resume = loadIfPresent(stagingPath);
                if (resume.isEmpty()) {
                    resume = loadIfPresent(path);
                }
                staging.putAll(resume);
            }

            Set<String> keys = new LinkedHashSet<>();
            if (mode == Mode.RETRY_FAILED) {
                keys.addAll(job.failedKeys());
                for (String key : source.keySet()) {
                    if (!staging.containsKey(key)) {
                        keys.add(key);
                    }
                }
                keys.retainAll(source.keySet());
            } else {
                keys.addAll(source.keySet());
            }

            int total = keys.size();
            List<String> failures = new ArrayList<>();
            int successes = 0;
            updateStatus(job.id(), RUNNING, total, 0, List.of(), null, null);
            for (String key : keys) {
                if (isCancelled(job.id())) {
                    if (!staging.isEmpty()) {
                        catalog.writeAtomic(stagingPath, staging);
                    }
                    updateStatus(job.id(), CANCELLED, total, successes,
                            failures, null, null);
                    audit.record(null, "UI_MESSAGES_GENERATION_CANCELLED", "LANGUAGE",
                            language.code(), Map.of("jobId", job.id()),
                            Map.of("status", CANCELLED), null, null);
                    return;
                }
                try {
                    staging.put(key, translate(source.get(key), language.code()));
                    successes++;
                } catch (RuntimeException error) {
                    failures.add(key);
                }
                updateStatus(job.id(), RUNNING, total, successes,
                        List.copyOf(failures), null, null);
            }

            if (!failures.isEmpty()) {
                if (!staging.isEmpty()) {
                    catalog.writeAtomic(stagingPath, staging);
                }
                String message = "Translation failed for " + failures.size()
                        + " key(s): " + String.join(",", failures.subList(0,
                        Math.min(5, failures.size())));
                updateStatus(job.id(), FAILED, total, successes,
                        List.copyOf(failures), TRANSLATION_FAILED, message);
                return;
            }

            if (!staging.keySet().containsAll(source.keySet())
                    || !staging.keySet().equals(source.keySet())) {
                throw new IllegalStateException(
                        "Generated UI message key parity failed");
            }
            catalog.writeAtomic(path, staging);
            languages.setUiMessagesPath(language.code(), path);
            languages.setStatus(language.code(), reviewStatus);
            deleteStaging(path);
            audit.record(null, "UI_MESSAGES_GENERATED", "LANGUAGE", language.code(),
                    Map.of("path", language.uiMessagesPath() == null
                                    ? "" : language.uiMessagesPath(),
                            "status", language.status()),
                    Map.of("path", path, "status", reviewStatus,
                            "keysTranslated", staging.size()),
                    null, null);
            updateStatus(job.id(), COMPLETED, total, total, List.of(), null, null);
        } catch (RuntimeException error) {
            updateStatus(job.id(), FAILED, 0, 0, List.of(), TRANSLATION_FAILED,
                    error.getMessage() == null ? "UI message generation failed"
                            : error.getMessage());
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

    private Language requireLanguage(String code) {
        return languages.find(code)
                .orElseThrow(() -> validation("code", "LANGUAGE_UNKNOWN",
                        "error.locale.invalid"));
    }

    private String targetPath(Language language) {
        if (language.uiMessagesPath() != null
                && !language.uiMessagesPath().isBlank()) {
            return PlatformUiMessageCatalog.validateRelativePath(
                    language.uiMessagesPath());
        }
        return "platform_admin/" + language.code() + ".json";
    }

    private static String stagingPath(String path) {
        return path + ".pending.json";
    }

    private void deleteStaging(String path) {
        try {
            Files.deleteIfExists(Path.of(stagingPath(path)));
        } catch (Exception ignored) {
            // best effort cleanup
        }
    }

    private Map<String, String> loadIfPresent(String path) {
        try {
            if (!catalog.exists(path)) {
                return new LinkedHashMap<>();
            }
            return new LinkedHashMap<>(catalog.loadFlat(path));
        } catch (RuntimeException broken) {
            return new LinkedHashMap<>();
        }
    }

    private int sourceKeyCount() {
        try {
            return catalog.loadFlat(PlatformUiMessageCatalog.SOURCE_PATH).size();
        } catch (RuntimeException ignored) {
            return 0;
        }
    }

    private boolean isCancelled(String jobId) {
        try {
            String status = jdbc.queryForObject("""
                    SELECT status FROM platform_ui_message_generation_jobs WHERE id = ?
                    """, String.class, jobId);
            return CANCELLED.equals(status);
        } catch (RuntimeException error) {
            return false;
        }
    }

    private JobRow insertJob(String code, String status, int totalKeys,
                             int translatedKeys, List<String> failedKeys,
                             String errorCode, String errorMessage,
                             CurrentUser actor) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_ui_message_generation_jobs
                    (id, language_code, status, total_keys, translated_keys,
                     failed_keys_json, error_code, error_message, requested_by,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, id, code, status, totalKeys, translatedKeys,
                json(failedKeys), errorCode, errorMessage,
                actor == null || actor.userId() == null
                        ? null : actor.userId().toString());
        return reload(id, null);
    }

    private void updateStatus(String jobId, String status, int totalKeys,
                              int translatedKeys, List<String> failedKeys,
                              String errorCode, String errorMessage) {
        jdbc.update("""
                UPDATE platform_ui_message_generation_jobs
                SET status = ?, total_keys = ?, translated_keys = ?,
                    failed_keys_json = ?, error_code = ?, error_message = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, status, totalKeys, translatedKeys, json(failedKeys),
                errorCode, errorMessage, jobId);
    }

    private JobRow latestJob(String code) {
        List<JobRow> rows = jdbc.query("""
                SELECT id, language_code, status, total_keys, translated_keys,
                       failed_keys_json, error_code, error_message, requested_by,
                       created_at, updated_at
                FROM platform_ui_message_generation_jobs
                WHERE language_code = ?
                ORDER BY created_at DESC, id DESC
                LIMIT 1
                """, (rs, i) -> map(rs), code);
        return rows.isEmpty() ? null : rows.get(0);
    }

    private JobRow latestActiveJob(String code) {
        List<JobRow> rows = jdbc.query("""
                SELECT id, language_code, status, total_keys, translated_keys,
                       failed_keys_json, error_code, error_message, requested_by,
                       created_at, updated_at
                FROM platform_ui_message_generation_jobs
                WHERE language_code = ? AND status IN ('QUEUED', 'RUNNING')
                ORDER BY created_at DESC
                LIMIT 1
                """, (rs, i) -> map(rs), code);
        return rows.isEmpty() ? null : rows.get(0);
    }

    private JobRow reload(String jobId, Language language) {
        List<JobRow> rows = jdbc.query("""
                SELECT id, language_code, status, total_keys, translated_keys,
                       failed_keys_json, error_code, error_message, requested_by,
                       created_at, updated_at
                FROM platform_ui_message_generation_jobs
                WHERE id = ?
                """, (rs, i) -> map(rs), jobId);
        if (rows.isEmpty()) {
            throw ApiException.notFound();
        }
        return rows.get(0);
    }

    private JobRow map(java.sql.ResultSet rs) throws java.sql.SQLException {
        Timestamp created = rs.getTimestamp("created_at");
        Timestamp updated = rs.getTimestamp("updated_at");
        return new JobRow(
                rs.getString("id"),
                rs.getString("language_code"),
                rs.getString("status"),
                rs.getInt("total_keys"),
                rs.getInt("translated_keys"),
                parseKeys(rs.getString("failed_keys_json")),
                rs.getString("error_code"),
                rs.getString("error_message"),
                rs.getString("requested_by"),
                created == null ? Instant.EPOCH : created.toInstant(),
                updated == null ? Instant.EPOCH : updated.toInstant());
    }

    private List<String> parseKeys(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(raw,
                    new TypeReference<List<String>>() {
                    });
        } catch (JsonProcessingException error) {
            return List.of();
        }
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException error) {
            throw new IllegalStateException(error);
        }
    }

    private UiMessageGenerationDto toDto(JobRow job, Language language) {
        String path = language.uiMessagesPath() == null
                || language.uiMessagesPath().isBlank()
                ? "platform_admin/" + language.code() + ".json"
                : language.uiMessagesPath();
        return new UiMessageGenerationDto(job.language(), job.id(), job.status(),
                language.status(), path, job.translatedKeys(),
                job.failedKeys(), job.totalKeys(), job.translatedKeys(),
                job.errorMessage(), job.createdAt().toString(),
                COMPLETED.equals(job.status()) || FAILED.equals(job.status())
                        || CANCELLED.equals(job.status())
                        ? job.updatedAt().toString() : null);
    }

    private static String normalizeReviewStatus(String raw) {
        if (raw == null || raw.isBlank()) {
            return DEFAULT_REVIEW_STATUS;
        }
        String status = raw.trim().toUpperCase(Locale.ROOT);
        if (!REVIEW_STATUSES.contains(status)) {
            throw validation("reviewStatus", "UI_MESSAGE_REVIEW_STATUS_INVALID",
                    "error.validation.failed");
        }
        return status;
    }

    private static ApiException validation(String field, String code,
                                           String messageKey) {
        return ApiException.validation(code, "Invalid UI message generation request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
