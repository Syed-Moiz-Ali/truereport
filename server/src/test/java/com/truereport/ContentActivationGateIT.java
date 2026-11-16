package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.localization.TranslationGate;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.templates.config.PlatformTemplateService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ContentActivationGateIT extends IntegrationTestBase {

    private static final String LANGUAGE = "ar";

    @Autowired
    TranslationGate translationGate;

    @Autowired
    PlatformTemplateService templateService;

    @Test
    void pendingActivationContentIsTranslatableAndActivatable() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        approveReadinessItems(platform, LANGUAGE);
        assertThat(translationGate.liveExtendedLanguages()).contains(LANGUAGE);

        JsonNode category = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"GATE-CAT","name":"Gate category","sortOrder":1}
                """);
        assertThat(category.get("status").asText()).isEqualTo("DRAFT");
        String categoryId = category.get("id").asText();
        assertPending(platform, LANGUAGE, "CATEGORY", categoryId);
        approveAll(platform, LANGUAGE, "CATEGORY");
        activateCategory(platform, categoryId).andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        JsonNode optionSet = postJson(platform, "/api/v1/platform/master/option-sets", """
                {"code":"GATE-SET","name":"Gate set"}
                """);
        assertThat(optionSet.get("status").asText()).isEqualTo("DRAFT");
        String setId = optionSet.get("id").asText();
        assertThat(translationGate.overlaysApproved("OPTION_SET", setId)).isFalse();
        assertPending(platform, LANGUAGE, "OPTION_SET", setId);
        approveAll(platform, LANGUAGE, "OPTION_SET");
        mockMvc.perform(put("/api/v1/platform/master/option-sets/" + setId)
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"ACTIVE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        JsonNode value = postJson(platform,
                "/api/v1/platform/master/option-sets/" + setId + "/values", """
                {"code":"GOOD","label":"Good"}
                """);
        assertThat(value.get("status").asText()).isEqualTo("DRAFT");
        String valueId = value.get("id").asText();
        assertPending(platform, LANGUAGE, "OPTION_VALUE", valueId);
        approveAll(platform, LANGUAGE, "OPTION_VALUE");
        mockMvc.perform(put("/api/v1/platform/master/option-sets/" + setId
                                + "/values/" + valueId)
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"label\":\"Good\",\"status\":\"ACTIVE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        JsonNode documentType = postJson(platform, "/api/v1/platform/document-types", """
                {"code":"GATE-DOC","name":"Gate document"}
                """);
        assertThat(documentType.get("status").asText()).isEqualTo("DRAFT");
        String documentTypeId = documentType.get("id").asText();
        assertPending(platform, LANGUAGE, "DOCUMENT_TYPE", documentTypeId);
        approveAll(platform, LANGUAGE, "DOCUMENT_TYPE");
        mockMvc.perform(put("/api/v1/platform/document-types/" + documentTypeId)
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Gate document\",\"active\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        JsonNode item = postJson(platform, "/api/v1/platform/master/items", """
                {"stableCode":"GATE-ITEM","categoryId":"%s","label":"Gate item",
                 "instruction":"Inspect gate","standardSpec":"Above 3 mm",
                 "sampleData":false,
                 "resultOptions":["NO_ISSUE_OBSERVED","DEFECT_FOUND"]}
                """.formatted(categoryId));
        String itemId = item.get("item").get("id").asText();
        String versionId = item.get("versions").get(0).get("id").asText();
        putJson(platform, "/api/v1/platform/master/items/" + itemId + "/versions/"
                + versionId + "/issue-fields", """
                {"fields":[{"fieldCode":"ISSUE_TYPE","label":"Issue type",
                  "inputType":"TEXT","required":true,"sortOrder":1}]}
                """);
        approveAll(platform, LANGUAGE, "ITEM");
        approveAll(platform, LANGUAGE, "ISSUE_FIELD");
        mockMvc.perform(post("/api/v1/platform/master/items/" + itemId
                                + "/versions/" + versionId + "/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PUBLISHED"));
    }

    @Test
    void readinessExcludesDraftContent() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        approveReadinessItems(platform, LANGUAGE);

        int before = coverageTotal(platform, LANGUAGE);
        JsonNode draft = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"PENDING-CAT","name":"Pending category","sortOrder":1}
                """);
        assertThat(draft.get("status").asText()).isEqualTo("DRAFT");
        int after = coverageTotal(platform, LANGUAGE);
        assertThat(after).isEqualTo(before);

        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/" + LANGUAGE + "/backlog");
        boolean pendingVisible = false;
        for (JsonNode group : backlog.get("groups")) {
            for (JsonNode entry : group.get("items")) {
                if ("PENDING-CAT".equals(entry.get("entityCode").asText())) {
                    pendingVisible = true;
                    assertThat(entry.get("contentStatus").asText()).isEqualTo("DRAFT");
                }
            }
        }
        assertThat(pendingVisible).isTrue();

        JsonNode categories = getJson(platform, "/api/v1/platform/master/categories");
        JsonNode pending = null;
        for (JsonNode entry : categories) {
            if ("PENDING-CAT".equals(entry.get("code").asText())) {
                pending = entry;
            }
        }
        assertThat(pending).isNotNull();
        assertThat(pending.get("status").asText()).isEqualTo("DRAFT");

        approveAll(platform, LANGUAGE, "CATEGORY");
        activateCategory(platform, pending.get("id").asText())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    @Test
    void unpublishedTemplatesStayTranslatableButDoNotCountForReadiness() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        approveReadinessItems(platform, LANGUAGE);

        JsonNode template = postJson(platform, "/api/v1/platform/master/templates", """
                {"code":"PENDING-TPL","name":"Pending template",
                 "description":"Draft only"}
                """);
        String templateId = template.get("id").asText();
        String versionId = template.get("versions").get(0).get("id").asText();

        JsonNode unpublishedTranslation = putJson(platform,
                "/api/v1/platform/i18n/translations", """
                {"entityType":"TEMPLATE","entityId":"%s","field":"name","language":"ar",
                 "text":"ar-template","status":"DRAFT"}
                """.formatted(templateId));
        assertThat(unpublishedTranslation.get("contentStatus").asText())
                .isEqualTo("DRAFT");

        int readinessBefore = coverageTotal(platform, LANGUAGE);
        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/" + LANGUAGE + "/backlog");
        boolean templateVisible = false;
        for (JsonNode group : backlog.get("groups")) {
            if (!"TEMPLATE".equals(group.get("entityType").asText())) {
                continue;
            }
            for (JsonNode entry : group.get("items")) {
                if (!templateId.equals(entry.get("entityId").asText())) {
                    continue;
                }
                templateVisible = true;
                assertThat(entry.get("contentStatus").asText()).isEqualTo("DRAFT");
            }
        }
        assertThat(templateVisible).isTrue();
        assertThat(coverageTotal(platform, LANGUAGE)).isEqualTo(readinessBefore);

        JsonNode categories = getJson(platform, "/api/v1/platform/master/categories");
        String categoryId = categories.get(0).get("id").asText();
        JsonNode items = getJson(platform,
                "/api/v1/platform/master/items?categoryId=" + categoryId);
        String itemId = items.get(0).get("id").asText();
        JsonNode detail = getJson(platform, "/api/v1/platform/master/items/" + itemId);
        String itemVersionId = detail.get("versions").get(0).get("id").asText();

        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + versionId + "/categories", """
                {"categories":[{"categoryId":"%s","included":true,"sortOrder":1}]}
                """.formatted(categoryId));
        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + versionId + "/items", """
                {"items":[{"categoryId":"%s","itemVersionId":"%s",
                  "included":true,"sortOrder":1}]}
                """.formatted(categoryId, itemVersionId));

        CurrentUser first = new CurrentUser(fixture.platform().getId(),
                fixture.platform().getEmail(), "PLATFORM_ADMIN", null, null);
        CurrentUser second = new CurrentUser(UUID.randomUUID(),
                "platform.second@test.local", "PLATFORM_ADMIN", null, null);

        assertThatThrownBy(() -> templateService.publish(first, templateId, versionId))
                .isInstanceOf(ApiException.class)
                .satisfies(error -> assertThat(((ApiException) error).code())
                        .isEqualTo("TRANSLATION_REQUIRED"));

        approve(platform, "TEMPLATE", templateId, "name", "ar-template");
        approve(platform, "TEMPLATE", templateId, "description", "ar-description");

        templateService.publish(first, templateId, versionId);
        templateService.approve(second, templateId, versionId);
        int readinessAfterPublish = coverageTotal(platform, LANGUAGE);
        assertThat(readinessAfterPublish).isGreaterThan(readinessBefore);

        JsonNode published = getJson(platform,
                "/api/v1/platform/master/templates/" + templateId);
        assertThat(published.get("versions").get(0).get("status").asText())
                .isEqualTo("PUBLISHED");

        JsonNode publishedTranslation = putJson(platform,
                "/api/v1/platform/i18n/translations", """
                {"entityType":"TEMPLATE","entityId":"%s","field":"name","language":"ar",
                 "text":"ar-template","status":"APPROVED"}
                """.formatted(templateId));
        assertThat(publishedTranslation.get("contentStatus").asText())
                .isEqualTo("ACTIVE");
        JsonNode publishedBacklog = getJson(platform,
                "/api/v1/platform/i18n/languages/" + LANGUAGE + "/backlog");
        boolean publishedRowMatched = false;
        for (JsonNode group : publishedBacklog.get("groups")) {
            for (JsonNode entry : group.get("items")) {
                if ("TEMPLATE".equals(entry.get("entityType").asText())
                        && templateId.equals(entry.get("entityId").asText())) {
                    publishedRowMatched = true;
                    assertThat(entry.get("contentStatus").asText()).isEqualTo("ACTIVE");
                }
            }
        }
        assertThat(publishedRowMatched).isTrue();

        JsonNode readiness = getJson(platform,
                "/api/v1/platform/i18n/languages/" + LANGUAGE + "/readiness");
        assertThat(readiness.get("content").get("TEMPLATE").get("total").asInt())
                .isGreaterThan(0);
    }

    private void assertPending(Login platform, String language, String entityType,
                               String entityId) throws Exception {
        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/" + language + "/backlog");
        for (JsonNode group : backlog.get("groups")) {
            if (!entityType.equals(group.get("entityType").asText())) {
                continue;
            }
            for (JsonNode entry : group.get("items")) {
                if (entityId.equals(entry.get("entityId").asText())) {
                    assertThat(entry.get("contentStatus").asText()).isEqualTo("DRAFT");
                    return;
                }
            }
        }
        throw new AssertionError("Pending content not found in backlog: " + entityType);
    }

    private void approveReadinessItems(Login platform, String code) throws Exception {
        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/" + code + "/backlog");
        for (JsonNode group : backlog.get("groups")) {
            for (JsonNode entry : group.get("items")) {
                if (!isReadinessVisible(entry.get("contentStatus").asText())) {
                    continue;
                }
                if ("APPROVED".equals(entry.get("status").asText())) {
                    continue;
                }
                approveEntry(platform, code, entry);
            }
        }
    }

    private void approveAll(Login platform, String code, String entityType) throws Exception {
        JsonNode backlog = getJson(platform,
                "/api/v1/platform/i18n/languages/" + code + "/backlog");
        for (JsonNode group : backlog.get("groups")) {
            if (!entityType.equals(group.get("entityType").asText())) {
                continue;
            }
            for (JsonNode entry : group.get("items")) {
                if (!"APPROVED".equals(entry.get("status").asText())) {
                    approveEntry(platform, code, entry);
                }
            }
        }
    }

    private void approve(Login platform, String entityType, String entityId,
                         String field, String text) throws Exception {
        putJson(platform, "/api/v1/platform/i18n/translations", """
                {"entityType":"%s","entityId":"%s","field":"%s","language":"ar",
                 "text":"%s","status":"APPROVED"}
                """.formatted(entityType, entityId, field,
                text.replace("\"", "\\\"")));
    }

    private void approveEntry(Login platform, String code, JsonNode entry) throws Exception {
        String text = entry.hasNonNull("text") && !entry.get("text").asText().isBlank()
                ? entry.get("text").asText()
                : "[" + code + "] " + entry.get("defaultText").asText();
        putJson(platform, "/api/v1/platform/i18n/translations", """
                {"entityType":"%s","entityId":"%s","field":"%s","language":"%s",
                 "text":"%s","status":"APPROVED"}
                """.formatted(entry.get("entityType").asText(),
                entry.get("entityId").asText(), entry.get("field").asText(), code,
                text.replace("\"", "\\\"")));
    }

    private int coverageTotal(Login platform, String code) throws Exception {
        return getJson(platform, "/api/v1/platform/i18n/coverage?language=" + code)
                .get("totalRequired").asInt();
    }

    private boolean isReadinessVisible(String status) {
        return "ACTIVE".equals(status) || "PUBLISHED".equals(status);
    }

    private org.springframework.test.web.servlet.ResultActions activateCategory(
            Login platform, String id) throws Exception {
        return mockMvc.perform(put("/api/v1/platform/master/categories/" + id)
                .header("Authorization", bearer(platform))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"ACTIVE\"}"));
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
