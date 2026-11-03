package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.inspections.InspectionFinalSnapshotRepository;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.GuideImageDto;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.shared.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MvcResult;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class EvidenceIT extends IntegrationTestBase {

    @Autowired
    MasterContentService masterContent;

    @Autowired
    InspectionFinalSnapshotRepository finalSnapshots;

    @Test
    void evidenceBlocksFinalizationUntilRequiredVerifiedPhotosExist() throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        UUID categoryId = category("evidence");
        MasterItem item = item(categoryId, "SAMPLE-EVID-001", "Evidence check",
                "REQUIRED", 2, "{}");
        String templateId = template(admin, "Evidence template", List.of(item.versionId()));
        String jobId = job(admin, publishedVersion(admin, templateId), "Evidence customer");
        assign(admin, jobId, fixture.techA().getId());
        JsonNode checklist = start(technician, jobId);
        String inspectionItemId = checklist.get("items").get(0).get("inspectionItemId").asText();
        assess(technician, jobId, inspectionItemId, "NO_ISSUE_OBSERVED", null, "Evidence note");

        JsonNode blocked = getJson(technician, "/api/v1/technician/jobs/" + jobId + "/review");
        assertThat(blocked.get("ready").asBoolean()).isFalse();
        assertThat(blocked.toString()).contains("EVIDENCE_REQUIRED");
        mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/ready")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("INSPECTION_INCOMPLETE"));

        byte[] jpeg = jpeg();
        String hash = sha256(jpeg);
        UUID evidence1 = UUID.randomUUID();
        init(technician, jobId, inspectionItemId, evidence1, jpeg.length, hash)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.uploadToken").isNotEmpty());
        String token = initToken(technician, jobId, inspectionItemId, evidence1, jpeg.length, hash);
        upload(technician, evidence1, token, jpeg).andExpect(status().isNoContent());
        complete(technician, jobId, inspectionItemId, evidence1, hash).andExpect(status().isOk());

        JsonNode stillBlocked = getJson(technician, "/api/v1/technician/jobs/" + jobId + "/review");
        assertThat(stillBlocked.get("ready").asBoolean()).isFalse();

        UUID evidence2 = UUID.randomUUID();
        String token2 = initToken(technician, jobId, inspectionItemId, evidence2, jpeg.length, hash);
        upload(technician, evidence2, token2, jpeg).andExpect(status().isNoContent());
        complete(technician, jobId, inspectionItemId, evidence2, hash).andExpect(status().isOk());

        JsonNode ready = getJson(technician, "/api/v1/technician/jobs/" + jobId + "/review");
        assertThat(ready.get("ready").asBoolean()).isTrue();
        assertThat(ready.toString()).doesNotContain("EVIDENCE_REQUIRED");
        postJson(technician, "/api/v1/technician/jobs/" + jobId + "/ready", null);
        JsonNode finalized = finalize(technician, jobId, "evidence-final");
        assertThat(finalized.get("status").asText()).isEqualTo("FINALIZED");
        String snapshot = finalSnapshots.findByJobId(UUID.fromString(jobId)).orElseThrow()
                .getSnapshotJson();
        assertThat(snapshot).contains("sourceSha256").contains(hash).contains("VERIFIED");

        mockMvc.perform(delete("/api/v1/technician/jobs/" + jobId + "/evidence/" + evidence1)
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isConflict());
    }

    @Test
    void evidenceInitIsIdempotentAndRejectsBadInputs() throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        Login technicianB = login("tech.b@test.local");
        Login platform = login("platform@test.local");
        UUID categoryId = category("evidence-validation");
        MasterItem item = item(categoryId, "SAMPLE-EVID-002", "Evidence validation",
                "OPTIONAL", 0, "{}");
        String templateId = template(admin, "Evidence validation template", List.of(item.versionId()));
        String jobId = job(admin, publishedVersion(admin, templateId), "Validation customer");
        assign(admin, jobId, fixture.techA().getId());
        String inspectionItemId = start(technician, jobId).get("items").get(0)
                .get("inspectionItemId").asText();
        byte[] jpeg = jpeg();
        String hash = sha256(jpeg);
        UUID evidenceId = UUID.randomUUID();

        String firstToken = firstInit(technician, jobId, inspectionItemId, evidenceId, jpeg.length, hash);
        String secondToken = firstInit(technician, jobId, inspectionItemId, evidenceId, jpeg.length, hash);
        assertThat(firstToken).isNotBlank();
        assertThat(secondToken).isNotBlank();
        assertThat(getJson(technician, "/api/v1/technician/jobs/" + jobId
                + "/items/" + inspectionItemId + "/evidence").size()).isEqualTo(1);

        init(technician, jobId, inspectionItemId, UUID.randomUUID(), jpeg.length, hash)
                .andExpect(status().isCreated());
        init(technician, jobId, inspectionItemId, UUID.randomUUID(), 9 * 1024 * 1024, hash)
                .andExpect(status().isPayloadTooLarge());
        init(technician, jobId, inspectionItemId, UUID.randomUUID(), jpeg.length,
                sha256("wrong".getBytes(java.nio.charset.StandardCharsets.UTF_8)))
                .andExpect(status().isCreated());

        byte[] png = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        UUID wrongType = UUID.randomUUID();
        String wrongTypeToken = initToken(technician, jobId, inspectionItemId, wrongType,
                png.length, sha256(png));
        upload(technician, wrongType, wrongTypeToken, png)
                .andExpect(status().isUnsupportedMediaType());

        UUID wrongHash = UUID.randomUUID();
        String wrongHashToken = initToken(technician, jobId, inspectionItemId, wrongHash,
                jpeg.length, sha256(jpeg));
        upload(technician, wrongHash, wrongHashToken, jpeg).andExpect(status().isNoContent());
        complete(technician, jobId, inspectionItemId, wrongHash,
                sha256("wrong".getBytes(java.nio.charset.StandardCharsets.UTF_8)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("EVIDENCE_HASH_MISMATCH"));

        init(technicianB, jobId, inspectionItemId, UUID.randomUUID(), jpeg.length, hash)
                .andExpect(status().isNotFound());
        init(admin, jobId, inspectionItemId, UUID.randomUUID(), jpeg.length, hash)
                .andExpect(status().isForbidden());
        init(platform, jobId, inspectionItemId, UUID.randomUUID(), jpeg.length, hash)
                .andExpect(status().isForbidden());

        UUID valid = UUID.randomUUID();
        String validToken = initToken(technician, jobId, inspectionItemId, valid, jpeg.length, hash);
        upload(technician, valid, validToken, jpeg).andExpect(status().isNoContent());
        complete(technician, jobId, inspectionItemId, valid, hash).andExpect(status().isOk());
        mockMvc.perform(delete("/api/v1/technician/jobs/" + jobId + "/evidence/" + valid)
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isNoContent());
        assertThat(getJson(technician, "/api/v1/technician/jobs/" + jobId
                + "/items/" + inspectionItemId + "/evidence").toString())
                .doesNotContain(valid.toString());
    }

    @Test
    void guideImageIsAvailableSeparatelyFromEvidence() throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        byte[] guide = jpeg();
        GuideImageDto guideImage = masterContent.uploadGuideImage(platformActor(),
                new MockMultipartFile("file", "guide.jpg", "image/jpeg", guide),
                "Guide image", "Guide image AR", "Test licence");
        UUID categoryId = category("guide");
        MasterItem item = item(categoryId, "SAMPLE-EVID-003", "Guide and evidence",
                "NONE", 0, "{}", guideImage.id());
        String templateId = template(admin, "Guide template", List.of(item.versionId()));
        String jobId = job(admin, publishedVersion(admin, templateId), "Guide customer");
        assign(admin, jobId, fixture.techA().getId());
        JsonNode checklist = start(technician, jobId);
        String inspectionItemId = checklist.get("items").get(0).get("inspectionItemId").asText();

        MvcResult result = mockMvc.perform(get("/api/v1/technician/jobs/" + jobId
                        + "/items/" + inspectionItemId + "/guide-image")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "image/jpeg"))
                .andReturn();
        assertThat(result.getResponse().getContentAsByteArray()).isEqualTo(guide);
        assertThat(getJson(technician, "/api/v1/technician/jobs/" + jobId
                + "/items/" + inspectionItemId + "/evidence").size()).isZero();
    }

    private org.springframework.test.web.servlet.ResultActions init(Login login, String jobId,
                                                                    String itemId, UUID evidenceId,
                                                                    long bytes, String sha) throws Exception {
        return mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/items/" + itemId
                        + "/evidence/init")
                .header("Authorization", "Bearer " + login.accessToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"evidenceId\":\"" + evidenceId + "\",\"mime\":\"image/jpeg\","
                        + "\"bytes\":" + bytes + ",\"sha256\":\"" + sha + "\","
                        + "\"capturedAt\":\"2026-11-03T12:00:00Z\"}"));
    }

    private String firstInit(Login login, String jobId, String itemId, UUID evidenceId,
                             long bytes, String sha) throws Exception {
        MvcResult result = init(login, jobId, itemId, evidenceId, bytes, sha)
                .andExpect(status().isCreated()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("uploadToken").asText();
    }

    private String initToken(Login login, String jobId, String itemId, UUID evidenceId,
                             long bytes, String sha) throws Exception {
        MvcResult result = init(login, jobId, itemId, evidenceId, bytes, sha)
                .andExpect(status().isCreated()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("uploadToken").asText();
    }

    private org.springframework.test.web.servlet.ResultActions upload(Login login, UUID evidenceId,
                                                                       String token, byte[] bytes) throws Exception {
        return mockMvc.perform(put("/api/v1/technician/evidence/" + evidenceId + "/upload")
                .param("token", token)
                .header("Authorization", "Bearer " + login.accessToken())
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .content(bytes));
    }

    private org.springframework.test.web.servlet.ResultActions complete(Login login, String jobId,
                                                                        String itemId, UUID evidenceId,
                                                                        String sha) throws Exception {
        return mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/items/" + itemId
                        + "/evidence/" + evidenceId + "/complete")
                .header("Authorization", "Bearer " + login.accessToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sha256\":\"" + sha + "\"}"));
    }

    private void assess(Login login, String jobId, String itemId, String result,
                        String severity, String note) throws Exception {
        mockMvc.perform(put("/api/v1/technician/jobs/" + jobId + "/items/" + itemId + "/assessment")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"baseVersion\":0,\"clientRevision\":1,\"resultCode\":\""
                                + result + "\",\"severityCode\":"
                                + (severity == null ? "null" : "\"" + severity + "\"")
                                + ",\"note\":\"" + note + "\"}"))
                .andExpect(status().isOk());
    }

    private JsonNode start(Login login, String jobId) throws Exception {
        return postJson(login, "/api/v1/technician/jobs/" + jobId + "/start", null);
    }

    private JsonNode finalize(Login login, String jobId, String key) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/finalize")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .header("Idempotency-Key", key))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private UUID category(String suffix) {
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("phase5b-" + suffix + "-" + UUID.randomUUID(),
                        "Phase 5B " + suffix, "Phase 5B AR " + suffix, 0, null));
        return category.id();
    }

    private MasterItem item(UUID categoryId, String code, String label, String evidence,
                            int minPhotos, String applicability) {
        return item(categoryId, code, label, evidence, minPhotos, applicability, null);
    }

    private MasterItem item(UUID categoryId, String code, String label, String evidence,
                            int minPhotos, String applicability, UUID guideImageId) {
        ItemDetailDto detail = masterContent.createItem(platformActor(), new ItemCreateRequest(
                code, categoryId, label, "Arabic " + label, "Instruction " + label,
                "Arabic instruction " + label, true,
                List.of("NO_ISSUE_OBSERVED", "DEFECT_FOUND", "NOT_CHECKED", "NOT_APPLICABLE"),
                "{}", applicability, List.of(),
                "OPTIONAL", evidence, minPhotos, List.of(), guideImageId));
        UUID itemId = detail.item().id();
        UUID versionId = detail.versions().get(0).id();
        masterContent.publish(platformActor(), itemId, versionId);
        return new MasterItem(itemId, versionId);
    }

    private String template(Login login, String name, List<UUID> versionIds) throws Exception {
        JsonNode created = postJson(login, "/api/v1/workshop/templates",
                "{\"name\":\"" + name + "\",\"serviceType\":\"FULL\",\"vehicleType\":\"CAR\"}");
        String templateId = created.get("id").asText();
        List<Map<String, Object>> items = new ArrayList<>();
        int index = 0;
        for (UUID versionId : versionIds) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("masterItemVersionId", versionId.toString());
            item.put("sortOrder", index++);
            items.add(item);
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", name);
        body.put("serviceType", "FULL");
        body.put("vehicleType", "CAR");
        body.put("items", items);
        putJson(login, "/api/v1/workshop/templates/" + templateId + "/draft",
                objectMapper.writeValueAsString(body));
        postJson(login, "/api/v1/workshop/templates/" + templateId + "/publish", "{}");
        return templateId;
    }

    private String publishedVersion(Login login, String templateId) throws Exception {
        return getJson(login, "/api/v1/workshop/templates/" + templateId)
                .get("currentPublishedVersionId").asText();
    }

    private String job(Login login, String versionId, String customer) throws Exception {
        return postJson(login, "/api/v1/workshop/jobs",
                "{\"templateVersionId\":\"" + versionId + "\",\"customerName\":\"" + customer
                        + "\",\"vehicleMake\":\"Toyota\",\"vehicleModel\":\"Camry\","
                        + "\"scope\":\"Evidence inspection\"}")
                .get("id").asText();
    }

    private void assign(Login login, String jobId, UUID technicianId) throws Exception {
        postJson(login, "/api/v1/workshop/jobs/" + jobId + "/assign",
                "{\"technicianId\":\"" + technicianId + "\",\"reason\":\"Evidence test\"}");
    }

    private CurrentUser platformActor() {
        return new CurrentUser(fixture.platform().getId(), fixture.platform().getEmail(),
                "PLATFORM_ADMIN", null, null);
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var request = post(path).header("Authorization", "Bearer " + login.accessToken());
        if (body != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(body);
        }
        MvcResult result = mockMvc.perform(request).andExpect(status().is2xxSuccessful()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private byte[] jpeg() throws Exception {
        BufferedImage image = new BufferedImage(16, 16, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < 16; y++) {
            for (int x = 0; x < 16; x++) {
                image.setRGB(x, y, 0x224466);
            }
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", output);
        return output.toByteArray();
    }

    private String sha256(byte[] bytes) throws Exception {
        return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    }

    private record MasterItem(UUID itemId, UUID versionId) {
    }
}
