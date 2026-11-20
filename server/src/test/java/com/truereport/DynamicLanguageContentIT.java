package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.localization.DynamicContentTranslations;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@org.junit.jupiter.api.Disabled("English-only product: bilingual overlays are removed")
class DynamicLanguageContentIT extends IntegrationTestBase {

    @Autowired
    DynamicContentTranslations translations;

    @Test
    void seededContentExposesTranslationsForEveryContentType() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode category = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"CAT-I18N","name":"Engine",
                 "translations":{"name":{"ar":"ar-engine"}},
                 "sortOrder":50}
                """);
        String categoryId = category.get("id").asText();
        assertThat(category.get("name").asText()).isEqualTo("Engine");
        assertThat(category.get("translations").get("name").get("ar").asText())
                .isEqualTo("ar-engine");

        JsonNode item = postJson(platform, "/api/v1/platform/master/items", """
                {"stableCode":"I18N-ITEM-01","categoryId":"%s","label":"Check oil",
                 "instruction":"Verify the dipstick","standardSpec":"Above 3 mm","sampleData":false,
                 "translations":{"label":{"ar":"ar-oil"},"instruction":{"ar":"ar-dipstick"}},
                 "resultOptions":["NO_ISSUE_OBSERVED","DEFECT_FOUND"]}
                """.formatted(categoryId));
        String itemId = item.get("item").get("id").asText();
        JsonNode version = item.get("versions").get(0);
        assertThat(version.get("label").asText()).isEqualTo("Check oil");
        assertThat(version.get("translations").get("label").get("ar").asText())
                .isEqualTo("ar-oil");
        assertThat(version.get("translations").get("instruction").get("ar").asText())
                .isEqualTo("ar-dipstick");

        JsonNode optionSet = postJson(platform, "/api/v1/platform/master/option-sets", """
                {"code":"I18N-SET","name":"Condition",
                 "translations":{"name":{"ar":"ar-condition"}}}
                """);
        assertThat(optionSet.get("translations").get("name").get("ar").asText())
                .isEqualTo("ar-condition");
        String setId = optionSet.get("id").asText();
        postJson(platform, "/api/v1/platform/master/option-sets/" + setId + "/values", """
                {"code":"GOOD","label":"Good",
                 "translations":{"label":{"ar":"ar-good"}}}
                """);

        JsonNode template = postJson(platform, "/api/v1/platform/master/templates", """
                {"code":"I18N-TPL","name":"Inspection",
                 "description":"Full inspection",
                 "translations":{"name":{"ar":"ar-inspection"},"description":{"ar":"ar-full"}}}
                """);
        assertThat(template.get("translations").get("name").get("ar").asText())
                .isEqualTo("ar-inspection");

        JsonNode documentType = postJson(platform, "/api/v1/platform/document-types", """
                {"code":"I18N-DOC","name":"Invoice",
                 "translations":{"name":{"ar":"ar-invoice"}}}
                """);
        assertThat(documentType.get("translations").get("name").get("ar").asText())
                .isEqualTo("ar-invoice");

        String versionId = version.get("id").asText();
        putJson(platform, "/api/v1/platform/master/items/" + itemId + "/versions/"
                + versionId + "/issue-fields", """
                {"fields":[{"fieldCode":"ISSUE_TYPE","label":"Issue type","inputType":"TEXT",
                  "required":true,"sortOrder":1,
                  "translations":{"label":{"ar":"ar-issue"}}}]}
                """);
        JsonNode config = getJson(platform, "/api/v1/platform/master/items/" + itemId
                + "/versions/" + versionId + "/issue-fields");
        assertThat(config.get(0).get("label").asText()).isEqualTo("Issue type");
        assertThat(config.get(0).get("translations").get("label").get("ar").asText())
                .isEqualTo("ar-issue");
    }

    @Test
    void manualQueueStoresDraftsAndMissingTranslationsFallBackToEnglish() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        JsonNode created = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"MANUAL-CAT","name":"Manual category","sortOrder":1}
                """);
        String createdCategoryId = created.get("id").asText();

        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/ar/backlog");
        assertThat(backlog.get("totalRequired").asInt()).isGreaterThan(0);
        JsonNode first = null;
        for (JsonNode group : backlog.get("groups")) {
            for (JsonNode entry : group.get("items")) {
                if (createdCategoryId.equals(entry.get("entityId").asText())
                        && "CATEGORY".equals(entry.get("entityType").asText())
                        && !entry.hasNonNull("text")) {
                    first = entry;
                    break;
                }
            }
            if (first != null) {
                break;
            }
        }
        assertThat(first).isNotNull();
        String entityId = first.get("entityId").asText();
        String field = first.get("field").asText();
        String english = first.get("defaultText").asText();
        assertThat(english).isNotBlank();

        // Missing overlay resolves to the English source.
        assertThat(translations.resolve("CATEGORY", entityId, field, "ar", english))
                .isEqualTo(english);

        JsonNode saved = putJson(platform, "/api/v1/platform/i18n/translations", """
                {"entityType":"CATEGORY","entityId":"%s","field":"%s","language":"ar",
                 "text":"manual-ar","status":"DRAFT"}
                """.formatted(entityId, field));
        assertThat(saved.get("text").asText()).isEqualTo("manual-ar");
        assertThat(saved.get("status").asText()).isEqualTo("DRAFT");

        JsonNode updated = getJson(platform,
                "/api/v1/platform/i18n/languages/ar/backlog");
        boolean found = false;
        for (JsonNode group : updated.get("groups")) {
            for (JsonNode entry : group.get("items")) {
                if (entityId.equals(entry.get("entityId").asText())
                        && field.equals(entry.get("field").asText())) {
                    found = true;
                    assertThat(entry.get("text").asText()).isEqualTo("manual-ar");
                    assertThat(entry.get("status").asText()).isEqualTo("DRAFT");
                }
            }
        }
        assertThat(found).isTrue();

        JsonNode coverage = getJson(platform,
                "/api/v1/platform/i18n/coverage?language=ar");
        assertThat(coverage.get("totalRequired").asInt()).isGreaterThan(0);

        JsonNode readiness = getJson(platform,
                "/api/v1/platform/i18n/languages/ar/readiness");
        assertThat(readiness.get("language").asText()).isEqualTo("ar");
        assertThat(readiness.get("content").get("CATEGORY").get("total").asInt())
                .isGreaterThan(0);
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
