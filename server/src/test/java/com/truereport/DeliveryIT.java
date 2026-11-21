package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.delivery.DeliveryProvider;
import com.truereport.delivery.DeliveryRequestEntity;
import com.truereport.delivery.DeliveryRequestRepository;
import com.truereport.delivery.DeliveryService;
import com.truereport.delivery.FakeDeliveryProvider;
import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobTokenService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Delivery works from the clean platform job/report/link stack, for any LIVE
 * language, and never fails an email because the PDF is unavailable.
 */
class DeliveryIT extends IntegrationTestBase {

    private static final String JOBS = "/api/v1/workshop/jobs";
    private static final String ALLOWED_PHONE = "+971500009900";
    private static final String ALLOWED_EMAIL = "private.9900@example.test";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    PlatformJobStore store;

    @Autowired
    PlatformJobTokenService tokens;

    @Autowired
    DeliveryService deliveryService;

    @Autowired
    DeliveryRequestRepository requests;

    @Autowired
    FakeDeliveryProvider provider;

    @BeforeEach
    void resetProvider() {
        provider.clear();
    }

    @Test
    void emailDeliveryUsesPlatformIdsAndSpanishMessage() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture seeded = PlatformJobFixtures.publishedJob(
                jdbc, store, tokens, fixture.workshopA().getId(), fixture.adminA().getId(),
                ALLOWED_PHONE, ALLOWED_EMAIL, "es", true, "PUBLISHED", "{}");

        MvcResult result = send(admin, seeded.jobId(), "EMAIL", "es")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.language").value("es"))
                .andExpect(jsonPath("$.status").value("QUEUED"))
                .andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        UUID requestId = UUID.fromString(body.get("id").asText());

        deliveryService.poll();

        DeliveryProvider.DeliveryMessage message = provider.lastMessage();
        assertThat(message).isNotNull();
        assertThat(message.language()).isEqualTo("es");
        assertThat(message.subject()).isEqualTo("Informe de inspección del vehículo listo");
        assertThat(message.body()).contains("Su informe de inspección del vehículo está listo");
        // "{}" is not a renderable snapshot: the email must fall back to the link.
        assertThat(message.pdf()).isNull();
        assertThat(message.body()).contains("/r/");

        DeliveryRequestEntity stored = requests.findById(requestId).orElseThrow();
        assertThat(stored.getJobId()).isEqualTo(seeded.jobId());
        assertThat(stored.getReportVersionId()).isEqualTo(seeded.reportVersionId());
        assertThat(stored.getPublicShareLinkId()).isEqualTo(seeded.linkId());

        JsonNode rows = getJson(admin, JOBS + "/" + seeded.jobId() + "/deliveries");
        assertThat(rows.size()).isEqualTo(1);
        assertThat(rows.get(0).get("status").asText()).isEqualTo("SENT");
        assertThat(rows.get(0).get("linkState").asText()).isEqualTo("ACTIVE");
    }

    @Test
    void emailAttachesRenderedPdfWhenAvailable() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture seeded = PlatformJobFixtures.publishedJob(
                jdbc, store, tokens, fixture.workshopA().getId(), fixture.adminA().getId(),
                ALLOWED_PHONE, ALLOWED_EMAIL, "en", true, "PUBLISHED",
                PlatformJobFixtures.snapshot("en"));

        send(admin, seeded.jobId(), "EMAIL", "en")
                .andExpect(status().isCreated());

        deliveryService.poll();

        DeliveryProvider.DeliveryMessage message = provider.lastMessage();
        assertThat(message).isNotNull();
        assertThat(message.pdf()).isNotNull();
        assertThat(new String(message.pdf(), 0, 5)).isEqualTo("%PDF-");
        assertThat(message.body()).contains("attached PDF");
    }

    @Test
    void consentMissingIsRejected() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture seeded = PlatformJobFixtures.publishedJob(
                jdbc, store, tokens, fixture.workshopA().getId(), fixture.adminA().getId(),
                ALLOWED_PHONE, null, "en", false, "PUBLISHED", "{}");

        send(admin, seeded.jobId(), "SMS", "en")
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CONSENT_REQUIRED"));
    }

    @Test
    void nonPublishedJobIsRejected() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture seeded = PlatformJobFixtures.publishedJob(
                jdbc, store, tokens, fixture.workshopA().getId(), fixture.adminA().getId(),
                ALLOWED_PHONE, null, "en", true, "APPROVED", "{}");

        send(admin, seeded.jobId(), "SMS", "en")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("REPORT_NOT_READY"));
    }

    @Test
    void unknownJobIsNotFound() throws Exception {
        Login admin = login("admin.a@test.local");
        send(admin, UUID.randomUUID().toString(), "SMS", "en")
                .andExpect(status().isNotFound());
    }

    @Test
    void failedDeliveryCanBeRetried() throws Exception {
        Login admin = login("admin.a@test.local");
        PlatformJobFixtures.Fixture seeded = PlatformJobFixtures.publishedJob(
                jdbc, store, tokens, fixture.workshopA().getId(), fixture.adminA().getId(),
                ALLOWED_PHONE, null, "en", true, "PUBLISHED", "{}");

        MvcResult result = mockMvc.perform(post(JOBS + "/" + seeded.jobId() + "/deliveries")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .header("Idempotency-Key", UUID.randomUUID().toString())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"channel\":\"SMS\",\"language\":\"en\"}"))
                .andExpect(status().isCreated()).andReturn();
        UUID requestId = UUID.fromString(objectMapper.readTree(
                result.getResponse().getContentAsString()).get("id").asText());

        provider.failNext(1);
        deliveryService.poll();
        assertThat(requests.findById(requestId).orElseThrow().getStatus())
                .isEqualTo("RETRY_PENDING");

        mockMvc.perform(post(JOBS + "/" + seeded.jobId() + "/deliveries/" + requestId + "/retry")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .header("Idempotency-Key", UUID.randomUUID().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("QUEUED"));

        provider.clear();
        deliveryService.poll();
        assertThat(requests.findById(requestId).orElseThrow().getStatus()).isEqualTo("SENT");
    }

    // ------------------------------------------------------------------ helpers

    private org.springframework.test.web.servlet.ResultActions send(Login login, String jobId,
                                                                     String channel, String language)
            throws Exception {
        return mockMvc.perform(post(JOBS + "/" + jobId + "/deliveries")
                .header("Authorization", "Bearer " + login.accessToken())
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"channel\":\"" + channel + "\",\"language\":\"" + language + "\"}"));
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        MvcResult result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
