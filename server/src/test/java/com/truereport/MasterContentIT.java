package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MasterContentIT extends IntegrationTestBase {

    @Test
    void publishingCreatesVersionsAndRetiringLeavesOldVersionsUnchanged() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode category = postJson(platform, "/api/v1/platform/master/categories", """
                {"slug":"sample-exterior","labelEn":"Sample exterior","labelAr":"هيكل تجريبي","sortOrder":1}
                """);
        String categoryId = category.get("id").asText();

        JsonNode equipment = postJson(platform, "/api/v1/platform/master/equipment", """
                {"code":"FLASHLIGHT","labelEn":"Flashlight","labelAr":"مصباح يدوي","sortOrder":1}
                """);
        JsonNode reason = postJson(platform, "/api/v1/platform/master/reasons", """
                {"code":"NOT_ACCESSIBLE","labelEn":"Not accessible","labelAr":"غير متاح","sortOrder":1}
                """);

        JsonNode item = postJson(platform, "/api/v1/platform/master/items", """
                {"stableCode":"SAMPLE-EXT-001","categoryId":"%s",
                 "labelEn":"Sample body panel check","labelAr":"فحص لوحة الهيكل التجريبي",
                 "instructionEn":"Inspect the panel and record any defect.",
                 "instructionAr":"افحص اللوحة وسجل أي عيب.",
                 "sampleData":true,
                 "resultOptions":["NO_ISSUE_OBSERVED","DEFECT_FOUND","NOT_CHECKED"],
                 "severityPolicy":"{\\"DEFECT_FOUND\\":\\"MODERATE\\"}",
                 "applicability":"{}",
                 "reasonCodes":["%s"],
                 "noteRequirement":"OPTIONAL",
                 "evidenceRequirement":"OPTIONAL",
                 "minPhotos":0,
                 "equipmentIds":["%s"],
                 "guideImageId":null}
                """.formatted(categoryId, reason.get("code").asText(), equipment.get("id").asText()));

        String itemId = item.get("item").get("id").asText();
        String v1Id = item.get("versions").get(0).get("id").asText();
        assertThat(item.get("item").get("sampleData").asBoolean()).isTrue();

        mockMvc.perform(post("/api/v1/platform/master/items/" + itemId + "/versions/" + v1Id + "/publish")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PUBLISHED"));

        mockMvc.perform(post("/api/v1/platform/master/items/" + itemId + "/versions")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.versions.length()").value(2));

        JsonNode detail = getJson(platform, "/api/v1/platform/master/items/" + itemId);
        String v2Id = detail.get("versions").get(0).get("id").asText();

        mockMvc.perform(put("/api/v1/platform/master/items/" + itemId + "/versions/" + v2Id
                                + "/translations/en")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"label":"Updated body panel check","instruction":"Updated instruction."}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.label").value("Updated body panel check"));

        mockMvc.perform(put("/api/v1/platform/master/items/" + itemId + "/versions/" + v2Id
                                + "/translations/ar")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"label":"فحص لوحة الجسم","instruction":"تعليمات محدثة."}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/v1/platform/master/items/" + itemId + "/metadata")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"standardSpecEn":"Updated spec","standardSpecAr":"المواصفات المحدثة"}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/platform/master/items/" + itemId + "/versions/" + v2Id + "/publish")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PUBLISHED"));

        JsonNode versions = getJson(platform, "/api/v1/platform/master/items/" + itemId + "/versions");
        JsonNode v1 = findVersion(versions, 1);
        JsonNode v2 = findVersion(versions, 2);
        assertThat(v1.get("translations").get("label").get("en").asText())
                .isEqualTo("Sample body panel check");
        assertThat(v2.get("translations").get("label").get("en").asText())
                .isEqualTo("Updated body panel check");

        mockMvc.perform(post("/api/v1/platform/master/items/" + itemId + "/retire")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RETIRED"));

        JsonNode retired = getJson(platform, "/api/v1/platform/master/items/" + itemId);
        assertThat(retired.get("item").get("status").asText()).isEqualTo("RETIRED");
        assertThat(retired.get("versions").size()).isEqualTo(2);
        assertThat(findVersion(retired.get("versions"), 1).get("translations").get("label").get("en").asText())
                .isEqualTo("Sample body panel check");

        JsonNode audit = getJson(platform, "/api/v1/platform/audit-events");
        assertThat(audit.toString()).contains("MASTER_ITEM_PUBLISHED");
        assertThat(audit.toString()).contains("MASTER_ITEM_RETIRED");
    }

    @Test
    void guideImageUploadAndContentAreSeparateFromEvidence() throws Exception {
        Login platform = login("platform@test.local");
        byte[] png = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        MockMultipartFile file = new MockMultipartFile("file", "guide.png", "image/png", png);

        var result = mockMvc.perform(multipart("/api/v1/platform/master/guide-images")
                        .file(file)
                        .param("altEn", "Guide image showing the panel")
                        .param("altAr", "صورة إرشادية توضح اللوحة")
                        .param("licenceNote", "Original placeholder")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.altEn").value("Guide image showing the panel"))
                .andReturn();
        JsonNode image = objectMapper.readTree(result.getResponse().getContentAsString());
        String id = image.get("id").asText();

        var content = mockMvc.perform(get("/api/v1/platform/master/guide-images/" + id + "/content")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        assertThat(content.getResponse().getContentAsByteArray()).isEqualTo(png);
    }

    @Test
    void technicianAndWorkshopAdminCannotMutateMasterContent() throws Exception {
        Login technician = login("tech.a@test.local");
        Login workshopAdmin = login("admin.a@test.local");
        UUID random = UUID.randomUUID();
        String[] writeEndpoints = {
                "/api/v1/platform/master/categories",
                "/api/v1/platform/master/items",
                "/api/v1/platform/master/reasons",
                "/api/v1/platform/master/equipment",
                "/api/v1/platform/master/dropdowns",
                "/api/v1/platform/master/items/" + random + "/versions/" + random + "/publish",
                "/api/v1/platform/master/items/" + random + "/retire",
                "/api/v1/platform/master/guide-images/" + random + "/retire"
        };
        for (String endpoint : writeEndpoints) {
            mockMvc.perform(post(endpoint)
                            .header("Authorization", "Bearer " + technician.accessToken())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isForbidden());
            mockMvc.perform(post(endpoint)
                            .header("Authorization", "Bearer " + workshopAdmin.accessToken())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isForbidden());
        }
        String[] updateEndpoints = {
                "/api/v1/platform/master/categories/" + random,
                "/api/v1/platform/master/items/" + random + "/versions/" + random + "/translations/en",
                "/api/v1/platform/master/items/" + random + "/versions/" + random + "/rules"
        };
        for (String endpoint : updateEndpoints) {
            mockMvc.perform(put(endpoint)
                            .header("Authorization", "Bearer " + technician.accessToken())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isForbidden());
            mockMvc.perform(put(endpoint)
                            .header("Authorization", "Bearer " + workshopAdmin.accessToken())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isForbidden());
        }
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode findVersion(JsonNode versions, int versionNo) {
        for (JsonNode version : versions) {
            if (version.get("versionNo").asInt() == versionNo) {
                return version;
            }
        }
        throw new AssertionError("Version not found: " + versionNo);
    }
}
