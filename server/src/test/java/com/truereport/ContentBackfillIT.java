package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.shared.i18n.ContentTranslationService;
import com.truereport.shared.i18n.ContentTranslationWorker;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Explicit backfill for content authored before the translation pipeline: it
 * must enqueue only what is missing/stale, never duplicate jobs, and leave the
 * provider call to the worker.
 */
class ContentBackfillIT extends IntegrationTestBase {

    private static final String BACKFILL = "/api/v1/platform/i18n/content/backfill";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationService translations;

    @Autowired
    ContentTranslationWorker worker;

    @Test
    void enqueuesMissingAndStaleSkipsCurrentAndIsIdempotent() throws Exception {
        Login platform = login("platform@test.local");
        String categoryId = category("BF-CAT-" + suffix(), "Brakes");
        String versionId = item("BF-ITEM-" + suffix(), categoryId, "Front pads",
                "Check the pads", "No cracks or leaks");

        // Current rows must be skipped: one reviewed, one pending review.
        insertRow("CATEGORY", categoryId, "name", "es", "Frenos", "AUTHORED",
                "REVIEWED", translations.hash("Brakes"));
        insertRow("ITEM", versionId, "label", "es", "Pastillas", "MACHINE",
                "PENDING_REVIEW", translations.hash("Front pads"));
        // A stale row with a mismatched hash must be re-enqueued.
        insertRow("ITEM", versionId, "instruction", "es", "Viejo", "MACHINE",
                "STALE", translations.hash("an older source"));

        JsonNode first = backfill(platform, """
                {"languages":["es"],"entityTypes":["ITEM","CATEGORY"]}
                """);
        assertThat(first.get("enqueued").asInt())
                .as("instruction (stale) + standardSpec (missing)")
                .isEqualTo(2);
        assertThat(first.get("skipped").asInt()).isEqualTo(2);
        assertThat(texts(first.get("languages"))).containsExactly("es");
        assertThat(texts(first.get("entityTypes"))).containsExactly("ITEM", "CATEGORY");
        assertThat(jobCount(versionId)).isEqualTo(2);
        assertThat(jobStates(versionId)).containsOnly("PENDING");

        JsonNode second = backfill(platform, """
                {"languages":["es"],"entityTypes":["ITEM","CATEGORY"]}
                """);
        assertThat(second.get("enqueued").asInt()).isZero();
        assertThat(second.get("skipped").asInt()).isEqualTo(4);
        assertThat(jobCount(versionId))
                .as("unique job key keeps the second call idempotent")
                .isEqualTo(2);
    }

    @Test
    void dryRunReportsWhatWouldHappenWithoutWritingJobs() throws Exception {
        Login platform = login("platform@test.local");
        String categoryId = category("BF-DRY-" + suffix(), "Body");

        JsonNode preview = backfill(platform,
                "{\"languages\":[\"es\"],\"entityTypes\":[\"CATEGORY\"],\"dryRun\":true}");
        assertThat(preview.get("enqueued").asInt()).isEqualTo(1);
        assertThat(preview.get("skipped").asInt()).isZero();
        assertThat(jobCount(categoryId)).isZero();

        JsonNode real = backfill(platform,
                "{\"languages\":[\"es\"],\"entityTypes\":[\"CATEGORY\"],\"dryRun\":false}");
        assertThat(real.get("enqueued").asInt()).isEqualTo(1);
        assertThat(jobCount(categoryId)).isEqualTo(1);
    }

    @Test
    void unknownLanguageAndEntityTypeAreRejectedWithoutWriting() throws Exception {
        Login platform = login("platform@test.local");
        String categoryId = category("BF-ERR-" + suffix(), "Lights");

        backfillExpecting(platform, "{\"languages\":[\"de\"],\"entityTypes\":[\"CATEGORY\"]}",
                status().isUnprocessableEntity(), "LANGUAGE_UNKNOWN");
        backfillExpecting(platform, "{\"languages\":[\"en\"],\"entityTypes\":[\"CATEGORY\"]}",
                status().isUnprocessableEntity(), "LANGUAGE_DEFAULT");
        backfillExpecting(platform, "{\"languages\":[\"es\"],\"entityTypes\":[\"NOPE\"]}",
                status().isUnprocessableEntity(), "ENTITY_TYPE_UNKNOWN");
        assertThat(jobCount(categoryId)).isZero();
    }

