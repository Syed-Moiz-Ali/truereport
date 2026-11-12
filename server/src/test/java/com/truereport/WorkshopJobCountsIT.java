package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.shared.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkshopJobCountsIT extends IntegrationTestBase {

    private static final String COUNTS_PATH = "/api/v1/workshop/legacy/jobs/counts";

    @Autowired
    MasterContentService masterContent;

    @Autowired
    InspectionJobRepository inspectionJobs;

    @Test
    void roleMatrixIsEnforced() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");

        mockMvc.perform(get(COUNTS_PATH)
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0))
                .andExpect(jsonPath("$.newScheduled").value(0))
                .andExpect(jsonPath("$.finalizedToday").value(0));
        mockMvc.perform(get(COUNTS_PATH)
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get(COUNTS_PATH)
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get(COUNTS_PATH))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void countsAreCorrectPerStatusWithDubaiFinalizedToday() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        String versionId = publishedVersion(adminA, "counts", "SAMPLE-COUNT-001");

        createDraftJob(adminA, versionId, "Counts Draft");
        createScheduledJob(adminA, versionId, "Counts Scheduled");
        String assignedId = createDraftJob(adminA, versionId, "Counts Assigned");
        assign(adminA, assignedId, fixture.techA().getId());
        String inProgressId = createDraftJob(adminA, versionId, "Counts In Progress");
        assign(adminA, inProgressId, fixture.techA().getId());
        start(technician, inProgressId);
        String readyId = createDraftJob(adminA, versionId, "Counts Ready");
        assign(adminA, readyId, fixture.techA().getId());
        start(technician, readyId);
        markReady(readyId, LocalDateTime.now(ZoneOffset.UTC));
        String finalizedTodayId = createDraftJob(adminA, versionId, "Counts Finalized Today");
        assign(adminA, finalizedTodayId, fixture.techA().getId());
        start(technician, finalizedTodayId);
        finalizeJob(finalizedTodayId, LocalDateTime.now(ZoneOffset.UTC));
        String finalizedOldId = createDraftJob(adminA, versionId, "Counts Finalized Old");
        assign(adminA, finalizedOldId, fixture.techA().getId());
        start(technician, finalizedOldId);
        finalizeJob(finalizedOldId, LocalDateTime.now(ZoneOffset.UTC).minusDays(3));
        String cancelledId = createDraftJob(adminA, versionId, "Counts Cancelled");
        cancel(adminA, cancelledId);

        mockMvc.perform(get(COUNTS_PATH)
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.draft").value(1))
                .andExpect(jsonPath("$.scheduled").value(1))
                .andExpect(jsonPath("$.newScheduled").value(2))
                .andExpect(jsonPath("$.assigned").value(1))
                .andExpect(jsonPath("$.inProgress").value(1))
                .andExpect(jsonPath("$.readyToFinalize").value(1))
                .andExpect(jsonPath("$.finalized").value(2))
                .andExpect(jsonPath("$.finalizedToday").value(1))
                .andExpect(jsonPath("$.cancelled").value(1))
                .andExpect(jsonPath("$.total").value(8));
    }

    @Test
    void secondWorkshopsJobsAreNotCounted() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login adminB = login("admin.b@test.local");
        String versionA = publishedVersion(adminA, "isolation-a", "SAMPLE-ISO-A-001");
        String versionB = publishedVersion(adminB, "isolation-b", "SAMPLE-ISO-B-001");

        createDraftJob(adminA, versionA, "Isolation Alpha Customer");
        createDraftJob(adminB, versionB, "Isolation Beta One");
        createScheduledJob(adminB, versionB, "Isolation Beta Two");

        JsonNode countsA = getJson(adminA, COUNTS_PATH);
        assertThat(countsA.get("total").asLong()).isEqualTo(1);
        assertThat(countsA.get("draft").asLong()).isEqualTo(1);
        assertThat(countsA.toString()).doesNotContain("Isolation Beta");

        JsonNode countsB = getJson(adminB, COUNTS_PATH);
        assertThat(countsB.get("total").asLong()).isEqualTo(2);
        assertThat(countsB.get("draft").asLong()).isEqualTo(1);
        assertThat(countsB.get("scheduled").asLong()).isEqualTo(1);
        assertThat(countsB.toString()).doesNotContain("Isolation Alpha");
    }

    @Test
    void responseContainsNoPii() throws Exception {
        Login adminA = login("admin.a@test.local");
        String versionId = publishedVersion(adminA, "pii", "SAMPLE-PII-001");

        String customer = "Counts Pii Customer";
        String phone = "+971509998877";
        String email = "counts.pii@test.local";
        String vin = "PIIVIN00000000001";
        String plate = "PII-4242";
        mockMvc.perform(post("/api/v1/workshop/legacy/jobs")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"templateVersionId":"%s","customerName":"%s","customerPhone":"%s",
                                 "customerEmail":"%s","vehicleMake":"Toyota","vehicleModel":"Camry",
                                 "vehicleYear":2022,"vehicleVin":"%s","vehiclePlate":"%s",
                                 "scope":"Full inspection"}
                                """.formatted(versionId, customer, phone, email, vin, plate)))
                .andExpect(status().isCreated());

        var result = mockMvc.perform(get(COUNTS_PATH)
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1))
                .andReturn();
        String body = result.getResponse().getContentAsString();
        assertThat(body).doesNotContain(customer, phone, email, vin, plate);
    }

    @Test
    void writeMethodsAreRejected() throws Exception {
        Login adminA = login("admin.a@test.local");
        mockMvc.perform(post(COUNTS_PATH)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isMethodNotAllowed());
        mockMvc.perform(put(COUNTS_PATH)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isMethodNotAllowed());
        mockMvc.perform(delete(COUNTS_PATH)
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isMethodNotAllowed());
    }

    private String publishedVersion(Login login, String suffix, String code) throws Exception {
        UUID categoryId = category(suffix);
        ItemDetailDto detail = masterContent.createItem(platformActor(), new ItemCreateRequest(
                code, categoryId, "Counts label", "Arabic label", "Instruction",
                "Arabic instruction", true,
                List.of("NO_ISSUE_OBSERVED", "DEFECT_FOUND", "NOT_CHECKED"),
                "{\"DEFECT_FOUND\":\"MODERATE\"}", "{}", List.of(),
                "OPTIONAL", "NONE", 0, List.of(), null));
        UUID itemId = detail.item().id();
        UUID versionId = detail.versions().get(0).id();
        masterContent.publish(platformActor(), itemId, versionId);

        JsonNode created = postJson(login, "/api/v1/workshop/templates",
                "{\"name\":\"Counts template " + suffix + "\",\"serviceType\":\"FULL\",\"vehicleType\":\"CAR\"}");
        String templateId = created.get("id").asText();
        List<Map<String, Object>> items = new ArrayList<>();
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("masterItemVersionId", versionId.toString());
        item.put("sortOrder", 0);
        items.add(item);
        putJson(login, "/api/v1/workshop/templates/" + templateId + "/draft",
                objectMapper.writeValueAsString(Map.of(
                        "name", "Counts template " + suffix,
                        "serviceType", "FULL",
                        "vehicleType", "CAR",
                        "items", items)));
        JsonNode published = postJson(login, "/api/v1/workshop/templates/" + templateId + "/publish", "{}");
        return published.get("currentPublishedVersionId").asText();
    }

    private String createDraftJob(Login login, String versionId, String customer) throws Exception {
        return postJson(login, "/api/v1/workshop/legacy/jobs", """
                {"templateVersionId":"%s","customerName":"%s",
                 "vehicleMake":"Toyota","vehicleModel":"Camry","vehicleYear":2022,
                 "scope":"Full inspection"}
                """.formatted(versionId, customer)).get("id").asText();
    }

    private String createScheduledJob(Login login, String versionId, String customer) throws Exception {
        return postJson(login, "/api/v1/workshop/legacy/jobs", """
                {"templateVersionId":"%s","scheduledAt":"2026-11-05T09:00:00",
                 "customerName":"%s","vehicleMake":"Toyota","vehicleModel":"Camry",
                 "vehicleYear":2022,"scope":"Full inspection"}
                """.formatted(versionId, customer)).get("id").asText();
    }

    private void assign(Login login, String jobId, UUID technicianId) throws Exception {
        postJson(login, "/api/v1/workshop/legacy/jobs/" + jobId + "/assign",
                "{\"technicianId\":\"" + technicianId + "\",\"reason\":\"Assigned\"}");
    }

    private void cancel(Login login, String jobId) throws Exception {
        postJson(login, "/api/v1/workshop/legacy/jobs/" + jobId + "/cancel",
                "{\"reason\":\"No longer needed\"}");
    }

    private void start(Login login, String jobId) throws Exception {
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/start")
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk());
    }

    private void markReady(String jobId, LocalDateTime at) {
        InspectionJob job = inspectionJobs.findById(UUID.fromString(jobId)).orElseThrow();
        job.markReady(at);
        inspectionJobs.save(job);
    }

    private void finalizeJob(String jobId, LocalDateTime at) {
        InspectionJob job = inspectionJobs.findById(UUID.fromString(jobId)).orElseThrow();
        job.finalizeInspection(fixture.techA().getId(), at, new byte[32]);
        inspectionJobs.save(job);
    }

    private UUID category(String suffix) {
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("counts-" + suffix + "-" + UUID.randomUUID(),
                        "Counts " + suffix, "Counts AR " + suffix, 0, null));
        return category.id();
    }

    private CurrentUser platformActor() {
        return new CurrentUser(fixture.platform().getId(), fixture.platform().getEmail(),
                "PLATFORM_ADMIN", null, null);
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

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
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
}
