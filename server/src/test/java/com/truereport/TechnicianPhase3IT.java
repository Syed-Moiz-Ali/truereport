package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.shared.uuid.UuidV7;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

class TechnicianPhase3IT extends IntegrationTestBase {

    private static final String TECH = "/api/v1/technician";
    private static final String JOBS = "/api/v1/workshop/jobs";

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void technicianOnlySeesJobsAssignedToThemInTheirWorkshop() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Login techB = login("tech.b@test.local");
        Login platform = login("platform@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);

        JsonNode page = call(techA, get(TECH + "/jobs?page=0&size=20"), 200);
        assertThat(page.get("total").asInt()).isEqualTo(1);
        assertThat(page.get("items").get(0).get("id").asText()).isEqualTo(jobId);

        assertThat(call(techA, get(TECH + "/jobs/" + jobId), 200)
                .get("id").asText()).isEqualTo(jobId);
        assertThat(call(techB, get(TECH + "/jobs/" + jobId), 404).get("code").asText())
                .isEqualTo("JOB_NOT_FOUND");
        assertThat(call(techB, get(TECH + "/jobs"), 200).get("total").asInt()).isZero();
        assertThat(call(adminA, get(TECH + "/jobs"), 403).get("status").asInt()).isEqualTo(403);
        assertThat(call(platform, get(TECH + "/jobs"), 403).get("status").asInt()).isEqualTo(403);
    }

