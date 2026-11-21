package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.shared.i18n.ContentChangePublisher;
import com.truereport.shared.i18n.ContentTranslationWorker;
import com.truereport.shared.i18n.TranslationJobStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ContentTranslationJobIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationWorker worker;

    @Autowired
    ContentChangePublisher changes;

    @Test
    void createAndUpdateEnqueueOnceAndMarkTranslationsStale() throws Exception {
        Login platform = login("platform@test.local");
        String code = "JOB-CAT-" + UUID.randomUUID().toString().substring(0, 8);
        JsonNode created = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"%s","name":"Job Category"}
                """.formatted(code), null);
        String id = created.get("id").asText();

        assertThat(jobCount("CATEGORY", id)).isEqualTo(2);
        assertThat(jobLangs("CATEGORY", id)).containsExactly("es", "fr");

        // Same text: no duplicate job and no extra rows.
        putJson(platform, "/api/v1/platform/master/categories/" + id,
                "{\"name\":\"Job Category\"}", null).andExpect(status().isOk());
        assertThat(jobCount("CATEGORY", id)).isEqualTo(2);

        assertThat(worker.workOnce()).isPositive();
        assertThat(translationBody("CATEGORY", id, "es")).isEqualTo("[[es]] Job Category");
        assertThat(translationBody("CATEGORY", id, "fr")).isEqualTo("[[fr]] Job Category");
        assertThat(translationField("CATEGORY", id, "es", "origin")).isEqualTo("MACHINE");
        assertThat(translationField("CATEGORY", id, "es", "status"))
                .isEqualTo("PENDING_REVIEW");
        assertThat(translationField("CATEGORY", id, "es", "provider")).isEqualTo("fake");
        assertThat(jobState("CATEGORY", id, "es")).isEqualTo("DONE");

        // Re-running is a no-op.
        assertThat(worker.workOnce()).isZero();

        // Source change: existing rows become STALE and jobs are re-opened once.
        putJson(platform, "/api/v1/platform/master/categories/" + id,
                "{\"name\":\"Renamed Category\"}", null).andExpect(status().isOk());
        assertThat(translationField("CATEGORY", id, "es", "status")).isEqualTo("STALE");
        assertThat(jobCount("CATEGORY", id)).isEqualTo(2);
        assertThat(worker.workOnce()).isPositive();
        assertThat(translationBody("CATEGORY", id, "es")).isEqualTo("[[es]] Renamed Category");

        // Delete cleanup removes both rows and jobs.
        changes.deleteAll("CATEGORY", id);
        assertThat(jobCount("CATEGORY", id)).isZero();
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation
                WHERE entity_type = 'CATEGORY' AND entity_id = ?
                """, Integer.class, id)).isZero();
    }

    @Test
    void workerSkipsAJobWhoseTranslationIsAlreadyCurrent() throws Exception {
        Login platform = login("platform@test.local");
        String code = "JOB-CUR-" + UUID.randomUUID().toString().substring(0, 8);
        JsonNode created = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"%s","name":"Current"}
                """.formatted(code), null);
        String id = created.get("id").asText();
        worker.workOnce();

        // Force a duplicate job without changing the source; the worker must
        // complete it without replacing the existing body.
        jdbc.update("""
                UPDATE content_translation_job SET state = 'PENDING', attempts = 0
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'es'
                """, id);
        assertThat(worker.workOnce()).isPositive();
        assertThat(translationBody("CATEGORY", id, "es")).isEqualTo("[[es]] Current");
        assertThat(jobState("CATEGORY", id, "es")).isEqualTo("DONE");
    }

    @Test
    void spanishAuthoringStoresAuthoredRowAndDerivesEnglish() throws Exception {
        Login platform = login("platform@test.local");
        String code = "ES-CAT-" + UUID.randomUUID().toString().substring(0, 8);
        JsonNode created = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"%s","name":"Sistema de frenos"}
                """.formatted(code), "es");
        String id = created.get("id").asText();

        assertThat(translationBody("CATEGORY", id, "es")).isEqualTo("Sistema de frenos");
        assertThat(translationField("CATEGORY", id, "es", "origin")).isEqualTo("AUTHORED");
        assertThat(translationField("CATEGORY", id, "es", "status")).isEqualTo("REVIEWED");
        assertThat(translationField("CATEGORY", id, "es", "source_lang")).isEqualTo("es");
        assertThat(jobState("CATEGORY", id, "es")).isEqualTo("PENDING");
        assertThat(jobDirection("CATEGORY", id, "es")).isEqualTo(TranslationJobStore.TO_CANONICAL);

        assertThat(worker.workOnce()).isPositive();

        String canonicalName = jdbc.queryForObject(
                "SELECT name FROM platform_categories WHERE id = ?", String.class, id);
        assertThat(canonicalName).isEqualTo("[[en]] Sistema de frenos");
        assertThat(jobState("CATEGORY", id, "es")).isEqualTo("DONE");

        // Machine-derived English provenance lives on the canonical (en) row.
        Map<String, Object> provenance = jdbc.queryForMap("""
                SELECT body, origin, status, source_lang, provider
                FROM content_translation
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND field_name = 'name'
                  AND lang = 'en'
                """, id);
        assertThat(provenance.get("body")).isEqualTo("[[en]] Sistema de frenos");
        assertThat(provenance.get("origin")).isEqualTo("MACHINE");
        assertThat(provenance.get("status")).isEqualTo("PENDING_REVIEW");
        assertThat(provenance.get("source_lang")).isEqualTo("es");
        assertThat(provenance.get("provider")).isEqualTo("fake");

        JsonNode categories = getJson(platform, "/api/v1/platform/master/categories", null);
        JsonNode category = find(categories, id);
        assertThat(category.get("translationStatus").asText())
                .isEqualTo("MACHINE_PENDING_REVIEW");
        assertThat(category.get("name").asText()).isEqualTo("[[en]] Sistema de frenos");

        JsonNode esCategories = getJson(platform, "/api/v1/platform/master/categories", "es");
        assertThat(find(esCategories, id).get("name").asText())
                .isEqualTo("Sistema de frenos");
    }

    // ------------------------------------------------------------------ helpers

    private JsonNode find(JsonNode rows, String id) {
        for (JsonNode row : rows) {
            if (id.equals(row.get("id").asText())) {
                return row;
            }
        }
        throw new AssertionError("Category not found: " + id);
    }

    private int jobCount(String entityType, String entityId) {
        return jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ?
                """, Integer.class, entityType, entityId);
    }

    private List<String> jobLangs(String entityType, String entityId) {
        return jdbc.queryForList("""
                SELECT lang FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ? ORDER BY lang
                """, String.class, entityType, entityId);
    }

    private String jobState(String entityType, String entityId, String lang) {
        return jdbc.queryForObject("""
                SELECT state FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ? AND lang = ?
                """, String.class, entityType, entityId, lang);
    }

    private String jobDirection(String entityType, String entityId, String lang) {
        return jdbc.queryForObject("""
                SELECT direction FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ? AND lang = ?
                """, String.class, entityType, entityId, lang);
    }

    private String translationBody(String entityType, String entityId, String lang) {
        return jdbc.queryForObject("""
                SELECT body FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = 'name' AND lang = ?
                """, String.class, entityType, entityId, lang);
    }

    private String translationField(String entityType, String entityId, String lang,
                                    String column) {
        return jdbc.queryForObject("""
                SELECT %s FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = 'name' AND lang = ?
                """.formatted(column), String.class, entityType, entityId, lang);
    }

    private JsonNode getJson(Login login, String path, String lang) throws Exception {
        MockHttpServletRequestBuilder request = get(path)
                .header("Authorization", bearer(login));
        if (lang != null) {
            request.header("Accept-Language", lang);
        }
        MvcResult result = mockMvc.perform(request).andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode postJson(Login login, String path, String body, String contentLanguage)
            throws Exception {
        MockHttpServletRequestBuilder request = post(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body);
        if (contentLanguage != null) {
            request.header("Content-Language", contentLanguage);
        }
        MvcResult result = mockMvc.perform(request).andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private org.springframework.test.web.servlet.ResultActions putJson(
            Login login, String path, String body, String contentLanguage) throws Exception {
        MockHttpServletRequestBuilder request = put(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body);
        if (contentLanguage != null) {
            request.header("Content-Language", contentLanguage);
        }
        return mockMvc.perform(request);
    }

    private static String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
