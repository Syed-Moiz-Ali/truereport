package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.reports.ReportGenerationJob;
import com.truereport.reports.ReportGenerationJobRepository;
import com.truereport.reports.ReportGenerationService;
import com.truereport.reports.ReportVersion;
import com.truereport.reports.ReportVersionRepository;
import com.truereport.reports.PublicShareLinkRepository;
import com.truereport.reports.ReportRepository;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.api.ItemVersionDto;
import com.truereport.masterdata.api.TranslationRequest;
import com.truereport.inspections.InspectionFinalSnapshotRepository;
import org.junit.jupiter.api.Test;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.util.ArrayList;
import java.util.LinkedHashMap;
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

class ReportIT extends IntegrationTestBase {

    @Autowired
    MasterContentService masterContent;

    @Autowired
    ReportGenerationService reportGeneration;

    @Autowired
    ReportGenerationJobRepository generationJobs;

    @Autowired
    ReportVersionRepository reportVersions;

    @Autowired
    ReportRepository reports;

    @Autowired
    PublicShareLinkRepository publicLinks;

    @Autowired
    InspectionFinalSnapshotRepository finalSnapshots;

    @Test
    void finalizedReportIsImmutableAllowlistedPublicAndRevocable() throws Exception {
        Login admin = login("admin.a@test.local");
        Login adminB = login("admin.b@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        String customerName = "Private Customer 9921";
        String customerPhone = "+971500009921";
        String customerEmail = "private.9921@example.test";
        String fullVin = "JTDBR32E720123456";
        String plate = "PRIVATE-9921";

        UUID categoryId = category("report");
        MasterItem item = item(categoryId, "REPORT-001", "Brake system check");
        String templateId = template(admin, "Report template", List.of(item.versionId()));
        String jobId = job(admin, publishedVersion(admin, templateId), customerName,
                customerPhone, customerEmail, fullVin, plate);
        assign(admin, jobId, fixture.techA().getId());
        String itemId = start(technician, jobId).get("items").get(0).get("inspectionItemId").asText();
        assess(technician, jobId, itemId, "NO_ISSUE_OBSERVED", null,
                "Long note: " + "تفاصيل فنية طويلة ".repeat(15) + "Тормозная система проверена. 制动系统已检查。");
        consent(technician, jobId);
        finalize(technician, jobId, "report-final-1");

        JsonNode queued = getJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report");
        assertThat(queued.get("generationStatus").asText()).isIn("QUEUED", "GENERATING");
        assertThat(queued.get("reportNumber").asText()).isNotBlank();

        reportGeneration.poll();

        JsonNode ready = getJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report");
        assertThat(ready.get("generationStatus").asText()).isEqualTo("READY");
        assertThat(ready.get("consentState").asText()).isEqualTo("GRANTED");
        assertThat(ready.get("linkState").asText()).isEqualTo("PENDING_CONSENT");
        assertThat(ready.get("reportReady").asBoolean()).isTrue();
        assertThat(ready.get("pdfReady").asBoolean()).isTrue();
        String snapshotHash = ready.get("snapshotHash").asText();

        ReportVersion version = reportVersions.findFirstByReportIdOrderByVersionNoDesc(
                reports.findByJobId(UUID.fromString(jobId)).orElseThrow().getId()).orElseThrow();
        String snapshotJson = version.getSnapshotJson();
        assertThat(snapshotJson).doesNotContain(customerName)
                .doesNotContain(customerPhone).doesNotContain(customerEmail)
                .doesNotContain(fullVin).doesNotContain(plate);

        String activation = postJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report/link", "{}")
                .get("publicUrl").asText();
        assertThat(activation).contains("/r/");
        String token = activation.substring(activation.lastIndexOf('/') + 1);
        assertThat(token.length()).isGreaterThanOrEqualTo(43);
        assertThat(publicLinks.findAll()).singleElement()
                .satisfies(link -> assertThat(link.getTokenHash()).hasSize(32));
        assertThat(new String(publicLinks.findAll().get(0).getTokenHash()))
                .isNotEqualTo(token);

        MvcResult page = mockMvc.perform(get("/r/" + token))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Robots-Tag", "noindex, nofollow"))
                .andExpect(header().string("Referrer-Policy", "no-referrer"))
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andReturn();
        String html = page.getResponse().getContentAsString();
        assertThat(html).contains("Toyota", "Brake system check", "Workshop A", "Technician A")
                .doesNotContain(customerName, customerPhone, customerEmail, fullVin, plate)
                .doesNotContain("JTDBR32E72");
        assertThat(html).contains("noindex", "no-referrer");
        assertThat(html).doesNotContain("fonts.googleapis", "cdnjs", "http://", "https://");

        MvcResult arabic = mockMvc.perform(get("/r/" + token).param("lang", "ar"))
                .andExpect(status().isOk()).andReturn();
        assertThat(arabic.getResponse().getContentAsString())
                .contains("dir=\"rtl\"", "تقرير فحص مركبة");

        mockMvc.perform(get("/r/" + token + "/pdf")).andExpect(status().isNotFound());

        putJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report/pdf-download",
                "{\"enabled\":true}");
        MvcResult pdf = mockMvc.perform(get("/r/" + token + "/pdf"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", MediaType.APPLICATION_PDF_VALUE))
                .andReturn();
        byte[] pdfBytes = pdf.getResponse().getContentAsByteArray();
        assertThat(pdfBytes).hasSizeGreaterThan(1000);
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            String pdfText = new PDFTextStripper().getText(document).replaceAll("\\s+", " ");
            assertThat(pdfText).contains("Vehicle inspection report", "Brake system check")
                    .doesNotContain(customerName, customerPhone, customerEmail, fullVin, plate);
            assertThat(document.getNumberOfPages()).isGreaterThanOrEqualTo(1);
        }

        mockMvc.perform(get("/api/v1/workshop/jobs/" + jobId + "/report")
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/workshop/jobs/" + jobId + "/report")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/v1/workshop/jobs/" + jobId + "/report/retry")
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/technician/jobs/" + jobId + "/report")
                        .header("Authorization", "Bearer " + admin.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/technician/jobs/" + jobId + "/report")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isForbidden());

        ReportGenerationJob failedJob = generationJobs.findByReportVersionId(version.getId()).orElseThrow();
        String beforeFailureHash = ready.get("snapshotHash").asText();
        failedJob.markFailed("forced generation failure");
        generationJobs.save(failedJob);
        assertThat(getJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report")
                .get("generationStatus").asText()).isEqualTo("FAILED");
        assertThat(finalSnapshots.findByJobId(UUID.fromString(jobId)).orElseThrow()
                .getSnapshotHash()).isNotEmpty();
        postJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report/retry", "{}");
        reportGeneration.poll();
        JsonNode afterRetry = getJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report");
        assertThat(afterRetry.get("generationStatus").asText()).isEqualTo("READY");
        assertThat(afterRetry.get("snapshotHash").asText()).isEqualTo(beforeFailureHash);

        postJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report/link/revoke",
                "{\"reasonCode\":\"PRIVACY\",\"note\":\"Customer request\"}");
        MvcResult revoked = mockMvc.perform(get("/r/" + token))
                .andExpect(status().isNotFound()).andReturn();
        MvcResult invalid = mockMvc.perform(get("/r/not-a-real-token"))
                .andExpect(status().isNotFound()).andReturn();
        assertThat(revoked.getResponse().getContentAsString())
                .isEqualTo(invalid.getResponse().getContentAsString());
        mockMvc.perform(get("/r/" + token + "/pdf")).andExpect(status().isNotFound());
        mockMvc.perform(get("/r/" + token + "/photo/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());

        JsonNode retried = getJson(admin, "/api/v1/workshop/jobs/" + jobId + "/report");
        assertThat(retried.get("snapshotHash").asText()).isEqualTo(snapshotHash);
    }

    @Test
    void linkCannotActivateWithoutPublicLinkConsent() throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        UUID categoryId = category("consent");
        MasterItem item = item(categoryId, "REPORT-002", "Consent check");
        String templateId = template(admin, "Consent template", List.of(item.versionId()));
        String jobId = job(admin, publishedVersion(admin, templateId), "Consent customer",
                "+971500000002", "consent@example.test", "JTDBR32E720654321", "CONSENT-2");
        assign(admin, jobId, fixture.techA().getId());
        String itemId = start(technician, jobId).get("items").get(0).get("inspectionItemId").asText();
        assess(technician, jobId, itemId, "NO_ISSUE_OBSERVED", null, "");
        finalize(technician, jobId, "report-final-2");
        reportGeneration.poll();

        mockMvc.perform(post("/api/v1/workshop/jobs/" + jobId + "/report/link")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CONSENT_REQUIRED"));
    }

    @Test
    void publicEndpointRateLimitIsNeutral() throws Exception {
        String ip = "203.0.113.77";
        for (int i = 0; i < 240; i++) {
            mockMvc.perform(get("/r/not-a-real-token").header("X-Forwarded-For", ip))
                    .andExpect(status().isNotFound());
        }
        mockMvc.perform(get("/r/not-a-real-token").header("X-Forwarded-For", ip))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "60"));
    }

    private void consent(Login login, String jobId) throws Exception {
        postJson(login, "/api/v1/technician/jobs/" + jobId + "/consent",
                "{\"consentType\":\"PUBLIC_LINK\",\"status\":\"GRANTED\","
                        + "\"wordingVersion\":\"p6-test\",\"channel\":\"IN_PERSON\"}");
    }

    private UUID category(String suffix) {
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("phase6-" + suffix + "-" + UUID.randomUUID(),
                        "Phase 6 " + suffix, "Phase 6 AR " + suffix, 0, null));
        return category.id();
    }

