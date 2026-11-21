package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.shared.i18n.ContentTranslationWorker;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ContentReviewGateIT extends IntegrationTestBase {

    private static final String CONTENT = "/api/v1/platform/i18n/content";
    private static final String MASTER = "/api/v1/platform/master";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationWorker worker;

    @Test
    void approveEditAndRejectControlWhatIsServed() throws Exception {
        Login platform = login("platform@test.local");
        String code = "REV-CAT-" + UUID.randomUUID().toString().substring(0, 8);
        JsonNode created = postJson(platform, MASTER + "/categories", """
                {"code":"%s","name":"Review category"}
                """.formatted(code), null);
        String id = created.get("id").asText();
        worker.workOnce();

        JsonNode queue = getJson(platform, CONTENT + "/review?lang=es&state=PENDING_REVIEW");
        JsonNode item = findByEntity(queue, id);
        assertThat(item).isNotNull();
        assertThat(item.get("entityType").asText()).isEqualTo("CATEGORY");
        assertThat(item.get("field").asText()).isEqualTo("name");
        assertThat(item.get("sourceText").asText()).isEqualTo("Review category");
        assertThat(item.get("safetyCritical").asBoolean()).isFalse();
        assertThat(item.get("provider").asText()).isEqualTo("fake");

        JsonNode approved = review(platform, "CATEGORY", id, "name", "es",
                "{\"action\":\"APPROVE\"}");
        assertThat(approved.get("status").asText()).isEqualTo("REVIEWED");
        assertThat(jdbc.queryForObject("""
                SELECT reviewed_by FROM content_translation
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND field_name = 'name'
                  AND lang = 'es'
                """, String.class, id)).isNotBlank();
        assertThat(findByEntity(getJson(platform,
                CONTENT + "/review?lang=es&state=PENDING_REVIEW"), id)).isNull();

        JsonNode edited = review(platform, "CATEGORY", id, "name", "fr",
                "{\"action\":\"EDIT\",\"body\":\"Freinage\"}");
        assertThat(edited.get("origin").asText()).isEqualTo("AUTHORED");
        assertThat(edited.get("status").asText()).isEqualTo("REVIEWED");
        assertThat(edited.get("body").asText()).isEqualTo("Freinage");
        assertThat(itemName(platform, id, "fr")).isEqualTo("Freinage");

        JsonNode rejected = review(platform, "CATEGORY", id, "name", "es",
                "{\"action\":\"REJECT\",\"note\":\"wrong tone\"}");
        assertThat(rejected.get("status").asText()).isEqualTo("STALE");
        assertThat(itemName(platform, id, "es")).isEqualTo("Review category");
        assertThat(jdbc.queryForObject("""
                SELECT review_note FROM content_translation
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND field_name = 'name'
                  AND lang = 'es'
                """, String.class, id)).isEqualTo("wrong tone");

        JsonNode categories = getJson(platform, MASTER + "/categories?lang=es");
        JsonNode category = find(categories, id);
        assertThat(category.get("translationStatus").asText()).isEqualTo("STALE");
    }

    @Test
    void templatePublishIsBlockedUntilSafetyCriticalCanonicalIsReviewed() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String categoryCode = "GATE-CAT-" + suffix;
        JsonNode category = postJson(platform, MASTER + "/categories", """
                {"code":"%s","name":"Gate category"}
                """.formatted(categoryCode), null);
        String categoryId = category.get("id").asText();
        JsonNode item = postJson(platform, MASTER + "/items", """
                {"stableCode":"GATE-ITEM-%s","categoryId":"%s","label":"Safety item",
                 "instruction":"Torque {name} to 85-100 Nm","standardSpec":"Minimum 3.0 mm",
                 "sampleData":false,
                 "resultOptions":["NO_ISSUE_OBSERVED","ATTENTION_RECOMMENDED","DEFECT_FOUND"]}
                """.formatted(suffix, categoryId), "es");
        String itemId = item.get("item").get("id").asText();
        String versionId = item.get("versions").get(0).get("id").asText();
        worker.workOnce();

        String template = "Template " + suffix;
        JsonNode templateNode = postJson(platform, MASTER + "/templates", """
                {"code":"GATE-TPL-%s","name":"%s"}
                """.formatted(suffix, template), null);
        String templateId = templateNode.get("id").asText();
        String templateVersionId = templateNode.get("versions").get(0).get("id").asText();

        putJson(platform, MASTER + "/templates/" + templateId + "/versions/"
                + templateVersionId + "/categories", """
                {"categories":[{"categoryId":"%s","included":true,"sortOrder":1}]}
                """.formatted(categoryId)).andExpect(status().isOk());
        putJson(platform, MASTER + "/templates/" + templateId + "/versions/"
                + templateVersionId + "/items", """
                {"items":[{"categoryId":"%s","itemVersionId":"%s","included":true,
                 "sortOrder":1}]}
                """.formatted(categoryId, versionId)).andExpect(status().isOk());

        MvcResult blocked = mockMvc.perform(post(MASTER + "/templates/" + templateId
                                + "/versions/" + templateVersionId + "/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REVIEW_REQUIRED"))
                .andExpect(jsonPath("$.translationIssues").isArray())
                .andReturn();
        JsonNode issues = objectMapper.readTree(blocked.getResponse().getContentAsString())
                .get("translationIssues");
        Set<String> fields = new HashSet<>();
        issues.forEach(issue -> fields.add(issue.get("field").asText()));
        assertThat(fields).contains("instruction", "standardSpec");
        assertThat(fields).doesNotContain("label");

        review(platform, "ITEM", versionId, "instruction", "en", "{\"action\":\"APPROVE\"}");
        review(platform, "ITEM", versionId, "standardSpec", "en", "{\"action\":\"APPROVE\"}");

        mockMvc.perform(post(MASTER + "/templates/" + templateId + "/versions/"
                                + templateVersionId + "/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk());
        assertThat(itemId).isNotBlank();
    }

    @Test
    void languageGoLiveIsBlockedUntilSafetyCriticalTranslationsAreReviewed() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        JsonNode category = postJson(platform, MASTER + "/categories", """
                {"code":"LANG-CAT-%s","name":"Language category"}
                """.formatted(suffix), null);
        String categoryId = category.get("id").asText();
        JsonNode item = postJson(platform, MASTER + "/items", """
                {"stableCode":"LANG-ITEM-%s","categoryId":"%s","label":"Language item",
                 "instruction":"Check the brake pad","standardSpec":"Minimum 3.0 mm",
                 "sampleData":false,
                 "resultOptions":["NO_ISSUE_OBSERVED","ATTENTION_RECOMMENDED","DEFECT_FOUND"]}
                """.formatted(suffix, categoryId), null);
        String versionId = item.get("versions").get(0).get("id").asText();
        worker.workOnce();
        demoteLanguage("es");

        MvcResult blocked = mockMvc.perform(post("/api/v1/platform/i18n/languages/es/go-live")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REVIEW_REQUIRED"))
                .andReturn();
        JsonNode issues = objectMapper.readTree(blocked.getResponse().getContentAsString())
                .get("translationIssues");
        assertThat(issues.size()).isGreaterThan(0);
        assertThat(issues.get(0).get("lang").asText()).isEqualTo("es");

        review(platform, "ITEM", versionId, "instruction", "es", "{\"action\":\"APPROVE\"}");
        review(platform, "ITEM", versionId, "standardSpec", "es",
                "{\"action\":\"APPROVE\"}");

        mockMvc.perform(post("/api/v1/platform/i18n/languages/es/go-live")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("LIVE"));
    }

    @Test
    void languageGoLiveReportsMissingFieldsAndCapsAtFifty() throws Exception {
        Login platform = login("platform@test.local");
        demoteLanguage("es");
        seedItemsWithoutTranslations(30);

        MvcResult blocked = mockMvc.perform(post("/api/v1/platform/i18n/languages/es/go-live")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isConflict())
                .andReturn();
        JsonNode issues = objectMapper.readTree(blocked.getResponse().getContentAsString())
                .get("translationIssues");
        assertThat(issues.size()).isEqualTo(50);
        for (JsonNode issue : issues) {
            assertThat(issue.get("entityType").asText()).isEqualTo("ITEM");
            assertThat(issue.get("lang").asText()).isEqualTo("es");
            assertThat(issue.get("reason").asText()).isEqualTo("MISSING");
            assertThat(issue.get("entityId").asText()).isNotBlank();
            assertThat(issue.get("field").asText()).isIn("instruction", "standardSpec");
        }
    }

    @Test
    void entityWithoutTranslationsStillPublishes() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        JsonNode category = postJson(platform, MASTER + "/categories", """
                {"code":"HUMAN-CAT-%s","name":"Human category"}
                """.formatted(suffix), null);
        String categoryId = category.get("id").asText();
        JsonNode item = postJson(platform, MASTER + "/items", """
                {"stableCode":"HUMAN-ITEM-%s","categoryId":"%s","label":"Human item",
                 "instruction":"Visual check","standardSpec":"No damage",
                 "sampleData":false,
                 "resultOptions":["NO_ISSUE_OBSERVED","ATTENTION_RECOMMENDED","DEFECT_FOUND"]}
                """.formatted(suffix, categoryId), null);
        String versionId = item.get("versions").get(0).get("id").asText();
        JsonNode templateNode = postJson(platform, MASTER + "/templates", """
                {"code":"HUMAN-TPL-%s","name":"Human template"}
                """.formatted(suffix), null);
        String templateId = templateNode.get("id").asText();
        String templateVersionId = templateNode.get("versions").get(0).get("id").asText();
        putJson(platform, MASTER + "/templates/" + templateId + "/versions/"
                + templateVersionId + "/categories", """
                {"categories":[{"categoryId":"%s","included":true,"sortOrder":1}]}
                """.formatted(categoryId)).andExpect(status().isOk());
        putJson(platform, MASTER + "/templates/" + templateId + "/versions/"
                + templateVersionId + "/items", """
                {"items":[{"categoryId":"%s","itemVersionId":"%s","included":true,
                 "sortOrder":1}]}
                """.formatted(categoryId, versionId)).andExpect(status().isOk());

        mockMvc.perform(post(MASTER + "/templates/" + templateId + "/versions/"
                                + templateVersionId + "/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk());
    }

    @Test
    void contentLanguagesRequireLiveRegistryRowAndContentRows() throws Exception {
        Login platform = login("platform@test.local");
        seedContentRow("es", "STALE");
        seedContentRow("en", "PENDING_REVIEW");

        JsonNode languages = getJson(platform, CONTENT + "/languages");
        assertThat(languages).hasSize(1);
        JsonNode spanish = languages.get(0);
        assertThat(spanish.get("code").asText()).isEqualTo("es");
        assertThat(spanish.get("name").asText()).isEqualTo("Español");
        assertThat(spanish.get("nativeName").asText()).isEqualTo("Español");
        assertThat(spanish.get("direction").asText()).isEqualTo("ltr");
        assertThat(spanish.get("sortOrder").asInt()).isEqualTo(2);

        // The registry lists every LIVE DB row, while the content selector also
        // requires at least one translation row for the language.
        JsonNode uiLanguages = getJson(platform, "/api/v1/platform/i18n/languages");
        assertThat(uiLanguages).hasSize(3);
        assertThat(uiLanguages.get(0).get("code").asText()).isEqualTo("en");
        assertThat(uiLanguages.get(1).get("code").asText()).isEqualTo("es");
        assertThat(uiLanguages.get(2).get("code").asText()).isEqualTo("fr");
    }

    @Test
    void contentLanguagesFollowRegistryOrderAndIgnoreUnknownCodes() throws Exception {
        Login platform = login("platform@test.local");
        seedContentRow("fr", "REVIEWED");
        seedContentRow("es", "PENDING_REVIEW");
        // Not present in platform_languages: never offered for review.
        seedContentRow("de", "REVIEWED");

        JsonNode languages = getJson(platform, CONTENT + "/languages");
        assertThat(languages).hasSize(2);
        assertThat(languages.get(0).get("code").asText()).isEqualTo("es");
        assertThat(languages.get(0).get("sortOrder").asInt()).isEqualTo(2);
        assertThat(languages.get(1).get("code").asText()).isEqualTo("fr");
        assertThat(languages.get(1).get("name").asText()).isEqualTo("Français");
        assertThat(languages.get(1).get("nativeName").asText()).isEqualTo("Français");
        assertThat(languages.get(1).get("sortOrder").asInt()).isEqualTo(3);
    }

    @Test
    void contentLanguagesOmitLanguagesWithoutRows() throws Exception {
        Login platform = login("platform@test.local");
        seedContentRow("fr", "REVIEWED");

        JsonNode languages = getJson(platform, CONTENT + "/languages");
        assertThat(languages).hasSize(1);
        assertThat(languages.get(0).get("code").asText()).isEqualTo("fr");
    }

    @Test
    void contentLanguagesAreEmptyWithoutContentRows() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode languages = getJson(platform, CONTENT + "/languages");
        assertThat(languages).isEmpty();
    }

    @Test
    void contentLanguagesRequirePlatformAdmin() throws Exception {
        Login workshopAdmin = login("admin.a@test.local");

        mockMvc.perform(get(CONTENT + "/languages")
                        .header("Authorization", bearer(workshopAdmin)))
                .andExpect(status().isForbidden());
    }

    // ------------------------------------------------------------------ helpers

    private void seedContentRow(String lang, String status) {
        jdbc.update("""
                INSERT INTO content_translation
                    (id, entity_type, entity_id, field_name, lang, body, origin, status,
                     source_lang, source_hash, created_at, updated_at)
                VALUES (?, 'CATEGORY', ?, 'name', ?, 'Contenido', 'AUTHORED', ?,
                        'en', 'hash', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), UUID.randomUUID().toString(), lang, status);
    }

    private void demoteLanguage(String code) {
        jdbc.update("""
                UPDATE platform_languages
                SET active = FALSE, status = 'DRAFT', updated_at = CURRENT_TIMESTAMP
                WHERE code = ?
                """, code);
    }

    private void seedItemsWithoutTranslations(int count) {
        String categoryId = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, 'Cap category', 0, 'ACTIVE', 0,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, categoryId, "CAP-CAT-" + categoryId.substring(0, 8));
        for (int index = 0; index < count; index++) {
            String itemId = UUID.randomUUID().toString();
            String versionId = UUID.randomUUID().toString();
            jdbc.update("""
                    INSERT INTO platform_items
                        (id, stable_code, category_id, status, current_published_version_id,
                         sample_data, sort_order, created_at, updated_at, version)
                    VALUES (?, ?, ?, 'PUBLISHED', NULL, FALSE, ?, CURRENT_TIMESTAMP,
                            CURRENT_TIMESTAMP, 0)
                    """, itemId, "CAP-ITEM-" + itemId.substring(0, 8), categoryId, index);
            jdbc.update("""
                    INSERT INTO platform_item_versions
                        (id, item_id, version_no, status, label, instruction,
                         standard_spec, safety_critical, multi_point, allow_free_text_note,
                         result_options_json, note_requirement, evidence_requirement,
                         min_photos, created_at, updated_at, version)
                    VALUES (?, ?, 1, 'PUBLISHED', ?, 'Instruction', 'Standard',
                            FALSE, FALSE, FALSE, '[]', 'OPTIONAL', 'REQUIRED', 1,
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                    """, versionId, itemId, "Cap item " + index);
            jdbc.update("UPDATE platform_items SET current_published_version_id = ? "
                    + "WHERE id = ?", versionId, itemId);
        }
    }

    private JsonNode review(Login login, String entityType, String entityId, String field,
                            String lang, String body) throws Exception {
        MvcResult result = mockMvc.perform(post(CONTENT + "/" + entityType + "/" + entityId
                                + "/" + field + "/review?lang=" + lang)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String itemName(Login login, String id, String lang) throws Exception {
        JsonNode categories = getJson(login, MASTER + "/categories?lang=" + lang);
        JsonNode category = find(categories, id);
        return category == null ? null : category.get("name").asText();
    }

    private JsonNode findByEntity(JsonNode rows, String entityId) {
        for (JsonNode row : rows) {
            if (entityId.equals(row.get("entityId").asText())) {
                return row;
            }
        }
        return null;
    }

    private JsonNode find(JsonNode rows, String id) {
        for (JsonNode row : rows) {
            if (id.equals(row.get("id").asText())) {
                return row;
            }
        }
        return null;
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk()).andReturn();
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
        MvcResult result = mockMvc.perform(request).andReturn();
        int status = result.getResponse().getStatus();
        assertThat(status).as("POST " + path + " body=" + body + " -> " + result.getResponse()
                .getContentAsString()).isBetween(200, 299);
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private org.springframework.test.web.servlet.ResultActions putJson(
            Login login, String path, String body) throws Exception {
        return mockMvc.perform(put(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private static String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
