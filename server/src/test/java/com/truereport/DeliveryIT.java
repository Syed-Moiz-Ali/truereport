package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.delivery.DeliveryRequestRepository;
import com.truereport.delivery.DeliveryService;
import com.truereport.delivery.DeliveryWebhookEventRepository;
import com.truereport.delivery.FakeDeliveryProvider;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.reports.ReportGenerationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HexFormat;
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

class DeliveryIT extends IntegrationTestBase {

    private static final String PHONE = "+971500009900";
    private static final String EMAIL = "private.9900@example.test";
    private static final String WEBHOOK_SECRET = "test-webhook-secret";

    @Autowired
    MasterContentService masterContent;

    @Autowired
    ReportGenerationService reportGeneration;

    @Autowired
    DeliveryService deliveryService;

    @Autowired
    FakeDeliveryProvider fakeProvider;

    @Autowired
    DeliveryRequestRepository deliveryRequests;

    @Autowired
    DeliveryWebhookEventRepository webhookEvents;

'    @BeforeEach
    void resetFakeProvider() {
        fakeProvider.clear();
    }

    @Test
    void consentedWhatsAppIsIdempotentAndWebhookDelivered()' throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        String jobId = finalizedJob(admin, technician, "Delivery WhatsApp");

        JsonNode queued = send(admin, jobId, "WHATSAPP", "delivery-wa-1");
        assertThat(queued.get("status").asText()).isEqualTo("QUEUED");
        deliveryService.poll();
        JsonNode sent = delivery(admin, jobId).get(0);
        assertThat(sent.get("status").asText()).isEqualTo("SENT");
        assertThat(sent.get("recipientMasked").asText()).doesNotContain(PHONE);
        assertThat(fakeProvider.messages()).hasSize(1);
        String message = fakeProvider.lastMessage().body();
        assertThat(message).contains("Vehicle inspection report", "/r/", "Delivery WhatsApp")
                .doesNotContain("Private Customer", "+971500009900", "JTDBR32E720990011",
                        "PRIVATE-9900");
        String providerMessageId = fakeProvider.lastProviderMessageId();

        JsonNode replay = send(admin, jobId, "WHATSAPP", "delivery-wa-1");
        assertThat(replay.get("id").asText()).isEqualTo(queued.get("id").asText());
        assertThat(fakeProvider.messages()).hasSize(1);

