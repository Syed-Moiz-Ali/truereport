package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.shared.i18n.TranslationReviewRequiredException;
import com.truereport.shared.i18n.TranslationReviewRequiredException.Issue;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Blocks activation/publish of content while a non-default LIVE language has no
 * reviewed overlay text for required fields.
 *
 * <p>Reads the current localized content store ({@code content_translation});
 * only {@code REVIEWED} rows count. Machine rows waiting for a human decision
 * ({@code PENDING_REVIEW}), stale rows and missing rows all block the publish.
 */
@Service
public class TranslationGate {

    private final JdbcTemplate jdbc;
    private final LanguageRepository languages;

    public TranslationGate(JdbcTemplate jdbc, LanguageRepository languages) {
        this.jdbc = jdbc;
        this.languages = languages;
    }

    public List<String> liveExtendedLanguages() {
        String defaultCode = languages.defaultCode();
        return languages.findLive().stream()
                .map(LanguageDto::code)
                .filter(code -> defaultCode == null || !code.equalsIgnoreCase(defaultCode))
                // A manifest language becomes a required gate only after its
                // first reviewed translation exists. This keeps newly added
                // manifest languages usable immediately while missing dynamic
                // translations continue to fall back to English.
                .filter(this::hasReviewedTranslations)
                .toList();
    }

    private boolean hasReviewedTranslations(String language) {
        Integer reviewed = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation
                WHERE lang = ? AND status = 'REVIEWED'
                """, Integer.class, language);
        return reviewed != null && reviewed > 0;
    }

    /** Creation is always allowed; activation/publish is gated. */
    public void requireNewContentAllowed(String contentLabel) {
        // Intentionally a no-op.
    }

    public boolean overlaysApproved(String entityType, String entityId, List<String> fields) {
        List<String> extended = liveExtendedLanguages();
        if (extended.isEmpty()) {
            return true;
        }
        for (String language : extended) {
            for (String field : fields) {
                if (!"REVIEWED".equals(reviewedStatus(entityType, entityId, field, language))) {
                    return false;
                }
            }
        }
        return true;
    }

    public boolean overlaysApproved(String entityType, String entityId) {
        return overlaysApproved(entityType, entityId,
                TranslationFieldRegistry.fieldsFor(entityType));
    }

    /**
     * True when the supplied request translations cover every LIVE extended
     * language for the field. Used to choose ACTIVE vs DRAFT at creation time.
     */
    public boolean translationProvidedForLive(java.util.Map<String, java.util.Map<String, String>> translations,
                                              String field) {
        List<String> extended = liveExtendedLanguages();
        if (extended.isEmpty()) {
            return true;
        }
        java.util.Map<String, String> values = translations == null ? null : translations.get(field);
        if (values == null) {
            return false;
        }
        for (String language : extended) {
            String text = values.get(language);
            if (text == null || text.isBlank()) {
                return false;
            }
        }
        return true;
    }

    /**
     * Requires reviewed overlay text for every extended LIVE language.
     *
     * <p>Failures are reported as the structured 409
     * {@code TRANSLATION_REVIEW_REQUIRED} issue list so the console can open the
     * Content review desk instead of showing a generic error.
     */
    public void requireOverlaysApproved(String entityType, String entityId, List<String> fields) {
        List<String> extended = liveExtendedLanguages();
        if (extended.isEmpty()) {
            return;
        }
        List<Issue> missing = new ArrayList<>();
        for (String language : extended) {
            for (String field : fields) {
                String status = reviewedStatus(entityType, entityId, field, language);
                if (!"REVIEWED".equals(status)) {
                    missing.add(new Issue(entityType, entityId, field, language,
                            status == null ? "MISSING" : status));
                }
            }
        }
        if (!missing.isEmpty()) {
            throw new TranslationReviewRequiredException(missing);
        }
    }

    public void requireOverlaysApproved(String entityType, String entityId) {
        requireOverlaysApproved(entityType, entityId,
                TranslationFieldRegistry.fieldsFor(entityType));
    }

    /** REVIEWED when a row exists and was approved; otherwise its real status. */
    private String reviewedStatus(String entityType, String entityId, String field, String lang) {
        List<String> statuses = jdbc.query("""
                SELECT status FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, (rs, rowNum) -> rs.getString(1), entityType, entityId, field, lang);
        return statuses.isEmpty() ? null : statuses.get(0);
    }
}