    @Test
    void nonPlatformUserIsForbidden() throws Exception {
        Login workshopAdmin = login("admin.a@test.local");
        mockMvc.perform(post(BACKFILL)
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"languages\":[\"es\"]}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void backfillThenWorkerDrainsAndSecondPassEnqueuesNothing() throws Exception {
        Login platform = login("platform@test.local");
        String categoryId = category("BF-WORK-" + suffix(), "Body panels");
        String versionId = item("BF-WORK-ITEM-" + suffix(), categoryId, "Body paint",
                "Check the finish", "No cracks or leaks");

        JsonNode enqueued = backfill(platform, """
                {"languages":["es"],"entityTypes":["ITEM","CATEGORY"]}
                """);
        assertThat(enqueued.get("enqueued").asInt()).isEqualTo(4);
        assertThat(jobCount(categoryId) + jobCount(versionId)).isEqualTo(4);

        assertThat(worker.workOnce()).isPositive();

        assertThat(translatedText("CATEGORY", categoryId, "name"))
                .isEqualTo("[[es]] Body panels");
        assertThat(translatedText("ITEM", versionId, "label"))
                .isEqualTo("[[es]] Body paint");
        assertThat(translatedText("ITEM", versionId, "instruction"))
                .isEqualTo("[[es]] Check the finish");
        assertThat(translatedText("ITEM", versionId, "standardSpec"))
                .isEqualTo("[[es]] No cracks or leaks");
        assertThat(translationStatus("ITEM", versionId, "instruction"))
                .isEqualTo("PENDING_REVIEW");

        JsonNode second = backfill(platform, """
                {"languages":["es"],"entityTypes":["ITEM","CATEGORY"]}
                """);
        assertThat(second.get("enqueued").asInt()).isZero();
        assertThat(second.get("skipped").asInt()).isEqualTo(4);
        assertThat(jobStates(versionId)).containsOnly("DONE");

        worker.workOnce();
        assertThat(jobStates(versionId)).containsOnly("DONE");
        assertThat(translatedText("ITEM", versionId, "instruction"))
                .isEqualTo("[[es]] Check the finish");
    }

    // ---------------------------------------------------------------- helpers

    private JsonNode backfill(Login login, String body) throws Exception {
        ResultActions result = mockMvc.perform(post(BACKFILL)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
        MvcResult completed = result.andReturn();
        return objectMapper.readTree(completed.getResponse().getContentAsString());
    }

    private void backfillExpecting(Login login, String body,
                                   org.springframework.test.web.servlet.ResultMatcher status,
                                   String code) throws Exception {
        mockMvc.perform(post(BACKFILL)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status)
                .andExpect(jsonPath("$.code").value(code));
    }

    private static List<String> texts(JsonNode array) {
        List<String> values = new java.util.ArrayList<>();
        array.forEach(node -> values.add(node.asText()));
        return values;
    }

    private void insertRow(String entityType, String entityId, String field, String lang,
                           String body, String origin, String rowStatus, String sourceHash) {
        jdbc.update("""
                INSERT INTO content_translation
                    (id, entity_type, entity_id, field_name, lang, body, origin, status,
                     source_lang, source_hash, provider, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'en', ?, 'fake', CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), entityType, entityId, field, lang, body,
                origin, rowStatus, sourceHash);
    }

    private String category(String code, String name) {
        String id = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 0, 'ACTIVE', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name);
        return id;
    }

    private String item(String code, String categoryId, String label, String instruction,
                        String standardSpec) {
        String itemId = UUID.randomUUID().toString();
        String versionId = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id,
                     sample_data, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'PUBLISHED', NULL, FALSE, 0, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, itemId, code, categoryId);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction, standard_spec,
                     safety_critical, multi_point, allow_free_text_note, note_requirement,
                     evidence_requirement, min_photos, created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', ?, ?, ?, FALSE, FALSE, FALSE, 'OPTIONAL',
                        'NONE', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, versionId, itemId, label, instruction, standardSpec);
        jdbc.update("UPDATE platform_items SET current_published_version_id = ? WHERE id = ?",
                versionId, itemId);
        return versionId;
    }

    private int jobCount(String entityId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation_job WHERE entity_id = ?
                """, Integer.class, entityId);
        return count == null ? 0 : count;
    }

    private List<String> jobStates(String entityId) {
        return jdbc.queryForList("""
                SELECT state FROM content_translation_job WHERE entity_id = ? ORDER BY field_name
                """, String.class, entityId);
    }

    private String translatedText(String entityType, String entityId, String field) {
        return jdbc.queryForObject("""
                SELECT body FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = 'es'
                """, String.class, entityType, entityId, field);
    }

    private String translationStatus(String entityType, String entityId, String field) {
        return jdbc.queryForObject("""
                SELECT status FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = 'es'
                """, String.class, entityType, entityId, field);
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
