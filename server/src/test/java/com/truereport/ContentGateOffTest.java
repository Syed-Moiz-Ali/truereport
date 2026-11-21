package com.truereport;

import com.truereport.shared.i18n.TranslationReviewGate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;

@TestPropertySource(properties = "truereport.i18n.review.gate=off")
class ContentGateOffTest extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    TranslationReviewGate gate;

    @Test
    void gateOffDisablesSafetyCriticalChecks() {
        String versionId = seedItemWithPendingInstruction();

        assertThatCode(() -> gate.assertTemplatePublish(List.of(versionId)))
                .doesNotThrowAnyException();
    }

    private String seedItemWithPendingInstruction() {
        String categoryId = UUID.randomUUID().toString();
        String itemId = UUID.randomUUID().toString();
        String versionId = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, 'Gate off', 0, 'ACTIVE', 0, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, categoryId, "GOFF-CAT-" + categoryId.substring(0, 8));
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id,
                     sample_data, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'PUBLISHED', NULL, FALSE, 0, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, itemId, "GOFF-ITEM-" + itemId.substring(0, 8), categoryId);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction, standard_spec,
                     safety_critical, multi_point, allow_free_text_note, result_options_json,
                     note_requirement, evidence_requirement, min_photos,
                     created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', 'Gate off', 'Instruction', 'Standard',
                        FALSE, FALSE, FALSE, '[]', 'OPTIONAL', 'REQUIRED', 1,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, versionId, itemId);
        jdbc.update("UPDATE platform_items SET current_published_version_id = ? WHERE id = ?",
                versionId, itemId);
        jdbc.update("""
                INSERT INTO content_translation
                    (id, entity_type, entity_id, field_name, lang, body, origin, status,
                     source_lang, source_hash, created_at, updated_at)
                VALUES (?, 'ITEM', ?, 'instruction', 'en', 'Derived', 'MACHINE',
                        'PENDING_REVIEW', 'es', 'hash', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), versionId);
        return versionId;
    }
}