        String payload = objectMapper.writeValueAsString(Map.of(
                "eventId", "evt-wa-1",
                "providerMessageId", providerMessageId,
                "status", "DELIVERED"));
        String signature = signature(payload);
        mockMvc.perform(post("/api/v1/delivery/webhooks/fake")
                        .header("X-Delivery-Signature", signature)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/delivery/webhooks/fake")
                        .header("X-Delivery-Signature", signature)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());
        assertThat(webhookEvents.count()).isEqualTo(1);
        assertThat(delivery(admin, jobId).get(0).get("status").asText()).isEqualTo("DELIVERED");
        assertThat(delivery(admin, jobId).get(0).get("attemptHistory").size()).isEqualTo(1);
    }

    @Test
    void emailAttachesPdfAndRoleMatrixIsEnforced() throws Exception {
        Login admin = login("admin.a@test.local");
        Login adminB = login("admin.b@test.local");
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");
        String jobId = finalizedJob(admin, technician, "Delivery Email");

        send(admin, jobId, "EMAIL", "delivery-email-1");
        deliveryService.poll();
        JsonNode delivery = delivery(admin, jobId).get(0);
        assertThat(delivery.get("status").asText()).isEqualTo("SENT");
        assertThat(delivery.get("pdfAttached").asBoolean()).isTrue();
        assertThat(delivery.get("recipientMasked").asText()).doesNotContain(EMAIL);
        assertThat(fakeProvider.lastMessage().pdf())
                .isNotNull().startsWith("%PDF".getBytes(StandardCharsets.US_ASCII));
        assertThat(fakeProvider.lastMessage().body())
                .doesNotContain("Private Customer", EMAIL, "JTDBR32E720990011");

        mockMvc.perform(get("/api/v1/workshop/jobs/" + jobId + "/deliveries")
                        .header("Authorization", "Bearer " + adminB.accessToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/v1/workshop/jobs/" + jobId + "/deliveries")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "tech-send")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"channel\":\"SMS\",\"language\":\"en\"}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/technician/jobs/" + jobId + "/deliveries")
                        .header("Authorization", "Bearer " + admin.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/platform/deliveries")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/platform/deliveries")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/delivery/webhooks/fake")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isMethodNotAllowed());
        mockMvc.perform(post("/api/v1/delivery/webhooks/fake")
                        .header("X-Delivery-Signature", "sha256=bad")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void missingConsentBlockedRecipientAndRetryAreEnforced() throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        String jobId = finalizedJob(admin, technician, "Delivery Retry", false);

        mockMvc.perform(post("/api/v1/workshop/jobs/" + jobId + "/deliveries")
                        .header("Authorization", "Bearer " + admin.accessToken())
                        .header("Idempotency-Key", "no-consent")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"channel\":\"WHATSAPP\",\"language\":\"en\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CONSENT_REQUIRED"));

        consent(technician, jobId, "WHATSAPP");
        send(admin, jobId, "WHATSAPP", "retry-1");
        fakeProvider.failNext(1);
        deliveryService.poll();
        JsonNode retry = delivery(admin, jobId).get(0);
        assertThat(retry.get("status").asText()).isEqualTo("RETRY_PENDING");
        assertThat(retry.get("attempts").asInt()).isEqualTo(1);
        assertThat(deliveryRequests.findAll()).hasSize(1);

        Thread.sleep(1_200);
        deliveryService.poll();
        JsonNode sent = delivery(admin, jobId).get(0);
        assertThat(sent.get("status").asText()).isEqualTo("SENT");
        assertThat(sent.get("attemptHistory").size()).isEqualTo(2);
        assertThat(getJson(admin, "/api/v1/workshop/jobs/" + jobId).get("status").asText())
                .isEqualTo("FINALIZED");
    }

    private String finalizedJob(Login admin, Login technician, String label) throws Exception {
        return finalizedJob(admin, technician, label, true);
    }

    private String finalizedJob(Login admin, Login technician, String label, boolean allConsents)
            throws Exception {
        UUID categoryId = category(label);
        MasterItem item = item(categoryId, label);
        String templateId = template(admin, label, List.of(item.versionId()));
        String jobId = job(admin, publishedVersion(admin, templateId), label);
        assign(admin, jobId, fixture.techA().getId());
        String itemId = start(technician, jobId).get("items").get(0).get("inspectionItemId").asText();
        assess(technician, jobId, itemId);
        if (allConsents) {
            consent(technician, jobId, "PUBLIC_LINK");
            consent(technician, jobId, "WHATSAPP");
            consent(technician, jobId, "SMS");
            consent(technician, jobId, "EMAIL");
        }
        postJson(technician, "/api/v1/technician/jobs/" + jobId + "/ready", null);
        mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/finalize")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("Idempotency-Key", "delivery-final-" + jobId))
                .andExpect(status().isOk());
        reportGeneration.poll();
        return jobId;
    }

    private JsonNode send(Login login, String jobId, String channel, String key) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/workshop/jobs/" + jobId + "/deliveries")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .header("Idempotency-Key", key)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"channel\":\"" + channel + "\",\"language\":\"en\"}"))
                .andExpect(status().isCreated()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode delivery(Login login, String jobId) throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/workshop/jobs/" + jobId + "/deliveries")
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private void consent(Login login, String jobId, String type) throws Exception {
        postJson(login, "/api/v1/technician/jobs/" + jobId + "/consent",
                "{\"consentType\":\"" + type + "\",\"status\":\"GRANTED\","
                        + "\"wordingVersion\":\"p7-test\",\"channel\":\"IN_PERSON\"}");
    }

    private UUID category(String label) {
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("p7-" + UUID.randomUUID(), label,
                        "فئة " + label, 0, null));
        return category.id();
    }

    private MasterItem item(UUID categoryId, String label) {
        ItemDetailDto detail = masterContent.createItem(platformActor(), new ItemCreateRequest(
                "P7-" + UUID.randomUUID().toString().substring(0, 8), categoryId,
                label, "فحص " + label, "Inspect.", "افحص.", true,
                List.of("NO_ISSUE_OBSERVED", "DEFECT_FOUND", "NOT_CHECKED", "NOT_APPLICABLE"),
                "{}", "{}", List.of(), "OPTIONAL", "NONE", 0, List.of(), null));
        UUID itemId = detail.item().id();
        UUID versionId = detail.versions().get(0).id();
        masterContent.publish(platformActor(), itemId, versionId);
        return new MasterItem(versionId);
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

    private String job(Login login, String versionId, String label) throws Exception {
        JsonNode job = postJson(login, "/api/v1/workshop/jobs",
                "{\"templateVersionId\":\"" + versionId + "\",\"customerName\":\"Private Customer\","
                        + "\"customerPhone\":\"" + PHONE + "\",\"customerEmail\":\"" + EMAIL + "\","
                        + "\"vehicleMake\":\"Toyota\",\"vehicleModel\":\"Land Cruiser\","
                        + "\"vehicleYear\":2022,\"vehicleVin\":\"JTDBR32E720990011\","
                        + "\"vehiclePlate\":\"PRIVATE-9900\",\"scope\":\"" + label + "\"}");
        return job.get("id").asText();
    }

    private void assign(Login login, String jobId, UUID technicianId) throws Exception {
        postJson(login, "/api/v1/workshop/jobs/" + jobId + "/assign",
                "{\"technicianId\":\"" + technicianId + "\",\"reason\":\"Delivery test\"}");
    }

    private JsonNode start(Login login, String jobId) throws Exception {
        return postJson(login, "/api/v1/technician/jobs/" + jobId + "/start", null);
    }

    private void assess(Login login, String jobId, String itemId) throws Exception {
        putJson(login, "/api/v1/technician/jobs/" + jobId + "/items/" + itemId + "/assessment",
                "{\"baseVersion\":0,\"clientRevision\":1,\"resultCode\":\"NO_ISSUE_OBSERVED\","
                        + "\"note\":\"Visible condition checked.\"}");
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

    private String signature(String payload) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(WEBHOOK_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return "sha256=" + HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
    }

    private record MasterItem(UUID versionId) {
    }
}