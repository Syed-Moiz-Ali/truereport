package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformTemplateCategoryIT extends IntegrationTestBase {

    @Test
    void templateVersionGroupsItemsByOrderedCategory() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode categories = getJson(platform, "/api/v1/platform/master/categories");
        String first = categories.get(0).get("id").asText();
        String second = categories.get(1).get("id").asText();

        JsonNode firstItems = getJson(platform,
                "/api/v1/platform/master/items?categoryId=" + first);
        JsonNode secondItems = getJson(platform,
                "/api/v1/platform/master/items?categoryId=" + second);
        String firstItem = firstItems.get(0).get("id").asText();
        String secondItem = secondItems.get(0).get("id").asText();
        String firstVersion = versionId(platform, firstItem);
        String secondVersion = versionId(platform, secondItem);

        JsonNode template = postJson(platform, "/api/v1/platform/master/templates", """
                {"code":"TPL-GROUP-01","nameEn":"Grouped template","nameAr":"قالب مجمع",
                 "descriptionEn":"Grouped","descriptionAr":"مجمع"}
                """);
        String templateId = template.get("id").asText();
        String versionId = template.get("versions").get(0).get("id").asText();

        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + versionId + "/categories", """
                {"categories":[
                  {"categoryId":"%s","included":true,"sortOrder":2},
                  {"categoryId":"%s","included":true,"sortOrder":1}
                ]}
                """.formatted(first, second));

        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + versionId + "/items", """
                {"items":[
                  {"categoryId":"%s","itemVersionId":"%s","included":true,"sortOrder":1},
                  {"categoryId":"%s","itemVersionId":"%s","included":true,"sortOrder":1}
                ]}
                """.formatted(second, secondVersion, first, firstVersion));

        JsonNode detail = getJson(platform, "/api/v1/platform/master/templates/" + templateId);
        JsonNode grouped = detail.get("categories");
        assertThat(grouped.size()).isEqualTo(2);
        assertThat(grouped.get(0).get("categoryId").asText()).isEqualTo(second);
        assertThat(grouped.get(0).get("items").get(0).get("categoryId").asText())
                .isEqualTo(second);
        assertThat(grouped.get(1).get("categoryId").asText()).isEqualTo(first);
        assertThat(grouped.get(0).get("includedCount").asInt()
                + grouped.get(1).get("includedCount").asInt()).isEqualTo(2);

        mockMvc.perform(put("/api/v1/platform/master/templates/" + templateId
                                + "/versions/" + versionId + "/items")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"items":[{"categoryId":"%s","itemVersionId":"%s","included":true,"sortOrder":1}]}
                                """.formatted(first, secondVersion)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ITEM_CATEGORY_MISMATCH"));

        mockMvc.perform(get("/api/v1/platform/master/templates/" + templateId
                                + "/versions/" + versionId + "/weight-preview")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isNotFound());
    }

    @Test
    void emptyCategoriesAreExcludedAfterItemsAreSaved() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode categories = getJson(platform, "/api/v1/platform/master/categories");
        String first = categories.get(0).get("id").asText();
        String second = categories.get(1).get("id").asText();
        JsonNode firstItems = getJson(platform,
                "/api/v1/platform/master/items?categoryId=" + first);
        String firstVersion = versionId(platform,
                firstItems.get(0).get("id").asText());

        JsonNode template = postJson(platform, "/api/v1/platform/master/templates", """
                {"code":"TPL-EMPTY-01","nameEn":"Empty category template","nameAr":"قالب فارغ",
                 "descriptionEn":"Empty","descriptionAr":"فارغ"}
                """);
        String templateId = template.get("id").asText();
        String versionId = template.get("versions").get(0).get("id").asText();

        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + versionId + "/categories", """
                {"categories":[
                  {"categoryId":"%s","included":true,"sortOrder":1},
                  {"categoryId":"%s","included":true,"sortOrder":2}
                ]}
                """.formatted(first, second));

        putJson(platform, "/api/v1/platform/master/templates/" + templateId
                + "/versions/" + versionId + "/items", """
                {"items":[{"categoryId":"%s","itemVersionId":"%s","included":true,"sortOrder":1}]}
                """.formatted(first, firstVersion));

        JsonNode detail = getJson(platform, "/api/v1/platform/master/templates/" + templateId);
        JsonNode grouped = detail.get("categories");
        assertThat(grouped.size()).isEqualTo(1);
        assertThat(grouped.get(0).get("categoryId").asText()).isEqualTo(first);
    }

    private String versionId(Login login, String itemId) throws Exception {
        JsonNode detail = getJson(login, "/api/v1/platform/master/items/" + itemId);
        return detail.get("versions").get(0).get("id").asText();
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
