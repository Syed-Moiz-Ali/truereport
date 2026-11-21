package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobStore.LinkRow;
import com.truereport.jobs.PlatformJobTokenService;
import com.truereport.shared.uuid.UuidV7;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Workshop report actions target platform jobs: on-demand PDF, document retry,
 * and the link revoke/activate lifecycle, with the existing DTO shapes.
 */
class PlatformReportActionsIT extends IntegrationTestBase {

    private static final String JOBS = "/api/v1/workshop/jobs";
    private static final String ALLOWED_PHONE = "+971500009900";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    PlatformJobStore store;

    @Autowired
    PlatformJobTokenService tokens;

    @Test
    void adminPdfRendersWithoutAnArtifactAndReportsLanguage() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture fixture = fixture("es", true, "PUBLISHED");

        mockMvc.perform(get(JOBS + "/" + fixture.jobId() + "/report")
                        .header("Authorization", "Bearer " + admin.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pdfReady").value(true))
                .andExpect(jsonPath("$.reportReady").value(true))
                .andExpect(jsonPath("$.generationStatus").value("READY"))
                .andExpect(jsonPath("$.content.language").value("es"));

        MvcResult pdf = mockMvc.perform(get(JOBS + "/" + fixture.jobId() + "/report/pdf")
                        .header("Authorization", "Bearer " + admin.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        byte[] bytes = pdf.getResponse().getContentAsByteArray();
        assertThat(bytes.length).isGreaterThan(100);
        assertThat(new String(bytes, 0, 5)).isEqualTo("%PDF-");
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM report_artifacts",
                Integer.class)).isZero();
    }

    @Test
    void retryRegeneratesOnlyFailedPlatformDocuments() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture fixture = fixture("es", true, "PUBLISHED");
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String type = "DEL-RPT-" + suffix;
        jdbc.update("""
                INSERT INTO platform_document_types
                    (id, code, name, status, is_required, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 'ACTIVE', FALSE, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, UuidV7.generate().toString(), type, "Delivery report " + suffix);
        String documentId = store.insertDocument(fixture.reportVersionId(), type, "es");
        store.markDocumentFailed(documentId, "render failed");

        mockMvc.perform(get(JOBS + "/" + fixture.jobId() + "/report")
                        .header("Authorization", "Bearer " + admin.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.generationStatus").value("FAILED"));

        mockMvc.perform(post(JOBS + "/" + fixture.jobId() + "/report/retry")
                        .header("Authorization", "Bearer " + admin.accessToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.generationStatus").value("READY"));

        assertThat(store.document(documentId).orElseThrow().status()).isEqualTo("READY");
        assertThat(store.document(documentId).orElseThrow().language()).isEqualTo("es");
        assertThat(store.document(documentId).orElseThrow().storageKey()).endsWith("-es.pdf");
    }

    @Test
    void revokeThenActivateReturnsANewActiveLink() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture fixture = fixture("en", true, "PUBLISHED");

        mockMvc.perform(post(JOBS + "/" + fixture.jobId() + "/report/link/revoke")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reasonCode\":\"CUSTOMER_REQUEST\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("REVOKED"));
        assertThat(store.activeLink(fixture.jobId())).isEmpty();

        JsonNode activated = postJson(admin, JOBS + "/" + fixture.jobId() + "/report/link", "{}");
        assertThat(activated.get("state").asText()).isEqualTo("ACTIVE");
        assertThat(activated.get("publicUrl").asText()).startsWith("http://localhost:8080/r/");
        LinkRow active = store.activeLink(fixture.jobId()).orElseThrow();
        assertThat(active.id()).isNotEqualTo(fixture.linkId());

        JsonNode again = postJson(admin, JOBS + "/" + fixture.jobId() + "/report/link", "{}");
        assertThat(again.get("state").asText()).isEqualTo("ACTIVE");
        assertThat(store.activeLink(fixture.jobId()).orElseThrow().id()).isEqualTo(active.id());
    }

    private PlatformJobFixtures.Fixture fixture(String language, boolean consent, String status) {
        return PlatformJobFixtures.publishedJob(jdbc, store, tokens,
                fixture.workshopA().getId(), fixture.adminA().getId(), ALLOWED_PHONE,
                "private.9900@example.test", language, consent, status,
                PlatformJobFixtures.snapshot(language));
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(post(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