    @Test
    void checklistDeliversDynamicConfigurationAndPinsSnapshot() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);

        JsonNode checklist = call(techA, get(TECH + "/jobs/" + jobId + "/checklist"), 200);
        assertThat(checklist.get("categories").size()).isEqualTo(1);
        JsonNode category = checklist.get("categories").get(0);
        assertThat(category.get("code").asText()).isEqualTo(seed.categoryCode());
        assertThat(category.get("iconCode").asText()).isEqualTo(icon(seed.categoryCode()));
        assertThat(checklist.get("items").size()).isEqualTo(2);
        assertThat(checklist.get("progress").get("total").asInt()).isEqualTo(2);

        JsonNode multi = findItem(checklist, seed.itemCodeA());
        assertThat(multi.get("multiPoint").asBoolean()).isTrue();
        assertThat(multi.get("scoreBands").size()).isEqualTo(3);
        assertThat(multi.get("measurementBands").size()).isEqualTo(3);
        assertThat(multi.get("multiPointIndexes").toString()).contains("FL", "RR");

        JsonNode issue = findItem(checklist, seed.itemCodeB());
        assertThat(issue.get("issueFields").size()).isEqualTo(3);
        assertThat(issue.get("evidenceRules").size()).isEqualTo(1);
        assertThat(issue.get("evidenceRules").get(0).get("requiredEvidenceType").asText())
                .isEqualTo("DOCUMENT");
        assertThat(issue.get("resultOptions").toString())
                .contains("ATTENTION_RECOMMENDED", "DEFECT_FOUND");

        String hash = checklist.get("pinned").get("snapshotHash").asText();
        assertThat(hash).hasSize(64);
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_job_checklists WHERE job_id = ?",
                Integer.class, jobId)).isEqualTo(1);
        JsonNode second = call(techA, get(TECH + "/jobs/" + jobId + "/checklist"), 200);
        assertThat(second.get("pinned").get("snapshotHash").asText()).isEqualTo(hash);
    }

    @Test
    void measurementDrivesBandAndScoreOverrideMustStayInsideBand() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "PHOTO", 1);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "VIDEO", 1);

        JsonNode saved = putAssessment(techA, jobId, seed.itemCodeA(),
                assessmentBody(0, "ATTENTION_RECOMMENDED", 70,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4")), 200);
        assertThat(saved.get("suggestedResultCode").asText())
                .isEqualTo("ATTENTION_RECOMMENDED");
        assertThat(saved.get("bandResultCode").asText()).isEqualTo("ATTENTION_RECOMMENDED");
        assertThat(saved.get("measurements").size()).isEqualTo(2);

        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA())
                .contentType(MediaType.APPLICATION_JSON)
                .content(assessmentBody(0, "NO_ISSUE_OBSERVED", 100,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4"))), 422);

        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA())
                .contentType(MediaType.APPLICATION_JSON)
                .content(assessmentBody(0, "ATTENTION_RECOMMENDED", 10,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4"))), 422);

        JsonNode override = putAssessment(techA, jobId, seed.itemCodeA(),
                assessmentBody(0, "ATTENTION_RECOMMENDED", 75,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4")), 200);
        assertThat(override.get("score").asInt()).isEqualTo(75);
        assertThat(override.get("suggestedScore").asInt()).isEqualTo(70);
    }

    @Test
    void multiPointUsesWorstMeasurementResult() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "PHOTO", 2);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "VIDEO", 1);

        JsonNode saved = putAssessment(techA, jobId, seed.itemCodeA(),
                assessmentBody(0, "DEFECT_FOUND", 30,
                        measurements("MEASUREMENT", "MM",
                                "FL", "6.0", "FR", "4.2", "RL", "2.0", "RR", "5.8")), 200);
        assertThat(saved.get("resultCode").asText()).isEqualTo("DEFECT_FOUND");
        assertThat(saved.get("suggestedResultCode").asText()).isEqualTo("DEFECT_FOUND");
        assertThat(saved.get("measurements").size()).isEqualTo(4);

        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA())
                .contentType(MediaType.APPLICATION_JSON)
                .content(assessmentBody(0, "ATTENTION_RECOMMENDED", 70,
                        measurements("MEASUREMENT", "MM",
                                "FL", "6.0", "FR", "4.2", "RL", "2.0", "RR", "5.8"))), 422);
    }

    @Test
    void issueValuesDependenciesRequiredForStatusAndNotesAreValidated() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);
        seedEvidence(jobId, seed.itemCodeB(), seed.itemVersionB(), "PHOTO", 1);
        seedEvidence(jobId, seed.itemCodeB(), seed.itemVersionB(), "VIDEO", 1);
        seedEvidence(jobId, seed.itemCodeB(), seed.itemVersionB(), "DOCUMENT", 1);

        JsonNode saved = putAssessment(techA, jobId, seed.itemCodeB(),
                issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_LEFT", "PAD", "WORN",
                        "This is a long note"), 200);
        assertThat(saved.get("issueValues").size()).isEqualTo(3);

        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeB())
                .contentType(MediaType.APPLICATION_JSON)
                .content(issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_RIGHT", "PAD",
                        "WORN", "This is a long note")), 422);
        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeB())
                .contentType(MediaType.APPLICATION_JSON)
                .content(issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_LEFT", null,
                        null, "This is a long note")), 422);
        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeB())
                .contentType(MediaType.APPLICATION_JSON)
                .content(issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_LEFT", "PAD",
                        "WORN", "bad")), 422);
        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeB())
                .contentType(MediaType.APPLICATION_JSON)
                .content(issueBodyWithUnknownField(0)), 422);

        String itemAJob = createJob(adminA, seed);
        seedEvidence(itemAJob, seed.itemCodeA(), seed.itemVersionA(), "PHOTO", 1);
        seedEvidence(itemAJob, seed.itemCodeA(), seed.itemVersionA(), "VIDEO", 1);
        JsonNode problem = call(techA, put(TECH + "/jobs/" + itemAJob + "/items/"
                + seed.itemCodeA()).contentType(MediaType.APPLICATION_JSON)
                .content(assessmentBodyWithNotes(0, "ATTENTION_RECOMMENDED", 70,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4"),
                        "not allowed")), 422);
        assertThat(problem.get("errors").toString()).contains("NOTES_NOT_ALLOWED");
    }

    @Test
    void evidenceLifecycleSupportsPhotoVideoAndDocument() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);

        byte[] photo = bytes(1200, 1);
        JsonNode photoAsset = initEvidence(techA, jobId, seed.itemCodeA(), "PHOTO",
                "image/jpeg", photo, "CAMERA", 800, 600, null);
        String photoId = photoAsset.get("id").asText();
        assertThat(photoAsset.get("status").asText()).isEqualTo("PENDING");
        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/" + photoId + "/content")
                .contentType(MediaType.APPLICATION_OCTET_STREAM).content(photo), 200);
        JsonNode completedPhoto = call(techA, post(TECH + "/jobs/" + jobId + "/items/"
                + seed.itemCodeA() + "/evidence/" + photoId + "/complete")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"captionEn\":\"Front pad\",\"captionAr\":\"وسادة أمامية\"}"), 200);
        assertThat(completedPhoto.get("status").asText()).isEqualTo("VERIFIED");
        assertThat(completedPhoto.get("capturedAt").asText()).isNotBlank();

        byte[] content = mockMvc.perform(get(TECH + "/jobs/" + jobId + "/items/"
                        + seed.itemCodeA() + "/evidence/" + photoId + "/content")
                        .header("Authorization", "Bearer " + techA.accessToken()))
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(content).isEqualTo(photo);

        byte[] video = bytes(2200, 2);
        JsonNode videoAsset = initEvidence(techA, jobId, seed.itemCodeA(), "VIDEO",
                "video/mp4", video, "CAMERA", 1280, 720, 20000L);
        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/" + videoAsset.get("id").asText() + "/content")
                .contentType(MediaType.APPLICATION_OCTET_STREAM).content(video), 200);
        call(techA, post(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/" + videoAsset.get("id").asText() + "/complete")
                .contentType(MediaType.APPLICATION_JSON).content("{}"), 200);

        byte[] document = bytes(1500, 3);
        JsonNode documentAsset = initEvidence(techA, jobId, seed.itemCodeA(), "DOCUMENT",
                "application/pdf", document, "FILE", null, null, null);
        call(techA, put(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/" + documentAsset.get("id").asText() + "/content")
                .contentType(MediaType.APPLICATION_OCTET_STREAM).content(document), 200);
        call(techA, post(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/" + documentAsset.get("id").asText() + "/complete")
                .contentType(MediaType.APPLICATION_JSON).content("{}"), 200);

        assertThat(call(techA, get(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence"), 200).size()).isEqualTo(3);

        call(techA, post(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/init").contentType(MediaType.APPLICATION_JSON)
                .content(evidenceInitBody("PHOTO", "image/jpeg", photo, "FILE", 800, 600,
                        null)), 422);
        JsonNode duplicate = call(techA, post(TECH + "/jobs/" + jobId + "/items/"
                + seed.itemCodeA() + "/evidence/init")
                .contentType(MediaType.APPLICATION_JSON)
                .content(evidenceInitBody("PHOTO", "image/jpeg", photo, "CAMERA", 800, 600,
                        null)), 409);
        assertThat(duplicate.get("code").asText()).isEqualTo("DUPLICATE_EVIDENCE");

        call(techA, delete(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence/" + documentAsset.get("id").asText()), 204);
        assertThat(call(techA, get(TECH + "/jobs/" + jobId + "/items/" + seed.itemCodeA()
                + "/evidence"), 200).size()).isEqualTo(2);
    }

    @Test
    void evidenceRulesBlockSaveUntilRequirementsAreMet() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "PHOTO", 1);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "VIDEO", 1);

        JsonNode defect = call(techA, put(TECH + "/jobs/" + jobId + "/items/"
                + seed.itemCodeA()).contentType(MediaType.APPLICATION_JSON)
                .content(assessmentBody(0, "DEFECT_FOUND", 30,
                        measurements("MEASUREMENT", "MM", "FL", "2.0", "FR", "4.2"))), 422);
        assertThat(defect.get("errors").toString()).contains("EVIDENCE_RULE_NOT_MET");

        String emptyJob = createJob(adminA, seed);
        JsonNode noEvidence = call(techA, put(TECH + "/jobs/" + emptyJob + "/items/"
                + seed.itemCodeA()).contentType(MediaType.APPLICATION_JSON)
                .content(assessmentBody(0, "ATTENTION_RECOMMENDED", 70,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4"))), 422);
        assertThat(noEvidence.get("errors").toString()).contains("EVIDENCE_RULE_NOT_MET");

        String issueJob = createJob(adminA, seed);
        seedEvidence(issueJob, seed.itemCodeB(), seed.itemVersionB(), "PHOTO", 1);
        seedEvidence(issueJob, seed.itemCodeB(), seed.itemVersionB(), "VIDEO", 1);
        JsonNode missingDocument = call(techA, put(TECH + "/jobs/" + issueJob + "/items/"
                + seed.itemCodeB()).contentType(MediaType.APPLICATION_JSON)
                .content(issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_LEFT", "PAD",
                        "WORN", "This is a long note")), 422);
        assertThat(missingDocument.get("errors").toString())
                .contains("EVIDENCE_TYPE_REQUIRED");

        seedEvidence(issueJob, seed.itemCodeB(), seed.itemVersionB(), "DOCUMENT", 1);
        JsonNode shortNote = call(techA, put(TECH + "/jobs/" + issueJob + "/items/"
                + seed.itemCodeB()).contentType(MediaType.APPLICATION_JSON)
                .content(issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_LEFT", "PAD",
                        "WORN", "bad")), 422);
        assertThat(shortNote.get("errors").toString()).contains("NOTES_MIN_LENGTH");
    }

    @Test
    void signatureAndCompleteMoveJobToPendingReview() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "PHOTO", 1);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "VIDEO", 1);
        seedEvidence(jobId, seed.itemCodeB(), seed.itemVersionB(), "PHOTO", 1);
        seedEvidence(jobId, seed.itemCodeB(), seed.itemVersionB(), "VIDEO", 1);
        seedEvidence(jobId, seed.itemCodeB(), seed.itemVersionB(), "DOCUMENT", 1);

        putAssessment(techA, jobId, seed.itemCodeA(),
                assessmentBody(0, "ATTENTION_RECOMMENDED", 70,
                        measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4")), 200);
        putAssessment(techA, jobId, seed.itemCodeB(),
                issueBody(0, "ATTENTION_RECOMMENDED", 70, "FRONT_LEFT", "PAD", "WORN",
                        "This is a long note"), 200);

        JsonNode signature = call(techA, post(TECH + "/jobs/" + jobId + "/signature")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"signerName\":\"Technician A\",\"deviceId\":\"device-1\","
                        + "\"method\":\"DRAWN\",\"signatureBase64\":\""
                        + java.util.Base64.getEncoder().encodeToString(
                                "signature".getBytes(StandardCharsets.UTF_8)) + "\"}"), 200);
        assertThat(signature.get("signatureHash").asText()).hasSize(64);

        JsonNode completed = call(techA, post(TECH + "/jobs/" + jobId + "/complete")
                .contentType(MediaType.APPLICATION_JSON).content("{}"), 200);
        assertThat(completed.get("status").asText()).isEqualTo("PENDING_REVIEW");
        assertThat(completed.get("score").asInt()).isEqualTo(70);
        assertThat(completed.get("gradeCode").asText()).isEqualTo("C");

        assertThat(jdbc.queryForObject("""
                SELECT status FROM platform_jobs WHERE id = ?
                """, String.class, jobId)).isEqualTo("PENDING_REVIEW");
        assertThat(jdbc.queryForObject("""
                SELECT review_status FROM platform_jobs WHERE id = ?
                """, String.class, jobId)).isEqualTo("PENDING_REVIEW");
        assertThat(jdbc.queryForObject("""
                SELECT assessment_state FROM platform_jobs WHERE id = ?
                """, String.class, jobId)).isEqualTo("COMPLETED");
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_job_results WHERE job_id = ?
                """, Integer.class, jobId)).isEqualTo(2);
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_job_status_history
                WHERE job_id = ? AND to_status = 'PENDING_REVIEW'
                """, Integer.class, jobId)).isGreaterThan(0);
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_outbox_events
                WHERE aggregate_id = ? AND event_type = 'JOB_COMPLETED'
                """, Integer.class, jobId)).isEqualTo(1);
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_notifications
                WHERE user_id = ? AND type = 'JOB_COMPLETED'
                """, Integer.class, fixture.adminA().getId().toString())).isGreaterThan(0);

        String blockedJob = createJob(adminA, seed);
        JsonNode problem = call(techA, post(TECH + "/jobs/" + blockedJob + "/complete")
                .contentType(MediaType.APPLICATION_JSON).header("Accept-Language", "ar")
                .content("{}"), 422);
        assertThat(problem.get("code").asText()).isEqualTo("COMPLETION_BLOCKED");
        assertThat(problem.get("messageAr").asText()).isNotBlank();

        JsonNode arabicNotFound = call(techA, get(TECH + "/jobs/" + UUID.randomUUID())
                .header("Accept-Language", "ar"), 404);
        assertThat(arabicNotFound.get("messageAr").asText()).contains("غير موجود");
    }

    @Test
    void staleBaseVersionReturnsConflictAndSyncReplaysIt() throws Exception {
        Login adminA = login("admin.a@test.local");
        Login techA = login("tech.a@test.local");
        Seed seed = seedTemplate();
        String jobId = createJob(adminA, seed);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "PHOTO", 1);
        seedEvidence(jobId, seed.itemCodeA(), seed.itemVersionA(), "VIDEO", 1);

        String body = assessmentBody(0, "ATTENTION_RECOMMENDED", 70,
                measurements("MEASUREMENT", "MM", "FL", "4.2", "FR", "4.4"));
        putAssessment(techA, jobId, seed.itemCodeA(), body, 200);
        putAssessment(techA, jobId, seed.itemCodeA(), body, 200);
        JsonNode conflict = call(techA, put(TECH + "/jobs/" + jobId + "/items/"
                + seed.itemCodeA()).contentType(MediaType.APPLICATION_JSON)
                .content(body), 409);
        assertThat(conflict.get("code").asText()).isEqualTo("SYNC_CONFLICT");
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_sync_conflicts WHERE job_id = ?
                """, Integer.class, jobId)).isGreaterThan(0);

        JsonNode syncConflict = call(techA, post(TECH + "/jobs/" + jobId + "/sync")
                .contentType(MediaType.APPLICATION_JSON)
                .content(syncBody(seed, 0, "mutation-1")), 200);
        assertThat(syncConflict.get("conflicts").size()).isEqualTo(1);
        assertThat(syncConflict.get("applied").size()).isZero();

        JsonNode applied = call(techA, post(TECH + "/jobs/" + jobId + "/sync")
                .contentType(MediaType.APPLICATION_JSON)
                .content(syncBody(seed, 1, "mutation-2")), 200);
        assertThat(applied.get("applied").size()).isEqualTo(1);
        assertThat(applied.get("conflicts").size()).isZero();

        JsonNode replayed = call(techA, post(TECH + "/jobs/" + jobId + "/sync")
                .contentType(MediaType.APPLICATION_JSON)
                .content(syncBody(seed, 1, "mutation-2")), 200);
        assertThat(replayed.get("applied").size()).isEqualTo(1);
    }

    // ---------------------------------------------------------------- helpers

    private record Seed(String templateVersionId, String itemVersionA, String itemCodeA,
                        String itemVersionB, String itemCodeB, String categoryCode) {
    }

    private Seed seedTemplate() {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String categoryId = UuidV7.generate().toString();
        String categoryCode = "TECH-CAT-" + suffix;
        String itemAId = UuidV7.generate().toString();
        String itemBId = UuidV7.generate().toString();
        String versionA = UuidV7.generate().toString();
        String versionB = UuidV7.generate().toString();
        String templateId = UuidV7.generate().toString();
        String templateVersionId = UuidV7.generate().toString();
        String itemCodeA = "MP-" + suffix;
        String itemCodeB = "ISSUE-" + suffix;

        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 100, 'ACTIVE', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, categoryId, categoryCode, "Technician Category " + suffix);

        insertItem(itemAId, versionA, categoryId, itemCodeA, "Multi Point " + suffix, true,
                true, false, null, 1);
        insertItem(itemBId, versionB, categoryId, itemCodeB, "Issue Item " + suffix, false,
                false, true, null, 2);

        insertScoreBands(versionA);
        insertScoreBands(versionB);
        insertMeasureBand(versionA, "MEASUREMENT", "MM", "HIGHER_IS_BETTER", "0", "2.99",
                "DEFECT_FOUND", 30, "Below minimum", 1);
        insertMeasureBand(versionA, "MEASUREMENT", "MM", "HIGHER_IS_BETTER", "3.0", "5.49",
                "ATTENTION_RECOMMENDED", 70, "Worn", 2);
        insertMeasureBand(versionA, "MEASUREMENT", "MM", "HIGHER_IS_BETTER", "5.5", "999",
                "NO_ISSUE_OBSERVED", 100, "Within specification", 3);
        insertEvidenceRule(versionA, "DEFECT_FOUND", 2, 1, 0, null);
        insertEvidenceRule(versionB, "ATTENTION_RECOMMENDED", 1, 1, 10, "DOCUMENT");

        String locSet = insertOptionSet("LOC-" + suffix, "Location", "الموقع");
        insertOptionValue(locSet, "FRONT_LEFT", "Front Left", "أمامي أيسر", 1);
        insertOptionValue(locSet, "FRONT_RIGHT", "Front Right", "أمامي أيمن", 2);
        String compSet = insertOptionSet("COMP-" + suffix, "Component", "الجزء");
        insertOptionValue(compSet, "PAD", "Brake Pad", "قماش الفرامل", 1);
        String issueSet = insertOptionSet("ISSUE-" + suffix, "Issue Type", "نوع العطل");
        insertOptionValue(issueSet, "WORN", "Worn", "متآكل", 1);

        insertIssueField(versionB, "LOCATION", "Location", "الموقع", "SELECT", locSet,
                true, null, null, null, 0, null, null, false, false, 1);
        insertIssueField(versionB, "COMPONENT", "Component", "الجزء", "SELECT", compSet,
                true, null, null, null, 0, "LOCATION", "FRONT_LEFT", false, false, 2);
        insertIssueField(versionB, "ISSUE_TYPE", "Issue Type", "نوع العطل", "SELECT",
                issueSet, false, "[\"ATTENTION_RECOMMENDED\",\"DEFECT_FOUND\"]", null, null,
                0, null, null, false, false, 3);

        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name, status, current_published_version_id,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 'ACTIVE', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, templateId, "TECH-TPL-" + suffix,
                "Technician Template " + suffix);
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at, published_by,
                     created_at, updated_at)
                VALUES (?, ?, 1, 'PUBLISHED', CURRENT_TIMESTAMP, NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, templateVersionId, templateId);
        jdbc.update("UPDATE platform_templates SET current_published_version_id = ? WHERE id = ?",
                templateVersionId, templateId);
        insertTemplateItem(templateVersionId, versionA, 1);
        insertTemplateItem(templateVersionId, versionB, 2);
        insertScoringRule();
        return new Seed(templateVersionId, versionA, itemCodeA, versionB, itemCodeB,
                categoryCode);
    }

    private void insertItem(String itemId, String versionId, String categoryId, String code,
                            String label, boolean safetyCritical, boolean multiPoint,
                            boolean allowFreeTextNote, String unit, int sortOrder) {
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id,
                     sample_data, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'PUBLISHED', NULL, FALSE, ?, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, itemId, code, categoryId, sortOrder);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction,
                     measurement_unit, safety_critical, multi_point,
                     allow_free_text_note, result_options_json, note_requirement,
                     evidence_requirement, min_photos, created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', ?, ?, ?, ?, ?, ?,
                        '["NO_ISSUE_OBSERVED","ATTENTION_RECOMMENDED","DEFECT_FOUND"]',
                        'OPTIONAL', 'REQUIRED', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, versionId, itemId, label, "Instruction " + label,
                unit, safetyCritical, multiPoint, allowFreeTextNote);
        jdbc.update("UPDATE platform_items SET current_published_version_id = ? WHERE id = ?",
                versionId, itemId);
    }

    private void insertTemplateItem(String templateVersionId, String itemVersionId, int order) {
        jdbc.update("""
                INSERT INTO platform_template_items
                    (id, template_version_id, item_version_id, sort_order, included)
                VALUES (?, ?, ?, ?, TRUE)
                """, UuidV7.generate().toString(), templateVersionId, itemVersionId, order);
    }

    private void insertScoreBands(String versionId) {
        insertScoreBand(versionId, "NO_ISSUE_OBSERVED", 90, 100, 100, 1);
        insertScoreBand(versionId, "ATTENTION_RECOMMENDED", 60, 89, 70, 2);
        insertScoreBand(versionId, "DEFECT_FOUND", 0, 59, 30, 3);
    }

    private void insertScoreBand(String versionId, String result, int min, int max,
                                 int defaultScore, int order) {
        jdbc.update("""
                INSERT INTO platform_score_bands
                    (id, item_version_id, result_code, min_score, max_score, default_score,
                     criteria, sort_order, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), versionId, result, min, max, defaultScore,
                "Criteria " + result, order);
    }

    private void insertMeasureBand(String versionId, String fieldCode, String unit,
                                   String direction, String min, String max, String result,
                                   int defaultScore, String label, int order) {
        jdbc.update("""
                INSERT INTO platform_measurement_bands
                    (id, item_version_id, field_code, unit_code, direction, min_value,
                     max_value, result_code, default_score, label, sort_order,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), versionId, fieldCode, unit, direction,
                new java.math.BigDecimal(min), new java.math.BigDecimal(max), result,
                defaultScore, label, order);
    }

    private void insertEvidenceRule(String versionId, String result, int photos, int videos,
                                    int notes, String requiredType) {
        jdbc.update("""
                INSERT INTO platform_evidence_rules
                    (id, item_version_id, result_code, min_photos, min_videos, min_notes_chars,
                     required_evidence_type, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), versionId, result, photos, videos, notes,
                requiredType);
    }

    private String insertOptionSet(String code, String nameEn, String nameAr) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_option_sets
                    (id, code, name, status, sort_order, created_at, updated_at,
                     version)
                VALUES (?, ?, ?, 'ACTIVE', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, nameEn);
        return id;
    }

    private void insertOptionValue(String optionSetId, String code, String labelEn,
                                   String labelAr, int order) {
        jdbc.update("""
                INSERT INTO platform_option_values
                    (id, option_set_id, code, label, status, sort_order,
                     metadata_json, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', ?, NULL, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, UuidV7.generate().toString(), optionSetId, code, labelEn, order);
    }

    private void insertIssueField(String versionId, String fieldCode, String labelEn,
                                  String labelAr, String inputType, String optionSetId,
                                  boolean required, String requiredForStatuses, String min,
                                  String max, int decimalPlaces, String dependsOnField,
                                  String dependsOnValue, boolean allowMultiple,
                                  boolean allowFreeText, int order) {
        jdbc.update("""
                INSERT INTO platform_issue_fields
                    (id, item_version_id, field_code, label, input_type,
                     option_set_id, unit_set_id, is_required, required_for_statuses_json,
                     min_value, max_value, decimal_places, depends_on_field_code,
                     depends_on_value_code, allow_multiple, allow_free_text, sort_order,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), versionId, fieldCode, labelEn,
                inputType, optionSetId, required, requiredForStatuses,
                min == null ? null : new java.math.BigDecimal(min),
                max == null ? null : new java.math.BigDecimal(max), decimalPlaces,
                dependsOnField, dependsOnValue, allowMultiple, allowFreeText, order);
    }

    private void insertScoringRule() {
        String ruleId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_scoring_rules
                    (id, code, name, active, category_weight_mode,
                     hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval,
                     created_at, updated_at, version)
                VALUES (?, ?, 'Technician scoring', TRUE, 'CONFIGURED',
                        TRUE, 'B', FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, ruleId, "TECH-SCORE-" + UUID.randomUUID());
        insertBoundary(ruleId, "A", 90, 100, 1);
        insertBoundary(ruleId, "B", 75, 89, 2);
        insertBoundary(ruleId, "C", 60, 74, 3);
        insertBoundary(ruleId, "D", 0, 59, 4);
    }

    private void insertBoundary(String ruleId, String grade, int min, int max, int order) {
        jdbc.update("""
                INSERT INTO platform_grade_boundaries
                    (id, scoring_rule_id, grade_code, min_score, max_score, label,
                     sort_order, approved, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), ruleId, grade, min, max, "Grade " + grade, order);
    }

    private void seedEvidence(String jobId, String itemCode, String itemVersionId, String type,
                              int count) {
        for (int i = 0; i < count; i++) {
            String sha = UUID.randomUUID().toString().replace("-", "")
                    + UUID.randomUUID().toString().replace("-", "");
            String mime = switch (type) {
                case "VIDEO" -> "video/mp4";
                case "DOCUMENT" -> "application/pdf";
                default -> "image/jpeg";
            };
            jdbc.update("""
                    INSERT INTO platform_evidence_assets
                        (id, job_id, item_version_id, item_code, assessment_id, type, status,
                         storage_key, normalized_key, mime, bytes, sha256, captured_at,
                         capture_source, device_id, width, height, duration_ms, poster_key,
                         caption_en, caption_ar, quality_status, quality_json, uploaded_by,
                         deleted_at, deleted_by, created_at, updated_at, version)
                    VALUES (?, ?, ?, ?, NULL, ?, 'VERIFIED', ?, NULL, ?, 1000, ?,
                            CURRENT_TIMESTAMP, 'CAMERA', 'test-device', 800, 600, ?, NULL,
                            NULL, NULL, 'PASS', NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP,
                            CURRENT_TIMESTAMP, 0)
                    """, UuidV7.generate().toString(), jobId, itemVersionId, itemCode, type,
                    "test-evidence/" + jobId + "/" + UuidV7.generate(), mime, sha,
                    "VIDEO".equals(type) ? 20000L : null);
        }
    }

    private String createJob(Login admin, Seed seed) throws Exception {
        String body = """
                {"templateVersionId":"%s","customerName":"Customer",
                 "customerPhone":"+971500000000","customerEmail":"customer@test.local",
                 "vehicleVin":"1HGCM82633A004352","vehicleMake":"Toyota",
                 "vehicleModel":"Camry","vehicleYear":2022,"vehiclePlate":"A12345",
                 "odometerValue":12000,"odometerUnit":"KM","transmission":"AUTOMATIC",
                 "fuelType":"PETROL","preferredLanguage":"en",
                 "scheduledAt":"2026-11-20T09:00:00","consentGranted":true,
                 "assignedTechnicianId":"%s"}
                """.formatted(seed.templateVersionId(), fixture.techA().getId());
        JsonNode created = call(admin, post(JOBS).contentType(MediaType.APPLICATION_JSON)
                .content(body), 201);
        return created.get("id").asText();
    }

    private JsonNode putAssessment(Login login, String jobId, String itemCode, String body,
                                   int status) throws Exception {
        return call(login, put(TECH + "/jobs/" + jobId + "/items/" + itemCode)
                .contentType(MediaType.APPLICATION_JSON).content(body), status);
    }

    private String assessmentBody(int baseVersion, String result, int score, String measurements) {
        return """
                {"baseVersion":%d,"clientRevision":1,"resultCode":"%s","score":%d,
                 "measurements":%s}
                """.formatted(baseVersion, result, score, measurements);
    }

    private String assessmentBodyWithNotes(int baseVersion, String result, int score,
                                           String measurements, String notes) {
        return """
                {"baseVersion":%d,"clientRevision":1,"resultCode":"%s","score":%d,
                 "notesEn":"%s","measurements":%s}
                """.formatted(baseVersion, result, score, notes, measurements);
    }

    private String measurements(String field, String unit, String... pairs) {
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < pairs.length; i += 2) {
            if (i > 0) {
                json.append(',');
            }
            json.append("{\"fieldCode\":\"").append(field)
                    .append("\",\"valueIndex\":\"").append(pairs[i])
                    .append("\",\"numericValue\":").append(pairs[i + 1])
                    .append(",\"unitCode\":\"").append(unit).append("\"}");
        }
        return json.append(']').toString();
    }

    private String issueBody(int baseVersion, String result, int score, String location,
                             String component, String issueType, String notes) {
        StringBuilder values = new StringBuilder("[");
        if (location != null) {
            values.append("{\"fieldCode\":\"LOCATION\",\"optionValueCode\":\"")
                    .append(location).append("\"}");
        }
        if (component != null) {
            if (values.length() > 1) {
                values.append(',');
            }
            values.append("{\"fieldCode\":\"COMPONENT\",\"optionValueCode\":\"")
                    .append(component).append("\"}");
        }
        if (issueType != null) {
            if (values.length() > 1) {
                values.append(',');
            }
            values.append("{\"fieldCode\":\"ISSUE_TYPE\",\"optionValueCode\":\"")
                    .append(issueType).append("\"}");
        }
        values.append(']');
        return """
                {"baseVersion":%d,"clientRevision":1,"resultCode":"%s","score":%d,
                 "notesEn":"%s","issueValues":%s}
                """.formatted(baseVersion, result, score, notes, values);
    }

    private String issueBodyWithUnknownField(int baseVersion) {
        return """
                {"baseVersion":%d,"clientRevision":1,"resultCode":"ATTENTION_RECOMMENDED",
                 "score":70,"notesEn":"This is a long note","issueValues":[
                   {"fieldCode":"LOCATION","optionValueCode":"FRONT_LEFT"},
                   {"fieldCode":"COMPONENT","optionValueCode":"PAD"},
                   {"fieldCode":"ISSUE_TYPE","optionValueCode":"WORN"},
                   {"fieldCode":"BOGUS","optionValueCode":"NOPE"}]}
                """.formatted(baseVersion);
    }

    private String syncBody(Seed seed, int baseVersion, String idempotencyKey) {
        return """
                {"clientRevision":1,"mutations":[
                  {"idempotencyKey":"%s","itemCode":"%s","baseVersion":%d,
                   "clientRevision":1,"resultCode":"ATTENTION_RECOMMENDED","score":70,
                   "measurements":[{"fieldCode":"MEASUREMENT","valueIndex":"FL",
                     "numericValue":4.2,"unitCode":"MM"},
                     {"fieldCode":"MEASUREMENT","valueIndex":"FR",
                     "numericValue":4.4,"unitCode":"MM"}]}]}
                """.formatted(idempotencyKey, seed.itemCodeA(), baseVersion);
    }

    private JsonNode initEvidence(Login login, String jobId, String itemCode, String type,
                                  String mime, byte[] bytes, String source, Integer width,
                                  Integer height, Long durationMs) throws Exception {
        return call(login, post(TECH + "/jobs/" + jobId + "/items/" + itemCode
                + "/evidence/init").contentType(MediaType.APPLICATION_JSON)
                .content(evidenceInitBody(type, mime, bytes, source, width, height,
                        durationMs)), 201);
    }

    private String evidenceInitBody(String type, String mime, byte[] bytes, String source,
                                    Integer width, Integer height, Long durationMs) {
        return """
                {"type":"%s","mime":"%s","bytes":%d,"sha256":"%s","capturedAt":"%s",
                 "captureSource":"%s","deviceId":"device-1"%s%s%s}
                """.formatted(type, mime, bytes.length, sha256(bytes),
                LocalDateTime.now(ZoneOffset.UTC), source,
                width == null ? "" : ",\"width\":" + width,
                height == null ? "" : ",\"height\":" + height,
                durationMs == null ? "" : ",\"durationMs\":" + durationMs);
    }

    private JsonNode findItem(JsonNode checklist, String itemCode) {
        for (JsonNode item : checklist.get("items")) {
            if (itemCode.equals(item.get("itemCode").asText())) {
                return item;
            }
        }
        throw new AssertionError("Item not found: " + itemCode);
    }

    private JsonNode call(Login login, MockHttpServletRequestBuilder request, int expected)
            throws Exception {
        var result = mockMvc.perform(request.header("Authorization",
                        "Bearer " + login.accessToken()))
                .andReturn();
        int status = result.getResponse().getStatus();
        String content = result.getResponse().getContentAsString();
        assertThat(status).as("HTTP status for " + request).isEqualTo(expected);
        if (content == null || content.isBlank()) {
            return objectMapper.nullNode();
        }
        return objectMapper.readTree(content);
    }

    private static String icon(String code) {
        return code.trim().toLowerCase(java.util.Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");
    }

    private static byte[] bytes(int length, int seed) {
        byte[] value = new byte[length];
        for (int i = 0; i < length; i++) {
            value[i] = (byte) ((i + seed) % 251);
        }
        return value;
    }

    private static String sha256(byte[] value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }
}
