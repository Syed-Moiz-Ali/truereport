package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.shared.i18n.LocalizedFields;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ContentTranslationIT extends IntegrationTestBase {

    private static final String CONTENT = "/api/v1/platform/i18n/content";

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void exactHitFallsBackToDefaultAndEntityWithoutTranslationIsUnchanged() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}", null);

        CategoryRow category = firstCategory();
        ItemRow item = firstItem();
        String french = "Plaquettes de frein";
        String spanish = "Pastillas de freno";

        putJson(platform, CONTENT + "/CATEGORY/" + category.id() + "/name?lang=fr",
                "{\"body\":\"Freinage\"}", null).andExpect(status().isOk());
        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/label?lang=fr",
                "{\"body\":\"" + french + "\"}", null).andExpect(status().isOk());
        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/label?lang=es",
                "{\"body\":\"" + spanish + "\"}", null).andExpect(status().isOk());

        JsonNode frenchItems = getJson(platform,
                "/api/v1/platform/master/items/" + item.itemId(), "fr");
        assertThat(frenchItems.get("item").get("label").asText()).isEqualTo(french);
        assertThat(frenchItems.get("item").get("labelEn").asText()).isEqualTo(item.label());

        JsonNode spanishItems = getJson(platform,
                "/api/v1/platform/master/items/" + item.itemId(), "es");
        assertThat(spanishItems.get("item").get("label").asText()).isEqualTo(spanish);

        // A language with no row falls back to the English source.
        JsonNode defaultItems = getJson(platform,
                "/api/v1/platform/master/items/" + item.itemId(), null);
        assertThat(defaultItems.get("item").get("label").asText()).isEqualTo(item.label());
        assertThat(defaultItems.get("item").has("labelEn")).isTrue();

        JsonNode frenchCategories = getJson(platform,
                "/api/v1/platform/master/categories", "fr");
        assertThat(frenchCategories.get(0).get("name").asText()).isEqualTo("Freinage");
        assertThat(frenchCategories.get(0).get("nameEn").asText()).isEqualTo(category.name());
    }

    @Test
    void coverageMatchesLiveCountsAndWriteDeleteInvalidatesCache() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}", null);
        ItemRow item = firstItem();

        int total = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_item_versions
                WHERE label IS NOT NULL AND label <> ''
                """, Integer.class);

        JsonNode before = coverage(platform, "es", "ITEM");
        JsonNode labelCoverage = coverageItem(before, "ITEM", "label");
        assertThat(labelCoverage.get("total").asInt()).isEqualTo(total);
        assertThat(labelCoverage.get("translated").asInt()).isZero();
        assertThat(labelCoverage.get("missing").asInt()).isEqualTo(total);
        assertThat(labelCoverage.get("stale").asInt()).isZero();
        assertThat(labelCoverage.get("safetyCritical").asBoolean()).isFalse();

        // Prime the cache with the English fallback, then write and read again.
        assertThat(itemLabel(platform, item, "es")).isEqualTo(item.label());
        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/label?lang=es",
                "{\"body\":\"Etiqueta\"}", null).andExpect(status().isOk());
        assertThat(itemLabel(platform, item, "es")).isEqualTo("Etiqueta");

        // Overwriting an already-cached value must invalidate the cache entry.
        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/label?lang=es",
                "{\"body\":\"Etiqueta dos\"}", null).andExpect(status().isOk());
        assertThat(itemLabel(platform, item, "es")).isEqualTo("Etiqueta dos");

        JsonNode afterWrite = coverageItem(coverage(platform, "es", "ITEM"), "ITEM", "label");
        assertThat(afterWrite.get("translated").asInt()).isEqualTo(1);
        assertThat(afterWrite.get("missing").asInt()).isEqualTo(total - 1);

        mockMvc.perform(delete(CONTENT + "/ITEM/" + item.versionId() + "/label?lang=es")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isNoContent());
        assertThat(itemLabel(platform, item, "es")).isEqualTo(item.label());

        JsonNode afterDelete = coverageItem(coverage(platform, "es", "ITEM"), "ITEM", "label");
        assertThat(afterDelete.get("translated").asInt()).isZero();
        assertThat(afterDelete.get("missing").asInt()).isEqualTo(total);
    }

    @Test
    void manualWriteValidationAndRegistryGuard() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}", null);
        ItemRow item = firstItem();

        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/notAField?lang=es",
                "{\"body\":\"x\"}", null)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("FIELD_NOT_TRANSLATABLE"));
        putJson(platform, CONTENT + "/ITEM/00000000-0000-0000-0000-000000000000/label?lang=es",
                "{\"body\":\"x\"}", null)
                .andExpect(status().isNotFound());
        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/label?lang=de",
                "{\"body\":\"x\"}", null)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_UNKNOWN"));
        putJson(platform, CONTENT + "/ITEM/" + item.versionId() + "/label?lang=es",
                "{\"body\":\"" + "x".repeat(201) + "\"}", null)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("BODY_TOO_LONG"));

        for (Map.Entry<String, Set<String>> entry : LocalizedFields.all().entrySet()) {
            for (String field : entry.getValue()) {
                Integer count = jdbc.queryForObject("""
                        SELECT COUNT(*) FROM translatable_field
                        WHERE entity_type = ? AND field_name = ? AND enabled = TRUE
                        """, Integer.class, entry.getKey(), field);
                assertThat(count).as(entry.getKey() + "." + field).isEqualTo(1);
            }
        }
    }

    @Test
    void defaultLanguagePayloadsAreUnchanged() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}", null);
        ItemRow item = firstItem();

        String categoriesWithoutHeader = getRaw(platform,
                "/api/v1/platform/master/categories", null);
        String categoriesEnglish = getRaw(platform,
                "/api/v1/platform/master/categories", "en");
        assertThat(categoriesEnglish).isEqualTo(categoriesWithoutHeader);

        JsonNode categoryJson = objectMapper.readTree(categoriesWithoutHeader).get(0);
        assertThat(fieldNames(categoryJson)).doesNotContain("description");

        String itemWithoutHeader = getRaw(platform,
                "/api/v1/platform/master/items/" + item.itemId(), null);
        String itemEnglish = getRaw(platform,
                "/api/v1/platform/master/items/" + item.itemId(), "en");
        assertThat(itemEnglish).isEqualTo(itemWithoutHeader);
        JsonNode itemJson = objectMapper.readTree(itemWithoutHeader).get("item");
        assertThat(itemJson.get("label").asText()).isEqualTo(item.label());
        assertThat(itemJson.get("labelEn").asText()).isEqualTo(item.label());
    }

    // ------------------------------------------------------------------ helpers

    private record CategoryRow(String id, String name) {
    }

    private record ItemRow(String itemId, String versionId, String label) {
    }

    private CategoryRow firstCategory() {
        return jdbc.query("""
                SELECT id, name FROM platform_categories
                WHERE status = 'ACTIVE' ORDER BY sort_order, code LIMIT 1
                """, (rs, i) -> new CategoryRow(rs.getString("id"), rs.getString("name")))
                .stream().findFirst().orElseThrow();
    }

    private ItemRow firstItem() {
        return jdbc.query("""
                SELECT i.id AS item_id, i.current_published_version_id AS version_id,
                       v.label
                FROM platform_items i
                JOIN platform_item_versions v ON v.id = i.current_published_version_id
                ORDER BY i.stable_code
                LIMIT 1
                """, (rs, i) -> new ItemRow(rs.getString("item_id"),
                rs.getString("version_id"), rs.getString("label")))
                .stream().findFirst().orElseThrow();
    }

    private String itemLabel(Login login, ItemRow item, String lang) throws Exception {
        JsonNode node = getJson(login, "/api/v1/platform/master/items/" + item.itemId(), lang);
        return node.get("item").get("label").asText();
    }

    private JsonNode coverage(Login login, String lang, String entityType) throws Exception {
        return getJson(login, CONTENT + "/coverage?lang=" + lang
                + (entityType == null ? "" : "&entityType=" + entityType), null);
    }

    private JsonNode coverageItem(JsonNode coverage, String entityType, String field) {
        for (JsonNode row : coverage) {
            if (entityType.equals(row.get("entityType").asText())
                    && field.equals(row.get("field").asText())) {
                return row;
            }
        }
        throw new AssertionError("Coverage row not found: " + entityType + "." + field);
    }

    private static Set<String> fieldNames(JsonNode node) {
        Set<String> names = new HashSet<>();
        node.fieldNames().forEachRemaining(names::add);
        return names;
    }

    private String getRaw(Login login, String path, String lang) throws Exception {
        MockHttpServletRequestBuilder request = get(path)
                .header("Authorization", bearer(login));
        if (lang != null) {
            request.header("Accept-Language", lang);
        }
        MvcResult result = mockMvc.perform(request).andExpect(status().isOk()).andReturn();
        return result.getResponse().getContentAsString();
    }

    private JsonNode getJson(Login login, String path, String lang) throws Exception {
        return objectMapper.readTree(getRaw(login, path, lang));
    }

    private JsonNode postJson(Login login, String path, String body, String lang)
            throws Exception {
        MockHttpServletRequestBuilder request = post(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body);
        if (lang != null) {
            request.header("Accept-Language", lang);
        }
        MvcResult result = mockMvc.perform(request).andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private org.springframework.test.web.servlet.ResultActions putJson(
            Login login, String path, String body, String lang) throws Exception {
        MockHttpServletRequestBuilder request = put(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body);
        if (lang != null) {
            request.header("Accept-Language", lang);
        }
        return mockMvc.perform(request);
    }

    private static String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
