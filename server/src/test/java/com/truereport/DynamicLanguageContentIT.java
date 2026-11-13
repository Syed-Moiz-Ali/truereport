package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.uimessages.UiTextTranslationProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = {
        "truereport.i18n.generation.synchronous=true"
})
class DynamicLanguageContentIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @TestConfiguration
    static class TranslationConfig {
        @Bean
        @Primary
        FakeProvider fakeProvider() {
            return new FakeProvider();
        }
    }

    static class FakeProvider implements UiTextTranslationProvider {
        @Override
        public String translate(String text, String targetLanguage) {
            return "[" + targetLanguage + "] " + text;
        }
    }

    @Test
    void addingLanguagesExposesSourceAndTranslationsForEveryContentType() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        createLanguage(platform, "hi", "Hindi");
        createLanguage(platform, "fr", "French");

        JsonNode category = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"CAT-I18N","name":"Engine",
                 "translations":{"name":{"ar":"ar-engine","hi":"hi-engine","fr":"fr-engine"}},
                 "sortOrder":50}
                """);
        String categoryId = category.get("id").asText();
        assertThat(category.get("name").asText()).isEqualTo("Engine");
        assertThat(category.get("translations").get("name").get("hi").asText())
                .isEqualTo("hi-engine");
        assertThat(category.get("translations").get("name").get("fr").asText())
                .isEqualTo("fr-engine");

        JsonNode item = postJson(platform, "/api/v1/platform/master/items", """
                {"stableCode":"I18N-ITEM-01","categoryId":"%s","label":"Check oil",
                 "instruction":"Verify the dipstick","standardSpec":"Above 3 mm","sampleData":false,
                 "translations":{
                   "label":{"hi":"hi-oil","fr":"fr-oil"},
                   "instruction":{"hi":"hi-dipstick","fr":"fr-jauge"}
                 },
                 "resultOptions":["NO_ISSUE_OBSERVED","DEFECT_FOUND"]}
                """.formatted(categoryId));
        String itemId = item.get("item").get("id").asText();
        JsonNode version = item.get("versions").get(0);
        assertThat(version.get("label").asText()).isEqualTo("Check oil");
        assertThat(version.get("translations").get("label").get("hi").asText())
                .isEqualTo("hi-oil");
        assertThat(version.get("translations").get("instruction").get("fr").asText())
                .isEqualTo("fr-jauge");

        JsonNode optionSet = postJson(platform, "/api/v1/platform/master/option-sets", """
                {"code":"I18N-SET","name":"Condition",
                 "translations":{"name":{"hi":"hi-condition","fr":"fr-etat"}}}
                """);
        assertThat(optionSet.get("translations").get("name").get("hi").asText())
                .isEqualTo("hi-condition");
        String setId = optionSet.get("id").asText();
        postJson(platform, "/api/v1/platform/master/option-sets/" + setId + "/values", """
                {"code":"GOOD","label":"Good",
                 "translations":{"label":{"hi":"hi-good","fr":"fr-bon"}}}
                """);

        JsonNode template = postJson(platform, "/api/v1/platform/master/templates", """
                {"code":"I18N-TPL","name":"Inspection",
                 "description":"Full inspection",
                 "translations":{
                   "name":{"hi":"hi-inspection","fr":"fr-inspection"},
                   "description":{"hi":"hi-full","fr":"fr-complete"}
                 }}
                """);
        assertThat(template.get("translations").get("name").get("hi").asText())
                .isEqualTo("hi-inspection");

        JsonNode documentType = postJson(platform, "/api/v1/platform/document-types", """
                {"code":"I18N-DOC","name":"Invoice",
                 "translations":{"name":{"hi":"hi-invoice","fr":"fr-facture"}}}
                """);
        assertThat(documentType.get("translations").get("name").get("fr").asText())
                .isEqualTo("fr-facture");

        String versionId = version.get("id").asText();
        putJson(platform, "/api/v1/platform/master/items/" + itemId + "/versions/"
                + versionId + "/issue-fields", """
                {"fields":[{"fieldCode":"ISSUE_TYPE","label":"Issue type","inputType":"TEXT",
                  "required":true,"sortOrder":1,
                  "translations":{"label":{"hi":"hi-issue","fr":"fr-probleme"}}}]}
                """);
        JsonNode config = getJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/issue-fields");
        assertThat(config.get(0).get("label").asText()).isEqualTo("Issue type");
        assertThat(config.get(0).get("translations").get("label").get("hi").asText())
                .isEqualTo("hi-issue");
    }

    @Test
    void generationProducesDraftTranslationsAndReadinessListsBlockers() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        createLanguage(platform, "hi", "Hindi");

        JsonNode generation = postJson(platform,
                "/api/v1/platform/i18n/languages/hi/content/generate",
                "{\"entityTypes\":[\"CATEGORY\",\"ITEM\"],\"force\":true}");
        assertThat(generation.get("jobStatus").asText()).isEqualTo("COMPLETED");
        assertThat(generation.get("totalKeys").asInt()).isGreaterThan(0);
        assertThat(generation.get("translatedKeys").asInt())
                .isEqualTo(generation.get("totalKeys").asInt());

        JsonNode languages = getJson(platform, "/api/v1/platform/i18n/languages");
        for (JsonNode language : languages) {
            if ("hi".equals(language.get("code").asText())) {
                assertThat(language.get("status").asText()).isEqualTo("TRANSLATING");
            }
        }
        String translatingAudit = jdbc.queryForObject("""
                SELECT after_json FROM platform_audit_events
                WHERE action_code = 'CONTENT_TRANSLATIONS_GENERATED'
                ORDER BY occurred_at DESC LIMIT 1
                """, String.class);
        assertThat(objectMapper.readTree(translatingAudit).get("status").asText())
                .isEqualTo("TRANSLATING");

        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/hi/backlog");
        int drafting = 0;
        for (JsonNode group : backlog.get("groups")) {
            if (!"CATEGORY".equals(group.get("entityType").asText())
                    && !"ITEM".equals(group.get("entityType").asText())) {
                continue;
            }
            for (JsonNode item : group.get("items")) {
                if ("TRANSLATING".equals(item.get("status").asText())) {
                    drafting++;
                    assertThat(item.get("text").asText()).startsWith("[hi] ");
                }
            }
        }
        assertThat(drafting).isGreaterThan(0);

        JsonNode readiness = getJson(platform,
                "/api/v1/platform/i18n/languages/hi/readiness");
        assertThat(readiness.get("language").asText()).isEqualTo("hi");
        assertThat(readiness.get("content").get("CATEGORY").get("total").asInt())
                .isGreaterThan(0);
        assertThat(readiness.get("blockers").size()).isGreaterThan(0);
        assertThat(readiness.get("readinessPercent").asInt()).isLessThan(100);

        mockMvc.perform(post("/api/v1/platform/i18n/languages/hi/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity());
    }

    private void createLanguage(Login login, String code, String nativeName) throws Exception {
        postJson(login, "/api/v1/platform/i18n/languages", """
                {"code":"%s","nativeName":"%s","direction":"ltr","sortOrder":50}
                """.formatted(code, nativeName));
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(post(path)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(put(path)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
