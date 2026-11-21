package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Authoring inventory: canonical units must be listed even when the target
 * language has no translation row at all.
 */
class ContentUnitsIT extends IntegrationTestBase {

    private static final String CONTENT = "/api/v1/platform/i18n/content";
    private static final String MASTER = "/api/v1/platform/master";

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void missingFieldListsCanonicalUnitWithoutRow() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        String name = "UnitSource-" + suffix;
        String id = createCategory(platform, name, "UCAT-" + suffix);

        JsonNode page = units(platform,
                "lang=es&entityType=CATEGORY&filter=missing&query=" + suffix);

        assertThat(page.get("lang").asText()).isEqualTo("es");
        assertThat(page.get("total").asInt()).isEqualTo(1);
        assertThat(page.get("page").asInt()).isZero();
        assertThat(page.get("size").asInt()).isEqualTo(50);

        JsonNode item = page.get("items").get(0);
        assertThat(item.get("entityType").asText()).isEqualTo("CATEGORY");
        assertThat(item.get("entityId").asText()).isEqualTo(id);
        assertThat(item.get("field").asText()).isEqualTo("name");
        assertThat(item.get("sourceText").asText()).isEqualTo(name);
        assertThat(item.get("text").isNull()).isTrue();
        assertThat(item.get("status").isNull()).isTrue();
        assertThat(item.get("origin").isNull()).isTrue();
        assertThat(item.get("safetyCritical").asBoolean()).isFalse();
    }

    @Test
    void existingRowsExposeBodyStatusAndOrigin() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();

        String authoredToken = "Authored" + suffix;
        String authoredId = createCategory(platform, "Units-" + authoredToken, "AUCAT-" + suffix);
        String authoredBody = "Categoria-" + authoredToken;
        putJson(platform, CONTENT + "/CATEGORY/" + authoredId + "/name?lang=es",
                "{\"body\":\"" + authoredBody + "\"}").andExpect(status().isOk());

        JsonNode authored = single(units(platform,
                "lang=es&entityType=CATEGORY&filter=all&query=" + authoredToken));
        assertThat(authored.get("text").asText()).isEqualTo(authoredBody);
        assertThat(authored.get("status").asText()).isEqualTo("REVIEWED");
        assertThat(authored.get("origin").asText()).isEqualTo("AUTHORED");

        String machineToken = "Machine" + suffix;
        String machineId = createCategory(platform, "Units-" + machineToken, "MUCAT-" + suffix);
        String machineBody = "Maquina-" + machineToken;
        jdbc.update("""
                INSERT INTO content_translation
                    (id, entity_type, entity_id, field_name, lang, body, origin, status,
                     source_lang, source_hash, created_at, updated_at)
                VALUES (?, 'CATEGORY', ?, 'name', 'es', ?, 'MACHINE', 'PENDING_REVIEW',
                        'en', 'hash', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), machineId, machineBody);

        JsonNode machine = single(units(platform,
                "lang=es&entityType=CATEGORY&filter=all&query=" + machineToken));
        assertThat(machine.get("text").asText()).isEqualTo(machineBody);
        assertThat(machine.get("status").asText()).isEqualTo("PENDING_REVIEW");
        assertThat(machine.get("origin").asText()).isEqualTo("MACHINE");

        // A row that exists is not "missing", but a blank body is.
        assertThat(units(platform, "lang=es&entityType=CATEGORY&filter=missing&query="
                + authoredToken).get("total").asInt()).isZero();
        jdbc.update("""
                UPDATE content_translation SET body = '   '
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND field_name = 'name'
                  AND lang = 'es'
                """, machineId);
        assertThat(units(platform, "lang=es&entityType=CATEGORY&filter=missing&query="
                + machineToken).get("total").asInt()).isEqualTo(1);
    }

    @Test
    void filterAllIsSupersetOfMissing() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        String missingId = createCategory(platform, "SupersetMissing-" + suffix,
                "SUCAT-A-" + suffix);
        String translatedId = createCategory(platform, "SupersetTranslated-" + suffix,
                "SUCAT-B-" + suffix);

        JsonNode all = units(platform, "lang=es&entityType=CATEGORY&filter=all&query=" + suffix);
        JsonNode missing = units(platform,
                "lang=es&entityType=CATEGORY&filter=missing&query=" + suffix);
        assertThat(all.get("total").asInt()).isEqualTo(2);
        assertThat(missing.get("total").asInt()).isEqualTo(2);
        assertThat(all.get("total").asInt()).isGreaterThanOrEqualTo(missing.get("total").asInt());

        putJson(platform, CONTENT + "/CATEGORY/" + translatedId + "/name?lang=es",
                "{\"body\":\"Traducido-" + suffix + "\"}").andExpect(status().isOk());

        JsonNode allAfter = units(platform,
                "lang=es&entityType=CATEGORY&filter=all&query=" + suffix);
        JsonNode missingAfter = units(platform,
                "lang=es&entityType=CATEGORY&filter=missing&query=" + suffix);
        assertThat(allAfter.get("total").asInt()).isEqualTo(2);
        assertThat(missingAfter.get("total").asInt()).isEqualTo(1);
        assertThat(allAfter.get("total").asInt())
                .isGreaterThanOrEqualTo(missingAfter.get("total").asInt());
        assertThat(entityIds(missingAfter)).containsExactly(missingId);
    }

    @Test
    void queryMatchesSourceAndTranslationAndPagingSlicesStableOrder() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        String sourceToken = "Bleed" + suffix;
        List<String> ids = new ArrayList<>();
        ids.add(createCategory(platform, sourceToken + "-Alpha", "PUCA-A-" + suffix));
        ids.add(createCategory(platform, sourceToken + "-Bravo", "PUCA-B-" + suffix));
        ids.add(createCategory(platform, sourceToken + "-Charlie", "PUCA-C-" + suffix));

        JsonNode bySource = units(platform,
                "lang=es&entityType=CATEGORY&query=" + sourceToken);
        assertThat(bySource.get("total").asInt()).isEqualTo(3);

        // Case-insensitive match on the translation body only.
        putJson(platform, CONTENT + "/CATEGORY/" + ids.get(1) + "/name?lang=es",
                "{\"body\":\"FrenadoZeta\"}").andExpect(status().isOk());
        JsonNode byTranslation = units(platform,
                "lang=es&entityType=CATEGORY&query=frenadozeta");
        assertThat(byTranslation.get("total").asInt()).isEqualTo(1);
        assertThat(byTranslation.get("items").get(0).get("entityId").asText())
                .isEqualTo(ids.get(1));
        assertThat(byTranslation.get("items").get(0).get("sourceText").asText())
                .isEqualTo(sourceToken + "-Bravo");

        assertThat(units(platform, "lang=es&entityType=CATEGORY&query=NoSuchUnitToken")
                .get("total").asInt()).isZero();

        JsonNode first = units(platform,
                "lang=es&entityType=CATEGORY&query=" + sourceToken + "&page=0&size=2");
        JsonNode second = units(platform,
                "lang=es&entityType=CATEGORY&query=" + sourceToken + "&page=1&size=2");
        JsonNode full = units(platform,
                "lang=es&entityType=CATEGORY&query=" + sourceToken + "&page=0&size=50");
        assertThat(first.get("total").asInt()).isEqualTo(3);
        assertThat(first.get("size").asInt()).isEqualTo(2);
        assertThat(first.get("items")).hasSize(2);
        assertThat(second.get("total").asInt()).isEqualTo(3);
        assertThat(second.get("items")).hasSize(1);
        List<String> paged = new ArrayList<>(entityIds(first));
        paged.addAll(entityIds(second));
        assertThat(paged).containsExactlyElementsOf(entityIds(full));
        assertThat(paged).doesNotHaveDuplicates();
        assertThat(entityIds(second)).doesNotContainAnyElementsOf(entityIds(first));

        JsonNode capped = units(platform,
                "lang=es&entityType=CATEGORY&query=" + sourceToken + "&size=999");
        assertThat(capped.get("size").asInt()).isEqualTo(200);
        assertThat(capped.get("total").asInt()).isEqualTo(3);
    }

    @Test
    void languageWithZeroRowsStillListsCanonicalUnits() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        String id = createCategory(platform, "Fresh-" + suffix, "FCAT-" + suffix);

        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM content_translation WHERE lang = 'fr'", Integer.class))
                .isZero();

        JsonNode page = units(platform, "lang=fr&entityType=CATEGORY&query=" + suffix);
        assertThat(page.get("lang").asText()).isEqualTo("fr");
        assertThat(page.get("total").asInt()).isEqualTo(1);
        JsonNode item = page.get("items").get(0);
        assertThat(item.get("entityId").asText()).isEqualTo(id);
        assertThat(item.get("text").isNull()).isTrue();
        assertThat(item.get("status").isNull()).isTrue();
        assertThat(item.get("origin").isNull()).isTrue();
    }

    @Test
    void unitsRejectUnknownEntityTypeCanonicalLanguageAndWorkshopRole() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(get(CONTENT + "/units?lang=es&entityType=NOPE")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ENTITY_TYPE_UNKNOWN"));
        mockMvc.perform(get(CONTENT + "/units?lang=en")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_DEFAULT"));
        mockMvc.perform(get(CONTENT + "/units?lang=zz")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_UNKNOWN"));
        mockMvc.perform(get(CONTENT + "/units")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_UNKNOWN"));
        mockMvc.perform(get(CONTENT + "/units?lang=es&filter=bogus")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("FILTER_INVALID"));

        Login workshopAdmin = login("admin.a@test.local");
        mockMvc.perform(get(CONTENT + "/units?lang=es")
                        .header("Authorization", bearer(workshopAdmin)))
                .andExpect(status().isForbidden());
    }

    @Test
    void unitsReadDoesNotWriteOrEnqueue() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        createCategory(platform, "ReadOnly-" + suffix, "ROCAT-" + suffix);

        int rowsBefore = count("content_translation");
        int jobsBefore = count("content_translation_job");

        units(platform, "lang=es&filter=all&size=200");

        assertThat(count("content_translation")).isEqualTo(rowsBefore);
        assertThat(count("content_translation_job")).isEqualTo(jobsBefore);
    }

    @Test
    void lockedOptionSetsAreExcludedFromUnitsMissingFilterAndCoverage() throws Exception {
        Login platform = login("platform@test.local");
        seedChecklist(platform);

        List<String> lockedSetIds = jdbc.queryForList(
                "SELECT id FROM platform_option_sets WHERE code_locked = TRUE", String.class);
        List<String> catalogueSetIds = jdbc.queryForList(
                "SELECT id FROM platform_option_sets WHERE code_locked = FALSE", String.class);
        assertThat(lockedSetIds).isNotEmpty();
        assertThat(catalogueSetIds).hasSize(7);

        JsonNode setUnits = units(platform, "lang=es&entityType=OPTION_SET&size=200");
        assertThat(setUnits.get("total").asInt()).isEqualTo(catalogueSetIds.size());
        assertThat(entityIds(setUnits)).containsExactlyInAnyOrderElementsOf(catalogueSetIds);
        assertThat(entityIds(setUnits)).doesNotContainAnyElementsOf(lockedSetIds);

        List<String> lockedValueIds = jdbc.queryForList("""
                SELECT v.id FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.code_locked = TRUE
                """, String.class);
        List<String> catalogueValueIds = jdbc.queryForList("""
                SELECT v.id FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.code_locked = FALSE
                """, String.class);
        assertThat(lockedValueIds).isNotEmpty();
        assertThat(catalogueValueIds).isNotEmpty();

        JsonNode valueUnits = units(platform, "lang=es&entityType=OPTION_VALUE&size=200");
        assertThat(valueUnits.get("total").asInt()).isEqualTo(catalogueValueIds.size());
        assertThat(entityIds(valueUnits)).containsExactlyInAnyOrderElementsOf(catalogueValueIds);
        assertThat(entityIds(valueUnits)).doesNotContainAnyElementsOf(lockedValueIds);

        int expectedMissingValues = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.code_locked = FALSE AND v.label IS NOT NULL AND v.label <> ''
                  AND NOT EXISTS (
                      SELECT 1 FROM content_translation ct
                      WHERE ct.entity_type = 'OPTION_VALUE' AND ct.entity_id = v.id
                        AND ct.field_name = 'label' AND ct.lang = 'es'
                        AND ct.body IS NOT NULL AND ct.body <> '')
                """, Integer.class);
        JsonNode missingValues = units(platform,
                "lang=es&entityType=OPTION_VALUE&filter=missing&size=200");
        assertThat(missingValues.get("total").asInt()).isEqualTo(expectedMissingValues);
        assertThat(entityIds(missingValues)).doesNotContainAnyElementsOf(lockedValueIds);

        JsonNode valueCoverage = coverageItem(
                coverage(platform, "lang=es&entityType=OPTION_VALUE"), "OPTION_VALUE", "label");
        assertThat(valueCoverage.get("total").asInt()).isEqualTo(catalogueValueIds.size());
        assertThat(valueCoverage.get("missing").asInt()).isEqualTo(expectedMissingValues);

        JsonNode setCoverage = coverageItem(
                coverage(platform, "lang=es&entityType=OPTION_SET"), "OPTION_SET", "name");
        assertThat(setCoverage.get("total").asInt()).isEqualTo(catalogueSetIds.size());
        assertThat(entityIds(units(platform,
                "lang=es&entityType=OPTION_SET&filter=missing&size=200")))
                .doesNotContainAnyElementsOf(lockedSetIds);
    }

    // ------------------------------------------------------------------ helpers

    private void seedChecklist(Login login) throws Exception {
        mockMvc.perform(post("/api/v1/platform/seed/default-checklist")
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().is2xxSuccessful());
    }

    private JsonNode coverage(Login login, String queryString) throws Exception {
        MvcResult result = mockMvc.perform(get(CONTENT + "/coverage?" + queryString)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
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

    private JsonNode units(Login login, String queryString) throws Exception {
        MvcResult result = mockMvc.perform(get(CONTENT + "/units?" + queryString)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode single(JsonNode page) {
        assertThat(page.get("total").asInt()).isEqualTo(1);
        return page.get("items").get(0);
    }

    private static List<String> entityIds(JsonNode page) {
        List<String> ids = new ArrayList<>();
        page.get("items").forEach(item -> ids.add(item.get("entityId").asText()));
        return ids;
    }

    private int count(String table) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM " + table, Integer.class);
        return count == null ? 0 : count;
    }

    private String createCategory(Login login, String name, String code) throws Exception {
        MvcResult result = mockMvc.perform(org.springframework.test.web.servlet.request
                                .MockMvcRequestBuilders.post(MASTER + "/categories")
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","name":"%s"}
                                """.formatted(code, name)))
                .andExpect(status().isCreated()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("id").asText();
    }

    private org.springframework.test.web.servlet.ResultActions putJson(
            Login login, String path, String body) throws Exception {
        return mockMvc.perform(put(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    private static String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
