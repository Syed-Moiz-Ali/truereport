package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.api.ItemVersionDto;
import com.truereport.masterdata.api.TranslationRequest;
import com.truereport.shared.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkshopAdminIT extends IntegrationTestBase {

    @Autowired
    MasterContentService masterContent;

    @Test
    void templatePinsMasterVersionAndExistingJobKeepsItAfterPublishAndRetirement() throws Exception {
        Login platform = login("platform@test.local");
        Login adminA = login("admin.a@test.local");
        UUID categoryId = category("pin");
        MasterItem item = publishedItem(categoryId, "SAMPLE-PIN-001", "Version one label",
                "REQUIRED", "REQUIRED", 2);
        String templateId = createTemplate(adminA, "Pinned template");
        JsonNode saved = saveDraft(adminA, templateId, List.of(item.versionId()), "Pinned template");
        assertThat(saved.get("draft").get("items").get(0).get("labelEn").asText())
                .isEqualTo("Version one label");
        JsonNode published = postJson(adminA, "/api/v1/workshop/templates/" + templateId + "/publish", "{}");
        UUID v1 = UUID.fromString(published.get("currentPublishedVersionId").asText());
        String jobId = createJob(adminA, v1, "Customer One").get("id").asText();

        UUID v2 = createSecondMasterVersion(item, "Version two label");
        JsonNode templateAfterMasterEdit = getJson(adminA, "/api/v1/workshop/templates/" + templateId);
        assertThat(findVersion(templateAfterMasterEdit.get("versions"), 1)
                .get("id").asText()).isEqualTo(v1.toString());
        assertThat(getJson(adminA, "/api/v1/workshop/templates/" + templateId
                + "/versions/" + v1).get("items").get(0).get("labelEn").asText())
                .isEqualTo("Version one label");

        masterContent.retireItem(platformActor(), item.itemId());
        JsonNode oldVersion = getJson(adminA, "/api/v1/workshop/templates/" + templateId
                + "/versions/" + v1);
        assertThat(oldVersion.get("items").get(0).get("labelEn").asText())
                .isEqualTo("Version one label");

        JsonNode jobs = getJson(adminA, "/api/v1/workshop/legacy/jobs");
        assertThat(jobs.get(0).get("id").asText()).isEqualTo(jobId);
        assertThat(jobs.get(0).get("templateVersionId").asText()).isEqualTo(v1.toString());

        String newTemplateId = createTemplate(adminA, "Retired item template");
        mockMvc.perform(put("/api/v1/workshop/templates/" + newTemplateId + "/draft")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(draftBody("Retired item template", List.of(item.versionId()))))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("MASTER_ITEM_NOT_AVAILABLE"));

        assertThat(v2).isNotNull();
    }

    @Test
    void workshopIsolationRoleMatrixAndStaffAreEnforced() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login adminB = login("admin.b@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        UUID categoryId = category("roles");
        MasterItem item = publishedItem(categoryId, "SAMPLE-ROLE-001", "Role label",
                "OPTIONAL", "NONE", 0);
        String templateA = createTemplate(adminA, "A template");
        saveDraft(adminA, templateA, List.of(item.versionId()), "A template");
        JsonNode published = postJson(adminA, "/api/v1/workshop/templates/" + templateA + "/publish", "{}");
        UUID versionA = UUID.fromString(published.get("currentPublishedVersionId").asText());
        String jobA = createJob(adminA, versionA, "Isolation customer").get("id").asText();

        assertThat(getJson(adminA, "/api/v1/workshop/templates").toString()).contains(templateA);
        assertThat(getJson(adminB, "/api/v1/workshop/templates").toString()).doesNotContain(templateA);
        mockMvc.perform(get("/api/v1/workshop/templates/" + templateA)
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(put("/api/v1/workshop/templates/" + templateA + "/draft")
                        .header("Authorization", "Bearer " + adminB.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(draftBody("Hijacked", List.of(item.versionId()))))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/v1/workshop/templates/" + templateA + "/publish")
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());

        assertThat(getJson(adminA, "/api/v1/workshop/legacy/jobs").toString()).contains(jobA);
        assertThat(getJson(adminB, "/api/v1/workshop/legacy/jobs").toString()).doesNotContain(jobA);
        mockMvc.perform(post("/api/v1/workshop/legacy/jobs/" + jobA + "/assign")
                        .header("Authorization", "Bearer " + adminB.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"technicianId\":\"" + fixture.techA().getId() + "\"}"))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/v1/workshop/legacy/jobs/" + jobA + "/cancel")
                        .header("Authorization", "Bearer " + adminB.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"Not mine\"}"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/workshop/legacy/jobs/" + jobA + "/assignments")
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());

        String staffA = getJson(adminA, "/api/v1/workshop/staff").toString();
        String staffB = getJson(adminB, "/api/v1/workshop/staff").toString();
        assertThat(staffA).contains("Technician A");
        assertThat(staffB).doesNotContain("Technician A");

        JsonNode assigned = postJson(adminA, "/api/v1/workshop/legacy/jobs/" + jobA + "/assign",
                "{\"technicianId\":\"" + fixture.techA().getId() + "\",\"reason\":\"Assigned\"}");
        assertThat(assigned.get("status").asText()).isEqualTo("ASSIGNED");
        JsonNode technicianJobs = getJson(technician, "/api/v1/technician/legacy/jobs");
        assertThat(technicianJobs.toString()).contains(jobA);
        assertThat(getJson(technician, "/api/v1/technician/legacy/jobs/" + jobA).get("id").asText())
                .isEqualTo(jobA);

        String unassignedJob = createJob(adminA, versionA, "Unassigned customer").get("id").asText();
        assertThat(getJson(technician, "/api/v1/technician/legacy/jobs").toString())
                .doesNotContain(unassignedJob);
        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + unassignedJob)
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isNotFound());

        assertForbidden(technician, platform, "/api/v1/workshop/templates", false);
        assertForbidden(technician, platform, "/api/v1/workshop/templates/versions", false);
        assertForbidden(technician, platform, "/api/v1/workshop/master/categories", false);
        assertForbidden(technician, platform, "/api/v1/workshop/master/items", false);
        assertForbidden(technician, platform, "/api/v1/workshop/legacy/jobs", false);
        assertForbidden(technician, platform, "/api/v1/workshop/staff", false);
        assertForbidden(technician, platform, "/api/v1/workshop/legacy/jobs/" + jobA + "/assignments", false);
        assertForbidden(technician, platform, "/api/v1/workshop/templates", true);
        assertForbidden(technician, platform, "/api/v1/workshop/legacy/jobs", true);
        mockMvc.perform(get("/api/v1/technician/legacy/jobs")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/technician/legacy/jobs")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());

        String random = UUID.randomUUID().toString();
        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + random)
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + random)
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());
        String[] protectedGets = {
                "/api/v1/workshop/master/categories",
                "/api/v1/workshop/master/items",
                "/api/v1/workshop/master/items/" + random,
                "/api/v1/workshop/staff",
                "/api/v1/workshop/legacy/jobs",
                "/api/v1/workshop/legacy/jobs/" + random + "/assignments",
                "/api/v1/workshop/templates",
                "/api/v1/workshop/templates/versions",
                "/api/v1/workshop/templates/" + random,
                "/api/v1/workshop/templates/" + random + "/versions",
                "/api/v1/workshop/templates/" + random + "/versions/" + random,
                "/api/v1/workshop/templates/" + random + "/preview"
        };
        for (String path : protectedGets) {
            assertForbidden(technician, platform, path, false);
        }
        String[] protectedPosts = {
                "/api/v1/workshop/legacy/jobs",
                "/api/v1/workshop/legacy/jobs/" + random + "/assign",
                "/api/v1/workshop/legacy/jobs/" + random + "/cancel",
                "/api/v1/workshop/templates",
                "/api/v1/workshop/templates/" + random + "/draft",
                "/api/v1/workshop/templates/" + random + "/publish",
                "/api/v1/workshop/templates/" + random + "/retire"
        };
        for (String path : protectedPosts) {
            assertForbidden(technician, platform, path, true);
        }
        mockMvc.perform(put("/api/v1/workshop/templates/" + random + "/draft")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/v1/workshop/templates/" + random + "/draft")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());

        assertThat(getJson(platform, "/api/v1/platform/audit-events").toString())
                .contains("TEMPLATE_PUBLISHED")
                .contains("JOB_CREATED")
                .contains("JOB_ASSIGNED");
    }

    @Test
    void craftedOverridesFailAndHundredPlusItemTemplatePublishes() throws Exception {
        Login adminA = login("admin.a@test.local");
        UUID categoryId = category("bulk");
        MasterItem guarded = publishedItem(categoryId, "SAMPLE-GUARD-001", "Guarded",
                "REQUIRED", "REQUIRED", 2);
        String guardedTemplate = createTemplate(adminA, "Guarded template");
        mockMvc.perform(put("/api/v1/workshop/templates/" + guardedTemplate + "/draft")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Guarded template","serviceType":"FULL",
                                 "items":[{"masterItemVersionId":"%s","sortOrder":0,
                                 "overrides":{"noteRequirement":"NONE"}}]}
                                """.formatted(guarded.versionId())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TEMPLATE_WEAKENS_SAFETY_RULE"));
        mockMvc.perform(put("/api/v1/workshop/templates/" + guardedTemplate + "/draft")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Guarded template","serviceType":"FULL",
                                 "items":[{"masterItemVersionId":"%s","sortOrder":0,
                                 "noteRequirement":"NONE"}]}
                                """.formatted(guarded.versionId())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TEMPLATE_WEAKENS_SAFETY_RULE"));

        String bulkTemplate = createTemplate(adminA, "Full inspection package");
        List<UUID> versions = new ArrayList<>();
        for (int i = 0; i < 105; i++) {
            versions.add(publishedItem(categoryId, "SAMPLE-BULK-" + String.format("%03d", i),
                    "Bulk item " + i, "OPTIONAL", "OPTIONAL", 0).versionId());
        }
        saveDraft(adminA, bulkTemplate, versions, "Full inspection package");
        JsonNode published = postJson(adminA, "/api/v1/workshop/templates/" + bulkTemplate + "/publish", "{}");
        String publishedVersion = published.get("currentPublishedVersionId").asText();
        JsonNode view = getJson(adminA, "/api/v1/workshop/templates/" + bulkTemplate
                + "/versions/" + publishedVersion);
        assertThat(view.get("items").size()).isEqualTo(105);
    }

    private void assertForbidden(Login technician, Login platform, String path, boolean post) throws Exception {
        var request = post
                ? post(path).header("Authorization", "Bearer " + technician.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}")
                : get(path).header("Authorization", "Bearer " + technician.accessToken());
        mockMvc.perform(request).andExpect(status().isForbidden());
        request = post
                ? post(path).header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}")
                : get(path).header("Authorization", "Bearer " + platform.accessToken());
        mockMvc.perform(request).andExpect(status().isForbidden());
    }

    private UUID category(String suffix) {
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("phase4-" + suffix + "-" + UUID.randomUUID(),
                        "Phase 4 " + suffix, "Phase 4 AR " + suffix, 0, null));
        return category.id();
    }

    private MasterItem publishedItem(UUID categoryId, String code, String label,
                                     String note, String evidence, int minPhotos) {
        ItemDetailDto detail = masterContent.createItem(platformActor(), new ItemCreateRequest(
                code, categoryId, label, "Arabic " + label, "Instruction " + label,
                "Arabic instruction " + label, true,
                List.of("NO_ISSUE_OBSERVED", "DEFECT_FOUND", "NOT_CHECKED"),
                "{\"DEFECT_FOUND\":\"MODERATE\"}", "{}", List.of(),
                note, evidence, minPhotos, List.of(), null));
        UUID itemId = detail.item().id();
        UUID versionId = detail.versions().get(0).id();
        masterContent.publish(platformActor(), itemId, versionId);
        return new MasterItem(itemId, versionId);
    }

    private UUID createSecondMasterVersion(MasterItem item, String label) {
        ItemDetailDto draft = masterContent.createDraft(platformActor(), item.itemId());
        ItemVersionDto version = draft.versions().stream()
                .filter(value -> value.status().equals("DRAFT"))
                .findFirst().orElseThrow();
        masterContent.updateTranslation(platformActor(), item.itemId(), version.id(), "en",
                new TranslationRequest(label, "Updated instruction"));
        masterContent.publish(platformActor(), item.itemId(), version.id());
        return version.id();
    }

    private CurrentUser platformActor() {
        return new CurrentUser(fixture.platform().getId(), fixture.platform().getEmail(),
                "PLATFORM_ADMIN", null, null);
    }

    private String createTemplate(Login login, String name) throws Exception {
        JsonNode response = postJson(login, "/api/v1/workshop/templates",
                "{\"name\":\"" + name + "\",\"serviceType\":\"FULL\",\"vehicleType\":\"CAR\"}");
        return response.get("id").asText();
    }

    private JsonNode saveDraft(Login login, String templateId, List<UUID> versionIds,
                               String name) throws Exception {
        return putJson(login, "/api/v1/workshop/templates/" + templateId + "/draft",
                draftBody(name, versionIds));
    }

    private String draftBody(String name, List<UUID> versionIds) throws Exception {
        List<Map<String, Object>> items = new ArrayList<>();
        int index = 0;
        for (UUID versionId : versionIds) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("masterItemVersionId", versionId.toString());
            item.put("sortOrder", index++);
            items.add(item);
        }
        return objectMapper.writeValueAsString(Map.of(
                "name", name,
                "serviceType", "FULL",
                "vehicleType", "CAR",
                "items", items));
    }

    private JsonNode createJob(Login login, UUID templateVersionId, String customer) throws Exception {
        return postJson(login, "/api/v1/workshop/legacy/jobs", """
                {"templateVersionId":"%s","scheduledAt":"2026-11-05T09:00:00",
                 "customerName":"%s","customerPhone":"+971500000000",
                 "customerEmail":"customer@test.local",
                 "vehicleMake":"Toyota","vehicleModel":"Camry","vehicleYear":2022,
                 "vehicleVin":"TESTVIN00000000001","vehiclePlate":"A12345",
                 "scope":"Full inspection"}
                """.formatted(templateVersionId, customer));
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

    private JsonNode findVersion(JsonNode versions, int versionNo) {
        for (JsonNode version : versions) {
            if (version.get("versionNo").asInt() == versionNo) {
                return version;
            }
        }
        throw new AssertionError("Version not found: " + versionNo);
    }

    private record MasterItem(UUID itemId, UUID versionId) {
    }
}
