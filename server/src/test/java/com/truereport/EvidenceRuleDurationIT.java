package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class EvidenceRuleDurationIT extends IntegrationTestBase {

    @Test
    void durationsRoundTripAndValidationHolds() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode category = postJson(platform, "/api/v1/platform/master/categories", """
                {"code":"EVID-DUR-CAT","name":"Duration category"}
                """);
        JsonNode item = postJson(platform, "/api/v1/platform/master/items", """
                {"stableCode":"EVID-DUR-1","categoryId":"%s",
                 "label":"Duration item","instruction":"Inspect the item",
                 "sampleData":false,
                 "resultOptions":["NO_ISSUE_OBSERVED","DEFECT_FOUND"]}
                """.formatted(category.get("id").asText()));
        String itemId = item.get("item").get("id").asText();
        String versionId = item.get("versions").get(0).get("id").asText();
        String rulesPath = "/api/v1/platform/master/items/" + itemId + "/versions/"
                + versionId + "/evidence-rules";

        JsonNode saved = putJson(platform, rulesPath, """
                {"rules":[{"resultCode":"DEFECT_FOUND","minPhotos":2,"minVideos":1,
                  "minNotesChars":15,"requiredEvidenceType":"VIDEO",
                  "minDurationSeconds":15,"maxDurationSeconds":30}]}
                """);
        assertThat(saved.get(0).get("minDurationSeconds").asInt()).isEqualTo(15);
        assertThat(saved.get(0).get("maxDurationSeconds").asInt()).isEqualTo(30);

        JsonNode fetched = getJson(platform, rulesPath);
        assertThat(fetched.get(0).get("minDurationSeconds").asInt()).isEqualTo(15);
        assertThat(fetched.get(0).get("maxDurationSeconds").asInt()).isEqualTo(30);

        // null means "no duration constraint".
        JsonNode unconstrained = putJson(platform, rulesPath, """
                {"rules":[{"resultCode":"DEFECT_FOUND","minPhotos":2,"minVideos":1,
                  "minNotesChars":15,"requiredEvidenceType":"VIDEO",
                  "minDurationSeconds":null,"maxDurationSeconds":null}]}
                """);
        assertThat(unconstrained.get(0).has("minDurationSeconds")).isFalse();
        assertThat(unconstrained.get(0).has("maxDurationSeconds")).isFalse();

        var invalidResponse = mockMvc.perform(put(rulesPath)
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"rules":[{"resultCode":"DEFECT_FOUND","minPhotos":2,
                                  "minVideos":1,"minNotesChars":15,
                                  "requiredEvidenceType":"VIDEO",
                                  "minDurationSeconds":30,"maxDurationSeconds":15}]}
                                """))
                .andExpect(status().isUnprocessableEntity())
                .andReturn();
        JsonNode invalid = objectMapper.readTree(
                invalidResponse.getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(invalid.get("code").asText()).isEqualTo("EVIDENCE_RULES_INVALID");
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }
}
