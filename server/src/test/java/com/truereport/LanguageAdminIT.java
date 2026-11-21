package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.shared.i18n.LanguageCatalog;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Platform Admin-managed languages: create/retire lifecycle, runtime catalog
 * registration, and the content units/write contract for an admin-added code.
 */
class LanguageAdminIT extends IntegrationTestBase {

    private static final String PLATFORM = "/api/v1/platform/i18n";
    private static final String CONTENT = PLATFORM + "/content";
    private static final String MASTER = "/api/v1/platform/master";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    LanguageCatalog catalog;

    @AfterEach
    void unregisterTestCodes() {
        // Catalog mutations live outside the test transaction. Leave the shared
        // application context exactly as found so other test classes see the
        // same language set.
        catalog.unregister("de");
        catalog.unregister("zz");
    }

    @Test
    void createsLiveLanguageAndAcceptsContentUnitsAndWrites() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        String name = "Language source " + suffix;
        String categoryId = createCategory(platform, "LANG-CAT-" + suffix, name);

        mockMvc.perform(post(PLATFORM + "/languages")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"DE","nativeName":"Deutsch","direction":"ltr"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("de"))
                .andExpect(jsonPath("$.nativeName").value("Deutsch"))
                .andExpect(jsonPath("$.direction").value("ltr"))
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.isDefault").value(false))
                .andExpect(jsonPath("$.status").value("LIVE"))
                .andExpect(jsonPath("$.sortOrder").isNumber());

        JsonNode listed = findLanguage(getJson(platform, PLATFORM + "/languages"), "de");
        assertThat(listed).isNotNull();
        assertThat(listed.get("status").asText()).isEqualTo("LIVE");
        // en/es/fr are seeded from the manifest (1..3); admin codes append.
        assertThat(listed.get("sortOrder").asInt()).isGreaterThanOrEqualTo(4);

        // Public language selector sees the admin-created language too.
        JsonNode publicLanguages = getJson("/api/v1/i18n/languages");
        assertThat(findLanguage(publicLanguages, "de")).isNotNull();

        // Units accept the runtime-registered code and return canonical text.
        JsonNode units = units(platform, "lang=de&entityType=CATEGORY&query=" + suffix);
        assertThat(units.get("lang").asText()).isEqualTo("de");
        assertThat(units.get("total").asInt()).isEqualTo(1);
        JsonNode unit = units.get("items").get(0);
        assertThat(unit.get("entityId").asText()).isEqualTo(categoryId);
        assertThat(unit.get("sourceText").asText()).isEqualTo(name);
        assertThat(unit.get("text").isNull()).isTrue();

