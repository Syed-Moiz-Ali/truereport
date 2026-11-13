package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Blocks activation/publish of content while a non-default LIVE language has no
 * approved overlay text for required fields.
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
                .toList();
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
                Integer approved = jdbc.queryForObject("""
                        SELECT COUNT(*) FROM platform_translations
                        WHERE entity_type = ? AND entity_id = ? AND field_name = ?
                          AND lang = ? AND status = 'APPROVED'
                        """, Integer.class, entityType, entityId, field, language);
                if (approved == null || approved == 0) {
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
    public boolean translationProvidedForLive(Map<String, Map<String, String>> translations,
                                              String field) {
        List<String> extended = liveExtendedLanguages();
        if (extended.isEmpty()) {
            return true;
        }
        Map<String, String> values = translations == null ? null : translations.get(field);
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

    /** Requires APPROVED overlay text for every extended LIVE language. */
    public void requireOverlaysApproved(String entityType, String entityId, List<String> fields) {
        List<String> extended = liveExtendedLanguages();
        if (extended.isEmpty()) {
            return;
        }
        List<FieldIssue> missing = new ArrayList<>();
        for (String language : extended) {
            for (String field : fields) {
                Integer approved = jdbc.queryForObject("""
                        SELECT COUNT(*) FROM platform_translations
                        WHERE entity_type = ? AND entity_id = ? AND field_name = ?
                          AND lang = ? AND status = 'APPROVED'
                        """, Integer.class, entityType, entityId, field, language);
                if (approved == null || approved == 0) {
                    missing.add(FieldIssue.of(language + "." + field, "TRANSLATION_REQUIRED",
                            "error.translation.required"));
                }
            }
        }
        if (!missing.isEmpty()) {
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "Approved " + String.join(",", extended)
                            + " translations are required before publishing",
                    missing);
        }
    }

    public void requireOverlaysApproved(String entityType, String entityId) {
        requireOverlaysApproved(entityType, entityId,
                TranslationFieldRegistry.fieldsFor(entityType));
    }
}
