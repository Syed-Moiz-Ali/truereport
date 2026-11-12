package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.jobs.PlatformJobStore;
import com.truereport.shared.uuid.UuidV7;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkshopJobAdminIT extends IntegrationTestBase {

    private static final String JOBS = "/api/v1/workshop/jobs";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    PlatformJobStore store;

    @Test
    void jobCreateListDetailUpdateAssignCancelAndTenantScoping() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login adminB = login("admin.b@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        Seed seed = seedTemplate(true);

        JsonNode created = createJob(adminA, seed, "Customer A", null);
        String jobId = created.get("id").asText();
        assertThat(created.get("status").asText()).isEqualTo("SCHEDULED");
        assertThat(created.get("templateVersionId").asText()).isEqualTo(seed.versionId());
        assertThat(created.get("templateVersionNo").asInt()).isEqualTo(1);
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_jobs WHERE id = ?", Integer.class, jobId))
                .isEqualTo(1);
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM inspection_jobs", Integer.class)).isZero();

        JsonNode page = getJson(adminA, JOBS + "?page=0&size=10&search=Toyota");
        assertThat(page.get("total").asInt()).isEqualTo(1);
        assertThat(page.get("items").get(0).get("id").asText()).isEqualTo(jobId);
        assertThat(getJson(adminA, JOBS + "/counts").get("scheduled").asInt()).isEqualTo(1);

        assertThat(getJson(adminA, JOBS + "/" + jobId).get("id").asText()).isEqualTo(jobId);
        mockMvc.perform(get(JOBS + "/" + jobId)
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(get(JOBS)
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get(JOBS)
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());

        JsonNode updated = putJson(adminA, JOBS + "/" + jobId, """
                {"customerName":"Customer A2","customerPhone":"+971500000001",
                 "customerEmail":"a2@test.local","vehicleVin":"1HGCM82633A004352",
                 "vehicleMake":"Toyota","vehicleModel":"Corolla","vehicleYear":2023,
                 "vehiclePlate":"B54321","odometerValue":13000,"odometerUnit":"KM",
                 "transmission":"AUTOMATIC","fuelType":"PETROL","preferredLanguage":"ar",
                 "version":%d}
                """.formatted(created.get("version").asInt()));
        assertThat(updated.get("customerName").asText()).isEqualTo("Customer A2");
        assertThat(updated.get("preferredLanguage").asText()).isEqualTo("ar");

        mockMvc.perform(put(JOBS + "/" + jobId)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"customerName":"Stale","customerPhone":"+971500000001",
                                 "vehicleVin":"1HGCM82633A004352","vehicleMake":"Toyota",
                                 "vehicleModel":"Corolla","vehicleYear":2023,
                                 "vehiclePlate":"B54321","odometerValue":13000,
                                 "odometerUnit":"KM","transmission":"AUTOMATIC",
                                 "fuelType":"PETROL","preferredLanguage":"en","version":0}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("VERSION_CONFLICT"));

        mockMvc.perform(post(JOBS + "/" + jobId + "/assign")
                        .header("Authorization", "Bearer " + adminB.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"technicianId\":\"" + fixture.techA().getId() + "\"}"))
                .andExpect(status().isNotFound());

        JsonNode assigned = postJson(adminA, JOBS + "/" + jobId + "/assign",
                "{\"technicianId\":\"" + fixture.techA().getId() + "\",\"reason\":\"Assigned\"}");
        assertThat(assigned.get("status").asText()).isEqualTo("ASSIGNED");
        assertThat(assigned.get("assignedTechnicianId").asText())
                .isEqualTo(fixture.techA().getId().toString());
        JsonNode assignments = getJson(adminA, JOBS + "/" + jobId + "/assignments");
        assertThat(assignments.size()).isEqualTo(1);
        assertThat(assignments.get(0).get("technicianName").asText()).isEqualTo("Technician A");

        JsonNode cancelled = postJson(adminA, JOBS + "/" + jobId + "/cancel",
                "{\"reason\":\"Customer cancelled\"}");
        assertThat(cancelled.get("status").asText()).isEqualTo("CANCELLED");
        assertThat(cancelled.get("cancelReason").asText()).isEqualTo("Customer cancelled");
    }

    @Test
    void jobValidationTemplatePinningAndIdempotentCreate() throws Exception {
        Login adminA = login("admin.a@test.local");
        Seed seed = seedTemplate(true);

        mockMvc.perform(post(JOBS)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"templateVersionId":"%s","customerName":"",
                                 "customerPhone":"","vehicleVin":"BAD",
                                 "vehicleMake":"","vehicleModel":"","vehicleYear":1800,
                                 "vehiclePlate":"","odometerValue":-1,"odometerUnit":"",
                                 "transmission":"","fuelType":"","preferredLanguage":"xx"}
                                """.formatted(seed.versionId())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("JOB_VALIDATION_FAILED"))
                .andExpect(jsonPath("$.errors").isArray());

        String key = UUID.randomUUID().toString();
        JsonNode first = createJob(adminA, seed, "Idempotent", key);
        JsonNode second = createJob(adminA, seed, "Idempotent", key);
        assertThat(second.get("id").asText()).isEqualTo(first.get("id").asText());
        assertThat(getJson(adminA, JOBS + "/counts").get("total").asInt()).isEqualTo(1);

        Seed draft = seedTemplate(false);
        mockMvc.perform(post(JOBS)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jobBody(draft, "Draft template", null)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TEMPLATE_NOT_PUBLISHED"));
    }

    @Test
    void approvalRequiresChecklistApproverNotTechnicianAndRejectClosesJob() throws Exception {
        Login adminA = login("admin.a@test.local");
        Seed seed = seedTemplate(true);
        String jobId = createJob(adminA, seed, "Approval", null).get("id").asText();

        markPendingReview(jobId);
        insertResults(jobId, seed, "ATTENTION_RECOMMENDED", 70, 1, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);

        JsonNode checklist = getJson(adminA, JOBS + "/" + jobId + "/publish-checklist");
        assertThat(checklist.get("ready").asBoolean()).isTrue();
        assertThat(checklist.get("itemsAssessed").asInt()).isEqualTo(2);
        assertThat(checklist.get("itemsTotal").asInt()).isEqualTo(2);

        JsonNode review = getJson(adminA, JOBS + "/" + jobId + "/review");
        assertThat(review.get("findings").size()).isEqualTo(2);
        assertThat(review.get("scorePreview").asInt()).isEqualTo(83);
        assertThat(review.get("gradePreview").asText()).isEqualTo("B");

        JsonNode approved = postJson(adminA, JOBS + "/" + jobId + "/approve",
                "{\"reason\":\"Reviewed\",\"safetyCapReason\":null}");
        assertThat(approved.get("status").asText()).isEqualTo("APPROVED");
        assertThat(approved.get("reviewStatus").asText()).isEqualTo("APPROVED");
        assertThat(approved.get("score").asInt()).isEqualTo(83);
        assertThat(approved.get("gradeCode").asText()).isEqualTo("B");
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_report_versions WHERE job_id = ?",
                Integer.class, jobId)).isEqualTo(1);

        String rejectJobId = createJob(adminA, seed, "Reject", null).get("id").asText();
        markPendingReview(rejectJobId);
        insertResults(rejectJobId, seed, "ATTENTION_RECOMMENDED", 70, 1, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);
        JsonNode rejected = postJson(adminA, JOBS + "/" + rejectJobId + "/reject",
                "{\"reason\":\"Evidence incomplete\"}");
        assertThat(rejected.get("status").asText()).isEqualTo("REJECTED");
        assertThat(rejected.get("reviewStatus").asText()).isEqualTo("REJECTED");
        mockMvc.perform(post(JOBS + "/" + rejectJobId + "/approve")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("JOB_NOT_PENDING_REVIEW"));

        String selfJobId = createJob(adminA, seed, "Self approver", null).get("id").asText();
        markPendingReview(selfJobId);
        insertResults(selfJobId, seed, "NO_ISSUE_OBSERVED", 95, 1, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);
        jdbc.update("UPDATE platform_jobs SET assigned_technician_id = ? WHERE id = ?",
                fixture.adminA().getId().toString(), selfJobId);
        mockMvc.perform(post(JOBS + "/" + selfJobId + "/approve")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("APPROVER_IS_TECHNICIAN"));
    }

    @Test
    void approvalBlocksOnEvidenceAndSafetyCapExplanation() throws Exception {
        Login adminA = login("admin.a@test.local");
        Seed seed = seedTemplate(true);
        String jobId = createJob(adminA, seed, "Evidence", null).get("id").asText();
        markPendingReview(jobId);
        insertResults(jobId, seed, "DEFECT_FOUND", 95, 1, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);

        JsonNode checklist = getJson(adminA, JOBS + "/" + jobId + "/publish-checklist");
        assertThat(checklist.get("ready").asBoolean()).isFalse();
        assertThat(checklist.get("items")).anySatisfy(item -> {
            if ("EVIDENCE_RULES_MET".equals(item.get("code").asText())) {
                assertThat(item.get("passed").asBoolean()).isFalse();
            }
        });

        mockMvc.perform(post(JOBS + "/" + jobId + "/approve")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"No evidence\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("APPROVAL_CHECKLIST_INCOMPLETE"));

        insertResults(jobId, seed, "DEFECT_FOUND", 95, 2, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);
        mockMvc.perform(post(JOBS + "/" + jobId + "/approve")
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"Cap not explained\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("APPROVAL_CHECKLIST_INCOMPLETE"));

        JsonNode approved = postJson(adminA, JOBS + "/" + jobId + "/approve",
                "{\"reason\":\"Reviewed\",\"safetyCapReason\":\"Front brake pads below minimum\"}");
        assertThat(approved.get("safetyCapApplied").asBoolean()).isTrue();
        assertThat(approved.get("safetyCapReason").asText())
                .isEqualTo("Front brake pads below minimum");
        assertThat(approved.get("gradeCode").asText()).isEqualTo("B");
    }

    @Test
    void publishTokenQrDocumentsUnpublishRevokeRotateAndContent() throws Exception {
        Login adminA = login("admin.a@test.local");
        Seed seed = seedTemplate(true);
        String jobId = approvedJob(adminA, seed, "Publish");

        JsonNode link = postJson(adminA, JOBS + "/" + jobId + "/publish",
                "{\"pdfDownloadEnabled\":true}");
        assertThat(link.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(link.get("publicUrl").asText()).startsWith("http://localhost:8080/r/");
        assertThat(link.get("token").asText()).isNotBlank();
        assertThat(link.get("pdfDownloadEnabled").asBoolean()).isTrue();
        String firstToken = link.get("token").asText();

        JsonNode storedLink = getJson(adminA, JOBS + "/" + jobId + "/public-link");
        assertThat(storedLink.get("token").asText()).isEqualTo(firstToken);

        mockMvc.perform(get(JOBS + "/" + jobId + "/qr")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", MediaType.IMAGE_PNG_VALUE));

        JsonNode rotated = postJson(adminA, JOBS + "/" + jobId + "/rotate-token", "{}");
        assertThat(rotated.get("token").asText()).isNotEqualTo(firstToken);

        JsonNode documents = getJson(adminA, JOBS + "/" + jobId + "/documents");
        assertThat(documents.size()).isEqualTo(4);
        for (JsonNode document : documents) {
            assertThat(document.get("status").asText()).isEqualTo("READY");
            assertThat(document.get("language").asText()).isIn("en", "ar");
            assertThat(document.get("bytes").asInt()).isGreaterThan(0);
        }
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_outbox_events
                WHERE aggregate_type = 'REPORT_DOCUMENT'
                  AND event_type = 'REPORT_DOCUMENT_GENERATED'
                """, Integer.class)).isGreaterThan(0);
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_job_status_history
                WHERE job_id = ? AND to_status = 'PUBLISHED'
                """, Integer.class, jobId)).isGreaterThan(0);
        String documentId = documents.get(0).get("id").asText();
        var content = mockMvc.perform(get(JOBS + "/" + jobId + "/documents/"
                        + documentId + "/content")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        byte[] bytes = content.getResponse().getContentAsByteArray();
        assertThat(new String(bytes, 0, 5)).isEqualTo("%PDF-");

        JsonNode retried = postJson(adminA, JOBS + "/" + jobId
                + "/documents/" + documents.get(0).get("documentTypeCode").asText() + "/retry", "{}");
        assertThat(retried.size()).isEqualTo(2);
        assertThat(retried.get(0).get("status").asText()).isEqualTo("READY");

        JsonNode unpublished = postJson(adminA, JOBS + "/" + jobId + "/unpublish",
                "{\"reason\":\"Customer request\"}");
        assertThat(unpublished.get("status").asText()).isEqualTo("REVOKED");
        assertThat(getJson(adminA, JOBS + "/" + jobId).get("publicationStatus").asText())
                .isEqualTo("UNPUBLISHED");

        JsonNode republished = postJson(adminA, JOBS + "/" + jobId + "/publish",
                "{\"pdfDownloadEnabled\":false}");
        assertThat(republished.get("token").asText()).isNotBlank();
        assertThat(getJson(adminA, JOBS + "/" + jobId + "/documents").size()).isEqualTo(4);

        JsonNode revoked = postJson(adminA, JOBS + "/" + jobId + "/revoke",
                "{\"reason\":\"Legal hold\"}");
        assertThat(revoked.get("status").asText()).isEqualTo("REVOKED");
        assertThat(getJson(adminA, JOBS + "/" + jobId).get("publicationStatus").asText())
                .isEqualTo("REVOKED");
        mockMvc.perform(get(JOBS + "/" + jobId + "/public-link")
                        .header("Authorization", "Bearer " + adminA.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.publicUrl").doesNotExist());
    }

    @Test
    void notificationsAndLocalizedErrors() throws Exception {
        Login adminA = login("admin.a@test.local");
        Seed seed = seedTemplate(true);
        String jobId = createJob(adminA, seed, "Notify", null).get("id").asText();
        postJson(adminA, JOBS + "/" + jobId + "/assign",
                "{\"technicianId\":\"" + fixture.techA().getId() + "\"}");
        markPendingReview(jobId);
        insertResults(jobId, seed, "ATTENTION_RECOMMENDED", 70, 1, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);
        postJson(adminA, JOBS + "/" + jobId + "/approve", "{\"reason\":\"Reviewed\"}");

        JsonNode notifications = getJson(adminA, "/api/v1/workshop/notifications");
        assertThat(notifications.toString()).contains("JOB_APPROVED");
        String notificationId = notifications.get(0).get("id").asText();
        JsonNode read = postJson(adminA,
                "/api/v1/workshop/notifications/" + notificationId + "/read", "{}");
        assertThat(read.get("readAt").isNull()).isFalse();

        var result = mockMvc.perform(get(JOBS + "/" + UUID.randomUUID())
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .header("Accept-Language", "ar"))
                .andExpect(status().isNotFound())
                .andReturn();
        JsonNode problem = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(problem.get("messageAr").asText()).contains("غير موجود");
        assertThat(problem.get("detail").asText()).contains("غير موجود");
    }

    // ---------------------------------------------------------------- helpers

    private JsonNode createJob(Login login, Seed seed, String customer, String idempotencyKey)
            throws Exception {
        var request = post(JOBS)
                .header("Authorization", "Bearer " + login.accessToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(jobBody(seed, customer, null));
        if (idempotencyKey != null) {
            request = request.header("Idempotency-Key", idempotencyKey);
        }
        var result = mockMvc.perform(request).andExpect(status().isCreated()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String jobBody(Seed seed, String customer, String technicianId) {
        return """
                {"templateVersionId":"%s","customerName":"%s",
                 "customerPhone":"+971500000000","customerEmail":"customer@test.local",
                 "vehicleVin":"1HGCM82633A004352","vehicleMake":"Toyota",
                 "vehicleModel":"Camry","vehicleYear":2022,"vehiclePlate":"A12345",
                 "odometerValue":12000,"odometerUnit":"KM","transmission":"AUTOMATIC",
                 "fuelType":"PETROL","preferredLanguage":"en",
                 "scheduledAt":"2026-11-20T09:00:00","consentGranted":true%s}
                """.formatted(seed.versionId(), customer,
                technicianId == null ? "" : ",\"assignedTechnicianId\":\"" + technicianId + "\"");
    }

    private String approvedJob(Login login, Seed seed, String customer) throws Exception {
        String jobId = createJob(login, seed, customer, null).get("id").asText();
        markPendingReview(jobId);
        insertResults(jobId, seed, "ATTENTION_RECOMMENDED", 70, 1, 1,
                "NO_ISSUE_OBSERVED", 96, 1, 1);
        postJson(login, JOBS + "/" + jobId + "/approve", "{\"reason\":\"Reviewed\"}");
        return jobId;
    }

    private void markPendingReview(String jobId) {
        jdbc.update("""
                UPDATE platform_jobs
                SET status = 'PENDING_REVIEW', review_status = 'PENDING_REVIEW',
                    signature_present = TRUE, consent_granted = TRUE
                WHERE id = ?
                """, jobId);
    }

    private void insertResults(String jobId, Seed seed, String firstResult, int firstScore,
                               int firstPhotos, int firstVideos, String secondResult,
                               int secondScore, int secondPhotos, int secondVideos) {
        jdbc.update("DELETE FROM platform_job_results WHERE job_id = ?", jobId);
        store.insertResult(jobId, seed.itemVersionIds().get(0), firstResult, firstScore,
                firstPhotos, firstVideos, true, null);
        store.insertResult(jobId, seed.itemVersionIds().get(1), secondResult, secondScore,
                secondPhotos, secondVideos, true, null);
    }

    private Seed seedTemplate(boolean published) {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String categoryId = UuidV7.generate().toString();
        String itemOneId = UuidV7.generate().toString();
        String itemTwoId = UuidV7.generate().toString();
        String versionOneId = UuidV7.generate().toString();
        String versionTwoId = UuidV7.generate().toString();
        String templateId = UuidV7.generate().toString();
        String templateVersionId = UuidV7.generate().toString();
        String status = published ? "PUBLISHED" : "DRAFT";

        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name_en, name_ar, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 100, 'ACTIVE', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, categoryId, "job-cat-" + suffix, "Job Category " + suffix,
                "فئة الوظيفة " + suffix);

        insertItem(itemOneId, versionOneId, categoryId, "JOB-ITEM-A-" + suffix,
                "Front Brake Pads " + suffix, true, 1);
        insertItem(itemTwoId, versionTwoId, categoryId, "JOB-ITEM-B-" + suffix,
                "Engine Oil " + suffix, false, 2);

        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name_en, name_ar, status, current_published_version_id,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, templateId, "JOB-TPL-" + suffix, "Job Template " + suffix,
                "قالب الوظيفة " + suffix);
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at, published_by,
                     created_at, updated_at)
                VALUES (?, ?, 1, ?, CURRENT_TIMESTAMP, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, templateVersionId, templateId, status);
        jdbc.update("""
                UPDATE platform_templates SET current_published_version_id = ? WHERE id = ?
                """, templateVersionId, templateId);
        jdbc.update("""
                INSERT INTO platform_template_items
                    (id, template_version_id, item_version_id, sort_order, included)
                VALUES (?, ?, ?, 1, TRUE)
                """, UuidV7.generate().toString(), templateVersionId, versionOneId);
        jdbc.update("""
                INSERT INTO platform_template_items
                    (id, template_version_id, item_version_id, sort_order, included)
                VALUES (?, ?, ?, 2, TRUE)
                """, UuidV7.generate().toString(), templateVersionId, versionTwoId);

        insertScoring();
        insertDocumentType("RPT-A-" + suffix, "Inspection Report " + suffix, 1);
        insertDocumentType("RPT-B-" + suffix, "Certificate " + suffix, 2);

        return new Seed(templateVersionId, List.of(versionOneId, versionTwoId));
    }

    private void insertItem(String itemId, String versionId, String categoryId, String code,
                            String label, boolean safetyCritical, int sortOrder) {
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id,
                     sample_data, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'PUBLISHED', NULL, FALSE, ?, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, itemId, code, categoryId, sortOrder);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label_en, label_ar, instruction_en,
                     instruction_ar, measurement_unit, safety_critical, multi_point,
                     allow_free_text_note, note_requirement, evidence_requirement, min_photos,
                     created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', ?, ?, ?, ?, 'MM', ?, FALSE, FALSE,
                        'OPTIONAL', 'REQUIRED', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, versionId, itemId, label, "عربي " + label, "Instruction " + label,
                "تعليمات " + label, safetyCritical);
        jdbc.update("""
                UPDATE platform_items SET current_published_version_id = ? WHERE id = ?
                """, versionId, itemId);
    }

    private void insertScoring() {
        String ruleId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_scoring_rules
                    (id, code, name_en, name_ar, active, category_weight_mode,
                     hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval,
                     created_at, updated_at, version)
                VALUES (?, ?, 'Job scoring', 'تقييم الوظيفة', TRUE,
                        'CONFIGURED', TRUE, 'B', FALSE, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, ruleId, "JOB-SCORE-" + UUID.randomUUID());
        insertBoundary(ruleId, "A", 90, 100, 1);
        insertBoundary(ruleId, "B", 75, 89, 2);
        insertBoundary(ruleId, "C", 60, 74, 3);
        insertBoundary(ruleId, "D", 0, 59, 4);
    }

    private void insertBoundary(String ruleId, String grade, int min, int max, int order) {
        jdbc.update("""
                INSERT INTO platform_grade_boundaries
                    (id, scoring_rule_id, grade_code, min_score, max_score, label_en, label_ar,
                     sort_order, approved, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), ruleId, grade, min, max,
                "Grade " + grade, "الدرجة " + grade, order);
    }

    private void insertDocumentType(String code, String name, int order) {
        jdbc.update("""
                INSERT INTO platform_document_types
                    (id, code, name_en, name_ar, status, is_required, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', FALSE, ?, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, UuidV7.generate().toString(), code, name, "عربي " + name, order);
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

    private record Seed(String versionId, List<String> itemVersionIds) {
    }
}