        // Writing a translation for the new language succeeds without a restart.
        putJson(platform, CONTENT + "/CATEGORY/" + categoryId + "/name?lang=de",
                "{\"body\":\"Deutsch-" + suffix + "\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lang").value("de"))
                .andExpect(jsonPath("$.body").value("Deutsch-" + suffix));

        JsonNode translated = units(platform,
                "lang=de&entityType=CATEGORY&filter=all&query=Deutsch-" + suffix);
        assertThat(translated.get("total").asInt()).isEqualTo(1);
        assertThat(translated.get("items").get(0).get("text").asText())
                .isEqualTo("Deutsch-" + suffix);

        mockMvc.perform(get("/api/v1/i18n/me")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk());
    }

    @Test
    void createRejectsDuplicateInvalidDefaultAndWorkshopRoles() throws Exception {
        Login platform = login("platform@test.local");
        createGerman(platform)
                .andExpect(status().isCreated());

        createGerman(platform)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LANGUAGE_EXISTS"));

        mockMvc.perform(post(PLATFORM + "/languages")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"d!\",\"nativeName\":\"Broken\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_INVALID"));

        mockMvc.perform(post(PLATFORM + "/languages")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"toolong\",\"nativeName\":\"Broken\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_INVALID"));

        mockMvc.perform(post(PLATFORM + "/languages")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"EN\",\"nativeName\":\"English\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_DEFAULT"));

        mockMvc.perform(post(PLATFORM + "/languages")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"it\",\"nativeName\":\"Italiano\",\"direction\":\"up\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_INVALID"));

        Login workshopAdmin = login("admin.a@test.local");
        mockMvc.perform(post(PLATFORM + "/languages")
                        .header("Authorization", bearer(workshopAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"it\",\"nativeName\":\"Italiano\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void retireKeepsRowsHidesLanguageAndRecreateReactivates() throws Exception {
        Login platform = login("platform@test.local");
        String suffix = suffix();
        String categoryId = createCategory(platform, "RET-CAT-" + suffix,
                "Retire source " + suffix);
        createGerman(platform).andExpect(status().isCreated());
        putJson(platform, CONTENT + "/CATEGORY/" + categoryId + "/name?lang=de",
                "{\"body\":\"Bleibt-" + suffix + "\"}")
                .andExpect(status().isOk());
        int translationsBefore = count("SELECT COUNT(*) FROM content_translation WHERE lang='de'");
        assertThat(translationsBefore).isPositive();

        mockMvc.perform(delete(PLATFORM + "/languages/de")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("de"))
                .andExpect(jsonPath("$.status").value("RETIRED"))
                .andExpect(jsonPath("$.active").value(false));

        assertThat(findLanguage(getJson(platform, PLATFORM + "/languages"), "de")).isNull();
        mockMvc.perform(get(CONTENT + "/units?lang=de")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_UNKNOWN"));

        // Soft retire: the registry row and every translation row survive.
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_languages WHERE code='de'", Integer.class))
                .isEqualTo(1);
        assertThat(jdbc.queryForObject(
                "SELECT status FROM platform_languages WHERE code='de'", String.class))
                .isEqualTo("RETIRED");
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM content_translation WHERE lang='de'", Integer.class))
                .isEqualTo(translationsBefore);

        // Re-posting the same code reactivates the row with the new metadata.
        createGerman(platform, "Deutsch neu")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("de"))
                .andExpect(jsonPath("$.nativeName").value("Deutsch neu"))
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.status").value("LIVE"));

        units(platform, "lang=de&entityType=CATEGORY&query=" + suffix);
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM content_translation WHERE lang='de'", Integer.class))
                .isEqualTo(translationsBefore);
    }

    @Test
    void retireRejectsDefaultAndUnknownCodes() throws Exception {
        Login platform = login("platform@test.local");

        mockMvc.perform(delete(PLATFORM + "/languages/en")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("LANGUAGE_DEFAULT"));

        mockMvc.perform(delete(PLATFORM + "/languages/zz")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isNotFound());

        Login workshopAdmin = login("admin.a@test.local");
        mockMvc.perform(delete(PLATFORM + "/languages/de")
                        .header("Authorization", bearer(workshopAdmin)))
                .andExpect(status().isForbidden());
    }

    // ------------------------------------------------------------------ helpers

    private org.springframework.test.web.servlet.ResultActions createGerman(Login login)
            throws Exception {
        return createGerman(login, "Deutsch");
    }

    private org.springframework.test.web.servlet.ResultActions createGerman(Login login,
                                                                           String nativeName)
            throws Exception {
        return mockMvc.perform(post(PLATFORM + "/languages")
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"de\",\"nativeName\":\"" + nativeName + "\"}"));
    }

    private JsonNode units(Login login, String queryString) throws Exception {
        return getJson(login, CONTENT + "/units?" + queryString);
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private org.springframework.test.web.servlet.ResultActions putJson(
            Login login, String path, String body) throws Exception {
        return mockMvc.perform(put(path)
                .header("Authorization", bearer(login))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private String createCategory(Login login, String code, String name) throws Exception {
        MvcResult result = mockMvc.perform(post(MASTER + "/categories")
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","name":"%s"}
                                """.formatted(code, name)))
                .andExpect(status().isCreated()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("id").asText();
    }

    private int count(String sql) {
        Integer value = jdbc.queryForObject(sql, Integer.class);
        return value == null ? 0 : value;
    }

    private static JsonNode findLanguage(JsonNode array, String code) {
        for (JsonNode language : array) {
            if (code.equals(language.get("code").asText())) {
                return language;
            }
        }
        return null;
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    private static String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
