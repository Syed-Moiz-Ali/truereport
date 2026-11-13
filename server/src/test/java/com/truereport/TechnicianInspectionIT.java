package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.inspections.InspectionFinalSnapshotRepository;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.api.TranslationRequest;
import com.truereport.shared.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TechnicianInspectionIT extends IntegrationTestBase {

    @Autowired
    MasterContentService masterContent;

    @Autowired
    InspectionFinalSnapshotRepository finalSnapshots;

    @Test
    void onlineInspectionFinalizesAtomicallyAndIdempotently() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        UUID categoryId = category("finalize");
        MasterItem item = item(categoryId, "SAMPLE-5A-001", "Panel check", "OPTIONAL", "NONE", 0, "{}");
        String templateId = template(adminA, "Online inspection", List.of(item.versionId()), "CAR");
        String versionId = publishedVersion(adminA, templateId);
        String jobId = job(adminA, versionId, "Customer Finalize");
        assign(adminA, jobId, fixture.techA().getId());

        JsonNode checklist = start(technician, jobId);
        String itemId = checklist.get("items").get(0).get("inspectionItemId").asText();
        assertThat(checklist.get("items").get(0).has("assessment")).isFalse();

        customer(technician, jobId, "Customer Finalize", "+971500000000", "finalize@test.local");
        vehicle(technician, jobId, "Toyota", "Camry", 2022, "TESTVIN00000000001", "A12345", 82902, "KM");
        consent(technician, jobId, "PROCESSING", "GRANTED");
        assess(technician, jobId, itemId, "DEFECT_FOUND", "MODERATE", "نص عربي", "ar", null, null);
        JsonNode review = getJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/review");
        assertThat(review.get("ready").asBoolean()).isTrue();
        assertThat(review.get("blocking").size()).isZero();
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/finalize")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "too-early"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("READY_REQUIRED"));
        JsonNode ready = postJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/ready", null);
        assertThat(ready.get("job").get("status").asText()).isEqualTo("READY_TO_FINALIZE");

        JsonNode first = finalize(technician, jobId, "final-key-1");
        assertThat(first.get("status").asText()).isEqualTo("FINALIZED");
        assertThat(first.get("snapshotHash").asText()).isNotBlank();
        JsonNode second = finalize(technician, jobId, "final-key-1");
        assertThat(second.get("snapshotHash").asText())
                .isEqualTo(first.get("snapshotHash").asText());
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/finalize")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "different-key"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_FINALIZED"));

        assertThat(finalSnapshots.findByJobId(UUID.fromString(jobId))).isPresent();
        assertThat(finalSnapshots.findByJobId(UUID.fromString(jobId)).orElseThrow()
                .getSnapshotJson()).contains("Panel check").contains("نص عربي");

        mockMvc.perform(put("/api/v1/technician/legacy/jobs/" + jobId + "/items/" + itemId + "/assessment")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(assessmentBody("NO_ISSUE_OBSERVED", null, null, 1)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_FINALIZED"));
        mockMvc.perform(put("/api/v1/technician/legacy/jobs/" + jobId + "/customer")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"customerName\":\"Changed\"}"))
                .andExpect(status().isConflict());
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/start")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isConflict());

        assertThat(getJson(platform, "/api/v1/platform/audit-events").toString())
                .contains("INSPECTION_STARTED")
                .contains("INSPECTION_FINALIZED");
    }

    @Test
    void validationMatrixAndUnicodeNotesAreEnforced() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        UUID categoryId = category("rules");
        MasterItem item = item(categoryId, "SAMPLE-5A-002", "Guarded item", "REQUIRED",
                "REQUIRED", 2, "{\"vehicleTypes\":[\"CAR\"]}");
        String templateId = template(adminA, "Rule inspection", List.of(item.versionId()), "CAR");
        String jobId = job(adminA, publishedVersion(adminA, templateId), "Customer Rules");
        assign(adminA, jobId, fixture.techA().getId());
        String itemId = start(technician, jobId).get("items").get(0).get("inspectionItemId").asText();

        assessment(technician, jobId, itemId, assessmentBody("INVALID", null, null, 1))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("RESULT_INVALID"));
        assessment(technician, jobId, itemId, assessmentBody("DEFECT_FOUND", null, null, 1))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("SEVERITY_REQUIRED"));
        assessment(technician, jobId, itemId, assessmentBody("NOT_CHECKED", null, null, 1))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("REASON_REQUIRED"));
        assessment(technician, jobId, itemId, assessmentBody("NO_ISSUE_OBSERVED", null, null, 1))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("NOTE_REQUIRED"));
        assessment(technician, jobId, itemId, assessmentBody("NO_ISSUE_OBSERVED", null,
                "ملاحظة عربية", 1, "ar"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.assessment.note").value("ملاحظة عربية"))
                .andExpect(jsonPath("$.assessment.noteLanguage").value("ar"));
        assessment(technician, jobId, itemId, assessmentBody("NO_ISSUE_OBSERVED", null,
                "Русский текст", 2, "ru", 0))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.assessment.note").value("Русский текст"));
        assessment(technician, jobId, itemId, assessmentBody("NO_ISSUE_OBSERVED", null,
                "中文说明", 3, "zh-Hans", 1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.assessment.note").value("中文说明"));
        mockMvc.perform(put("/api/v1/technician/legacy/jobs/" + jobId + "/items/" + itemId + "/assessment")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(assessmentBody("NO_ISSUE_OBSERVED", null, "stale", 99)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("VERSION_CONFLICT"));

        JsonNode review = getJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/review");
        assertThat(review.get("ready").asBoolean()).isFalse();
        assertThat(review.toString()).contains("EVIDENCE_REQUIRED");
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/ready")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("INSPECTION_INCOMPLETE"));

        MasterItem applicability = item(categoryId, "SAMPLE-5A-003", "Vehicle type guard",
                "OPTIONAL", "NONE", 0, "{\"vehicleTypes\":[\"MOTORCYCLE\"]}");
        String template2 = template(adminA, "Applicability", List.of(applicability.versionId()), "CAR");
        String job2 = job(adminA, publishedVersion(adminA, template2), "Applicability customer");
        assign(adminA, job2, fixture.techA().getId());
        String item2 = start(technician, job2).get("items").get(0).get("inspectionItemId").asText();
        assessment(technician, job2, item2, assessmentBody("NO_ISSUE_OBSERVED", null, null, 1))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ITEM_NOT_APPLICABLE"));
        assessment(technician, job2, item2, assessmentBody("NOT_APPLICABLE", null, null, 1))
                .andExpect(status().isOk());
    }

    @Test
    void hundredPlusItemsCompleteAndSnapshotRemainsPinnedAfterMasterChange() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        UUID categoryId = category("bulk");
        List<UUID> versions = new ArrayList<>();
        MasterItem first = null;
        for (int i = 0; i < 105; i++) {
            MasterItem created = item(categoryId, "SAMPLE-5A-BULK-" + String.format("%03d", i),
                    "Bulk check " + i, "OPTIONAL", "NONE", 0, "{}");
            if (first == null) {
                first = created;
            }
            versions.add(created.versionId());
        }
        String templateId = template(adminA, "100+ inspection", versions, "CAR");
        String version1 = publishedVersion(adminA, templateId);
        String jobId = job(adminA, version1, "Bulk customer");
        assign(adminA, jobId, fixture.techA().getId());
        JsonNode checklist = start(technician, jobId);
        assertThat(checklist.get("items").size()).isEqualTo(105);
        for (JsonNode item : checklist.get("items")) {
            assessment(technician, jobId, item.get("inspectionItemId").asText(),
                    assessmentBody("NO_ISSUE_OBSERVED", null, null, 1))
                    .andExpect(status().isOk());
        }

        ItemDetailDto masterDraft = masterContent.createDraft(platformActor(), first.itemId());
        UUID masterDraftVersion = masterDraft.versions().stream()
                .filter(value -> value.status().equals("DRAFT")).findFirst().orElseThrow().id();
        masterContent.updateTranslation(platformActor(), first.itemId(), masterDraftVersion, "en",
                new TranslationRequest("Changed after start", "Changed instruction"));
        masterContent.updateTranslation(platformActor(), first.itemId(), masterDraftVersion, "ar",
                new TranslationRequest("تغيير بعد البدء", "تعليمات محدثة"));
        masterContent.publish(platformActor(), first.itemId(), masterDraftVersion);
        // Master/template changes after start must not change this pinned checklist.
        String v2 = createTemplateDraftAndPublish(adminA, templateId);
        assertThat(v2).isNotEqualTo(version1);
        JsonNode review = getJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/review");
        assertThat(review.get("ready").asBoolean()).isTrue();
        postJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/ready", null);
        JsonNode finalized = finalize(technician, jobId, "bulk-key");
        assertThat(finalized.get("itemCount").asInt()).isEqualTo(105);
        JsonNode checklistAfter = getJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/checklist");
        assertThat(checklistAfter.get("items").size()).isEqualTo(105);
        assertThat(checklistAfter.get("job").get("status").asText()).isEqualTo("FINALIZED");
    }

    @Test
    void technicianIsolationReassignCancelWalkInAndRoleMatrix() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technicianA = login("tech.a@test.local");
        Login technicianB = login("tech.b@test.local");
        Login technicianC = login("tech.c@test.local");
        Login platform = login("platform@test.local");
        UUID categoryId = category("isolation");
        MasterItem item = item(categoryId, "SAMPLE-5A-004", "Isolation item",
                "OPTIONAL", "NONE", 0, "{}");
        String templateId = template(adminA, "Isolation inspection", List.of(item.versionId()), "CAR");
        String versionId = publishedVersion(adminA, templateId);
        String jobId = job(adminA, versionId, "Isolation customer");
        assign(adminA, jobId, fixture.techA().getId());
        start(technicianA, jobId);

        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + jobId + "/checklist")
                        .header("Authorization", "Bearer " + technicianB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + jobId + "/checklist")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + jobId + "/checklist")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/v1/workshop/legacy/jobs/" + jobId + "/cancel")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"Cancelled during inspection\"}"))
                .andExpect(status().isOk());
        assessment(technicianA, jobId, startItemId(technicianA, jobId),
                assessmentBody("NO_ISSUE_OBSERVED", null, null, 1))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("JOB_CANCELLED"));

        String job2 = job(adminA, versionId, "Reassign customer");
        assign(adminA, job2, fixture.techA().getId());
        String itemId = start(technicianA, job2).get("items").get(0).get("inspectionItemId").asText();
        mockMvc.perform(post("/api/v1/workshop/legacy/jobs/" + job2 + "/assign")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"technicianId\":\"" + fixture.techC().getId() + "\",\"reason\":\"Reassigned\"}"))
                .andExpect(status().isOk());
        assessment(technicianA, job2, itemId, assessmentBody("NO_ISSUE_OBSERVED", null, null, 1))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("JOB_REASSIGNED"));
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + job2 + "/start")
                        .header("Authorization", "Bearer " + technicianC.accessToken()))
                .andExpect(status().isOk());

        JsonNode walkIn = postJson(technicianA, "/api/v1/technician/legacy/jobs", walkInBody(versionId, "Walk-in customer"));
        String walkInId = walkIn.get("id").asText();
        assertThat(walkIn.get("status").asText()).isEqualTo("ASSIGNED");
        assertThat(walkIn.get("assignedTechnicianId").asText())
                .isEqualTo(fixture.techA().getId().toString());
        assertThat(getJson(adminA, "/api/v1/workshop/legacy/jobs").toString()).contains(walkInId);

        String random = UUID.randomUUID().toString();
        String[] technicianGets = {
                "/api/v1/technician/legacy/jobs",
                "/api/v1/technician/legacy/jobs/" + random,
                "/api/v1/technician/legacy/jobs/" + random + "/checklist",
                "/api/v1/technician/legacy/jobs/" + random + "/equipment",
                "/api/v1/technician/legacy/jobs/" + random + "/review",
                "/api/v1/technician/legacy/templates/versions"
        };
        for (String path : technicianGets) {
            assertTechnicianForbidden(adminA, path, "GET");
            assertTechnicianForbidden(platform, path, "GET");
        }
        String[] technicianPosts = {
                "/api/v1/technician/legacy/jobs",
                "/api/v1/technician/legacy/jobs/" + random + "/start",
                "/api/v1/technician/legacy/jobs/" + random + "/consent",
                "/api/v1/technician/legacy/jobs/" + random + "/ready",
                "/api/v1/technician/legacy/jobs/" + random + "/finalize"
        };
        for (String path : technicianPosts) {
            assertTechnicianForbidden(adminA, path, "POST");
            assertTechnicianForbidden(platform, path, "POST");
        }
        String[] technicianPuts = {
                "/api/v1/technician/legacy/jobs/" + random + "/customer",
                "/api/v1/technician/legacy/jobs/" + random + "/vehicle",
                "/api/v1/technician/legacy/jobs/" + random + "/items/" + random + "/assessment"
        };
        for (String path : technicianPuts) {
            assertTechnicianForbidden(adminA, path, "PUT");
            assertTechnicianForbidden(platform, path, "PUT");
        }
        mockMvc.perform(get("/api/v1/technician/legacy/jobs/" + walkInId + "/checklist")
                        .header("Authorization", "Bearer " + technicianB.accessToken()))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/v1/technician/legacy/jobs")
                        .header("Authorization", "Bearer " + technicianB.accessToken()))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/technician/legacy/jobs")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(walkInBody(versionId, "Not allowed")))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/technician/legacy/jobs")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(walkInBody(versionId, "Not allowed")))
                .andExpect(status().isForbidden());
    }

    @Test
    void technicianReadsOwnJobEquipmentWithLabelsCodeStatusAndOrder() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        EquipmentRef late = equipment(platform, "EQ-LATE", "Late equipment", "معدات متأخرة", 30);
        EquipmentRef early = equipment(platform, "EQ-EARLY", "Early equipment", "معدات مبكرة", 10);
        EquipmentRef middle = equipment(platform, "EQ-MIDDLE", "Middle equipment", "معدات متوسطة", 20);
        UUID categoryId = category("equipment");
        MasterItem item = item(categoryId, "SAMPLE-EQ-001", "Equipment item", "OPTIONAL", "NONE", 0,
                "{}", List.of(late.id(), early.id(), middle.id()));
        String templateId = template(adminA, "Equipment inspection", List.of(item.versionId()), "CAR");
        String jobId = job(adminA, publishedVersion(adminA, templateId), "Equipment customer");
        assign(adminA, jobId, fixture.techA().getId());
        start(technician, jobId);

        JsonNode equipment = getJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/equipment");
        JsonNode items = equipment.get("items");
        assertThat(items.size()).isEqualTo(3);
        assertEquipmentItem(items.get(0), early);
        assertEquipmentItem(items.get(1), middle);
        assertEquipmentItem(items.get(2), late);
        assertThat(items.get(0).get("sortOrder").asInt()).isLessThan(items.get(1).get("sortOrder").asInt());
        assertThat(items.get(1).get("sortOrder").asInt()).isLessThan(items.get(2).get("sortOrder").asInt());
    }

    @Test
    void equipmentIdsAndItemsAgreeInMembership() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        EquipmentRef first = equipment(platform, "EQ-MEM-1", "Membership one", "عضوية واحد", 2);
        EquipmentRef second = equipment(platform, "EQ-MEM-2", "Membership two", "عضوية اثنان", 1);
        UUID categoryId = category("equipment-membership");
        MasterItem item = item(categoryId, "SAMPLE-EQ-MEM", "Equipment membership", "OPTIONAL",
                "NONE", 0, "{}", List.of(first.id(), second.id()));
        String templateId = template(adminA, "Equipment membership", List.of(item.versionId()), "CAR");
        String jobId = job(adminA, publishedVersion(adminA, templateId), "Equipment membership customer");
        assign(adminA, jobId, fixture.techA().getId());
        start(technician, jobId);

        JsonNode equipment = getJson(technician, "/api/v1/technician/legacy/jobs/" + jobId + "/equipment");
        Set<UUID> ids = uuids(equipment.get("equipmentIds"));
        Set<UUID> itemIds = new LinkedHashSet<>();
        equipment.get("items").forEach(value -> itemIds.add(UUID.fromString(value.get("equipmentId").asText())));
        assertThat(itemIds).isEqualTo(ids);
        assertThat(ids).containsExactlyInAnyOrder(first.id(), second.id());
    }

    @Test
    void technicianCannotReadAnotherWorkshopsJobEquipmentAndEndpointIsReadOnly() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login technicianA = login("tech.a@test.local");
        Login technicianB = login("tech.b@test.local");
        Login platform = login("platform@test.local");
        EquipmentRef ref = equipment(platform, "EQ-ISO", "Isolation equipment", "معدات العزل", 5);
        UUID categoryId = category("equipment-isolation");
        MasterItem item = item(categoryId, "SAMPLE-EQ-ISO", "Equipment isolation", "OPTIONAL", "NONE", 0,
                "{}", List.of(ref.id()));
        String templateId = template(adminA, "Equipment isolation", List.of(item.versionId()), "CAR");
        String jobId = job(adminA, publishedVersion(adminA, templateId), "Equipment isolation customer");
        assign(adminA, jobId, fixture.techA().getId());
        start(technicianA, jobId);

        String path = "/api/v1/technician/legacy/jobs/" + jobId + "/equipment";
        mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + technicianB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());

        mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + technicianA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isMethodNotAllowed());
        mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + technicianA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isMethodNotAllowed());
        mockMvc.perform(delete(path)
                        .header("Authorization", "Bearer " + technicianA.accessToken()))
                .andExpect(status().isMethodNotAllowed());
    }

    private EquipmentRef equipment(Login platform, String code, String labelEn, String labelAr,
                                   int sortOrder) throws Exception {
        JsonNode created = postJson(platform, "/api/v1/platform/master/equipment",
                "{\"code\":\"" + code + "\",\"labelEn\":\"" + labelEn + "\",\"labelAr\":\"" + labelAr
                        + "\",\"sortOrder\":" + sortOrder + "}");
        return new EquipmentRef(UUID.fromString(created.get("id").asText()), code, labelEn, labelAr,
                sortOrder, "ACTIVE");
    }

    private void assertEquipmentItem(JsonNode item, EquipmentRef expected) {
        assertThat(item.get("equipmentId").asText()).isEqualTo(expected.id().toString());
        assertThat(item.get("code").asText()).isEqualTo(expected.code());
        assertThat(item.get("labelEn").asText()).isEqualTo(expected.labelEn());
        assertThat(item.get("labelAr").asText()).isEqualTo(expected.labelAr());
        assertThat(item.get("status").asText()).isEqualTo(expected.status());
        assertThat(item.get("sortOrder").asInt()).isEqualTo(expected.sortOrder());
    }

    private Set<UUID> uuids(JsonNode array) {
        Set<UUID> values = new LinkedHashSet<>();
        array.forEach(value -> values.add(UUID.fromString(value.asText())));
        return values;
    }

    private void assertTechnicianForbidden(Login login, String path, String method) throws Exception {
        var request = switch (method) {
            case "POST" -> post(path)
                    .header("Authorization", "Bearer " + login.accessToken())
                    .header("Idempotency-Key", "role-check")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{}");
            case "PUT" -> put(path)
                    .header("Authorization", "Bearer " + login.accessToken())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{}");
            default -> get(path)
                    .header("Authorization", "Bearer " + login.accessToken());
        };
        mockMvc.perform(request).andExpect(status().isForbidden());
    }

    private String startItemId(Login login, String jobId) throws Exception {
        JsonNode checklist = getJson(login, "/api/v1/technician/legacy/jobs/" + jobId + "/checklist");
        return checklist.get("items").get(0).get("inspectionItemId").asText();
    }

    private void customer(Login login, String jobId, String name, String phone, String email) throws Exception {
        mockMvc.perform(put("/api/v1/technician/legacy/jobs/" + jobId + "/customer")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"customerName\":\"" + name + "\",\"customerPhone\":\"" + phone
                                + "\",\"customerEmail\":\"" + email + "\"}"))
                .andExpect(status().isOk());
    }

    private void vehicle(Login login, String jobId, String make, String model, int year,
                         String vin, String plate, int odometer, String unit) throws Exception {
        mockMvc.perform(put("/api/v1/technician/legacy/jobs/" + jobId + "/vehicle")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"vehicleMake\":\"" + make + "\",\"vehicleModel\":\"" + model
                                + "\",\"vehicleYear\":" + year + ",\"vehicleVin\":\"" + vin
                                + "\",\"vehiclePlate\":\"" + plate + "\",\"odometerValue\":" + odometer
                                + ",\"odometerUnit\":\"" + unit + "\"}"))
                .andExpect(status().isOk());
    }

    private void consent(Login login, String jobId, String type, String status) throws Exception {
        mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/consent")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"consentType\":\"" + type + "\",\"status\":\"" + status
                                + "\",\"wordingVersion\":\"v1\",\"channel\":\"IN_PERSON\"}"))
                .andExpect(status().isNoContent());
    }

    private org.springframework.test.web.servlet.ResultActions assessment(Login login, String jobId,
                                                                          String itemId, String body) throws Exception {
        return mockMvc.perform(put("/api/v1/technician/legacy/jobs/" + jobId + "/items/" + itemId + "/assessment")
                .header("Authorization", "Bearer " + login.accessToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private void assess(Login login, String jobId, String itemId, String result, String severity,
                        String note, String language, String reasonCode, String reasonText) throws Exception {
        assessment(login, jobId, itemId, assessmentBody(result, severity, note, 1,
                language, reasonCode, reasonText)).andExpect(status().isOk());
    }

    private String assessmentBody(String result, String severity, String note, long revision) {
        return assessmentBody(result, severity, note, revision, null, null, null);
    }

    private String assessmentBody(String result, String severity, String note, long revision,
                                  String language) {
        return assessmentBody(result, severity, note, revision, language, 0);
    }

    private String assessmentBody(String result, String severity, String note, long revision,
                                  String language, int baseVersion) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("baseVersion", baseVersion);
        body.put("clientRevision", revision);
        body.put("resultCode", result);
        body.put("severityCode", severity);
        body.put("note", note);
        body.put("noteLanguage", language);
        body.put("reasonCode", null);
        body.put("reasonText", null);
        try {
            return objectMapper.writeValueAsString(body);
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private String assessmentBody(String result, String severity, String note, long revision,
                                  String language, String reasonCode, String reasonText) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("baseVersion", 0);
        body.put("clientRevision", revision);
        body.put("resultCode", result);
        body.put("severityCode", severity);
        body.put("note", note);
        body.put("noteLanguage", language);
        body.put("reasonCode", reasonCode);
        body.put("reasonText", reasonText);
        try {
            return objectMapper.writeValueAsString(body);
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private JsonNode start(Login login, String jobId) throws Exception {
        return postJson(login, "/api/v1/technician/legacy/jobs/" + jobId + "/start", null);
    }

    private JsonNode finalize(Login login, String jobId, String key) throws Exception {
        var result = mockMvc.perform(post("/api/v1/technician/legacy/jobs/" + jobId + "/finalize")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .header("Idempotency-Key", key))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private UUID category(String suffix) {
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("phase5-" + suffix + "-" + UUID.randomUUID(),
                        "Phase 5 " + suffix, "Phase 5 AR " + suffix, 0, null));
        return category.id();
    }

    private MasterItem item(UUID categoryId, String code, String label, String note,
                            String evidence, int minPhotos, String applicability) {
        return item(categoryId, code, label, note, evidence, minPhotos, applicability, List.of());
    }

    private MasterItem item(UUID categoryId, String code, String label, String note,
                            String evidence, int minPhotos, String applicability,
                            List<UUID> equipmentIds) {
        ItemDetailDto detail = masterContent.createItem(platformActor(), new ItemCreateRequest(
                code, categoryId, label, "Arabic " + label, "Instruction " + label,
                "Arabic instruction " + label, true,
                List.of("NO_ISSUE_OBSERVED", "DEFECT_FOUND", "NOT_CHECKED", "NOT_APPLICABLE"),
                "{\"DEFECT_FOUND\":\"MODERATE\"}", applicability, List.of(),
                note, evidence, minPhotos, equipmentIds, null));
        UUID itemId = detail.item().id();
        UUID versionId = detail.versions().get(0).id();
        masterContent.publish(platformActor(), itemId, versionId);
        return new MasterItem(itemId, versionId);
    }

    private String template(Login login, String name, List<UUID> versionIds, String vehicleType) throws Exception {
        JsonNode created = postJson(login, "/api/v1/workshop/templates",
                "{\"name\":\"" + name + "\",\"serviceType\":\"FULL\",\"vehicleType\":\"" + vehicleType + "\"}");
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
        body.put("vehicleType", vehicleType);
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

    private String createTemplateDraftAndPublish(Login login, String templateId) throws Exception {
        postJson(login, "/api/v1/workshop/templates/" + templateId + "/draft", "{}");
        String template = getJson(login, "/api/v1/workshop/templates/" + templateId).toString();
        assertThat(template).contains("DRAFT");
        postJson(login, "/api/v1/workshop/templates/" + templateId + "/publish", "{}");
        return publishedVersion(login, templateId);
    }

    private String job(Login login, String versionId, String customer) throws Exception {
        return postJson(login, "/api/v1/workshop/legacy/jobs",
                "{\"templateVersionId\":\"" + versionId + "\",\"customerName\":\"" + customer
                        + "\",\"vehicleMake\":\"Toyota\",\"vehicleModel\":\"Camry\",\"vehicleYear\":2022,"
                        + "\"vehicleVin\":\"TESTVIN00000000001\",\"vehiclePlate\":\"A12345\","
                        + "\"scope\":\"Full inspection\"}")
                .get("id").asText();
    }

    private void assign(Login login, String jobId, UUID technicianId) throws Exception {
        postJson(login, "/api/v1/workshop/legacy/jobs/" + jobId + "/assign",
                "{\"technicianId\":\"" + technicianId + "\",\"reason\":\"Assigned\"}");
    }

    private String walkInBody(String versionId, String customer) {
        return "{\"templateVersionId\":\"" + versionId + "\",\"customerName\":\"" + customer
                + "\",\"vehicleMake\":\"Toyota\",\"vehicleModel\":\"Camry\","
                + "\"scope\":\"Walk-in inspection\"}";
    }

    private CurrentUser platformActor() {
        return new CurrentUser(fixture.platform().getId(), fixture.platform().getEmail(),
                "PLATFORM_ADMIN", null, null);
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var request = post(path)
                .header("Authorization", "Bearer " + login.accessToken());
        if (body != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(body);
        }
        var result = mockMvc.perform(request)
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

    private record MasterItem(UUID itemId, UUID versionId) {
    }

    private record EquipmentRef(UUID id, String code, String labelEn, String labelAr,
                                int sortOrder, String status) {
    }
}