    private MasterItem item(UUID categoryId, String code, String label) {
        ItemDetailDto detail = masterContent.createItem(platformActor(), new ItemCreateRequest(
                code, categoryId, label, "Arabic " + label, "Instruction " + label,
                "Arabic instruction " + label, true,
                List.of("NO_ISSUE_OBSERVED", "DEFECT_FOUND", "NOT_CHECKED", "NOT_APPLICABLE"),
                "{}", "{}", List.of(), "OPTIONAL", "NONE", 0, List.of(), null));
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

    private String job(Login login, String versionId, String name, String phone,
                       String email, String vin, String plate) throws Exception {
        return postJson(login, "/api/v1/workshop/jobs",
                "{\"templateVersionId\":\"" + versionId + "\",\"customerName\":\"" + name
                        + "\",\"customerPhone\":\"" + phone + "\",\"customerEmail\":\"" + email
                        + "\",\"vehicleMake\":\"Toyota\",\"vehicleModel\":\"Corolla\","
                        + "\"vehicleYear\":2021,\"vehicleVin\":\"" + vin + "\","
                        + "\"vehiclePlate\":\"" + plate + "\",\"scope\":\"Full report test\"}")
                .get("id").asText();
    }

    private void assign(Login login, String jobId, UUID technicianId) throws Exception {
        postJson(login, "/api/v1/workshop/jobs/" + jobId + "/assign",
                "{\"technicianId\":\"" + technicianId + "\",\"reason\":\"Report test\"}");
    }

    private JsonNode start(Login login, String jobId) throws Exception {
        return postJson(login, "/api/v1/technician/jobs/" + jobId + "/start", null);
    }

    private void assess(Login login, String jobId, String itemId, String result,
                        String severity, String note) throws Exception {
        putJson(login, "/api/v1/technician/jobs/" + jobId + "/items/" + itemId + "/assessment",
                "{\"baseVersion\":0,\"clientRevision\":1,\"resultCode\":\"" + result
                        + "\",\"severityCode\":" + (severity == null ? "null" : "\"" + severity + "\"")
                        + ",\"note\":\"" + note.replace("\"", "\\\"") + "\"}");
    }

    private void finalize(Login login, String jobId, String key) throws Exception {
        postJson(login, "/api/v1/technician/jobs/" + jobId + "/ready", null);
        mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/finalize")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .header("Idempotency-Key", key))
                .andExpect(status().isOk());
    }

    private com.truereport.shared.security.CurrentUser platformActor() {
        return new com.truereport.shared.security.CurrentUser(
                fixture.platform().getId(), fixture.platform().getEmail(),
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
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private record MasterItem(UUID itemId, UUID versionId) {
    }
}
