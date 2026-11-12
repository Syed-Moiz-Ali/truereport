package com.truereport.localization;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Blocks configuration publishes (and creation of new live content) while a
 * non-EN/AR language is LIVE but its approved overlay text is missing.
 * With only EN/AR live (all production seeds) this gate is a no-op.
 */
@Service
public class TranslationGate {

    private final JdbcTemplate jdbc;

    public TranslationGate(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** LIVE language codes beyond the built-in EN/AR pair. */
    public List<String> liveExtendedLanguages() {
        return jdbc.query("""
                SELECT code FROM platform_languages
                WHERE active = TRUE AND status = 'LIVE' AND code NOT IN ('en', 'ar')
                ORDER BY code
                """, (rs, i) -> rs.getString(1));
    }

    /**
     * Fail-fast for creating new live content while an extended language is
     * LIVE: a brand-new entity cannot have approved overlay text yet, so the
     * operator must either translate first or retire the language.
     */
    public void requireNewContentAllowed(String contentLabel) {
        List<String> extended = liveExtendedLanguages();
        if (!extended.isEmpty()) {
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    contentLabel + " cannot be created while language(s) "
                            + String.join(",", extended) + " are LIVE without translations",
                    extended.stream()
                            .map(code -> FieldIssue.of(code, "TRANSLATION_REQUIRED",
                                    "error.translation.required"))
                            .toList());
        }
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
}
