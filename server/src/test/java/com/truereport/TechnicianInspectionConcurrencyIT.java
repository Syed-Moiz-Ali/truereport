package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.shared.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:truereport_concurrency;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1;NON_KEYWORDS=USER")
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)
class TechnicianInspectionConcurrencyIT {

    private static final String PASSWORD = TestDataFactory.PASSWORD;

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    TestDataFactory testDataFactory;

    @Autowired
    MasterContentService masterContent;

    TestDataFactory.Fixture fixture;

    @BeforeEach
    void setUp() {
        fixture = testDataFactory.createTwoWorkshops();
    }

    @Test
    void twoFinalizeRequestsWithSameKeyProduceOneFinalizedInspection() throws Exception {
        Login admin = login("admin.a@test.local");
        Login technician = login("tech.a@test.local");
        CategoryDto category = masterContent.createCategory(platformActor(),
                new CategoryRequest("concurrent-" + UUID.randomUUID(), "Concurrent",
                        "Concurrent AR", 0, null));
        ItemDetailDto item = masterContent.createItem(platformActor(), new ItemCreateRequest(
                "SAMPLE-CONCURRENT-001", category.id(), "Concurrent item", "Concurrent AR item",
                "Instruction", "Arabic instruction", true,
                List.of("NO_ISSUE_OBSERVED"), "{}", "{}", List.of(),
                "OPTIONAL", "NONE", 0, List.of(), null));
        masterContent.publish(platformActor(), item.item().id(), item.versions().get(0).id());

        JsonNode template = postJson(admin, "/api/v1/workshop/templates",
                "{\"name\":\"Concurrent template\",\"serviceType\":\"FULL\",\"vehicleType\":\"CAR\"}");
        String templateId = template.get("id").asText();
        putJson(admin, "/api/v1/workshop/templates/" + templateId + "/draft",
                "{\"name\":\"Concurrent template\",\"serviceType\":\"FULL\",\"vehicleType\":\"CAR\","
                        + "\"items\":[{\"masterItemVersionId\":\"" + item.versions().get(0).id()
                        + "\",\"sortOrder\":0}]}");
        JsonNode published = postJson(admin, "/api/v1/workshop/templates/" + templateId + "/publish", "{}");
        String versionId = published.get("currentPublishedVersionId").asText();
        JsonNode job = postJson(admin, "/api/v1/workshop/jobs",
                "{\"templateVersionId\":\"" + versionId + "\",\"customerName\":\"Concurrent customer\","
                        + "\"vehicleMake\":\"Toyota\",\"vehicleModel\":\"Camry\",\"scope\":\"Full inspection\"}");
        String jobId = job.get("id").asText();
        postJson(admin, "/api/v1/workshop/jobs/" + jobId + "/assign",
                "{\"technicianId\":\"" + fixture.techA().getId() + "\"}");
        JsonNode checklist = postJson(technician, "/api/v1/technician/jobs/" + jobId + "/start", null);
        String itemId = checklist.get("items").get(0).get("inspectionItemId").asText();
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .put("/api/v1/technician/jobs/" + jobId + "/items/" + itemId + "/assessment")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"baseVersion\":0,\"clientRevision\":1,"
                                + "\"resultCode\":\"NO_ISSUE_OBSERVED\"}"))
                .andExpect(status().isOk());
        postJson(technician, "/api/v1/technician/jobs/" + jobId + "/ready", null);

        CompletableFuture<MvcResult> first = CompletableFuture.supplyAsync(
                () -> finalizeRequest(technician, jobId, "same-concurrent-key"));
        CompletableFuture<MvcResult> second = CompletableFuture.supplyAsync(
                () -> finalizeRequest(technician, jobId, "same-concurrent-key"));
        MvcResult result1 = first.get(30, TimeUnit.SECONDS);
        MvcResult result2 = second.get(30, TimeUnit.SECONDS);
        assertThat(result1.getResponse().getStatus()).isEqualTo(200);
        assertThat(result2.getResponse().getStatus()).isEqualTo(200);
        JsonNode body1 = objectMapper.readTree(result1.getResponse().getContentAsString());
        JsonNode body2 = objectMapper.readTree(result2.getResponse().getContentAsString());
        assertThat(body1.get("status").asText()).isEqualTo("FINALIZED");
        assertThat(body2.get("status").asText()).isEqualTo("FINALIZED");
        assertThat(body1.get("snapshotHash").asText())
                .isEqualTo(body2.get("snapshotHash").asText());
    }

    private MvcResult finalizeRequest(Login login, String jobId, String key) {
        try {
            return mockMvc.perform(post("/api/v1/technician/jobs/" + jobId + "/finalize")
                            .header("Authorization", "Bearer " + login.accessToken())
                            .header("Idempotency-Key", key))
                    .andReturn();
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private CurrentUser platformActor() {
        return new CurrentUser(fixture.platform().getId(), fixture.platform().getEmail(),
                "PLATFORM_ADMIN", null, null);
    }

    private Login login(String email) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"" + PASSWORD + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return new Login(body.get("accessToken").asText());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        MvcResult result = mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .put(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var request = post(path).header("Authorization", "Bearer " + login.accessToken());
        if (body != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(body);
        }
        MvcResult result = mockMvc.perform(request).andExpect(status().is2xxSuccessful()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private record Login(String accessToken) {
    }
}
