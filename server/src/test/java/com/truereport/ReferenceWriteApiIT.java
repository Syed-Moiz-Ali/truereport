package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ReferenceWriteApiIT extends IntegrationTestBase {

    private static final String BASE = "/api/v1/reference";

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void draftIsHiddenFromClientsUntilPublishedAndEtagChanges() throws Exception {
        Login platform = login("platform@test.local");
        Login workshop = login("admin.a@test.local");

        JsonNode created = write(platform, "post", BASE + "/statuses/job", """
                {"code":"E2E_DRAFT","labelKey":"statusScheduled","tone":"info",
                 "icon":"circle","order":99,"selectable":true,
                 "visibleFor":["platform_admin","workshop_admin","technician"],
                 "allowedNext":["CANCELLED"]}
                """, 201);
        assertThat(created.get("code").asText()).isEqualTo("E2E_DRAFT");
        assertThat(created.get("status").asText()).isEqualTo("DRAFT");

        assertThat(codes(read(workshop, BASE + "/statuses/job", 200)
                .body())).doesNotContain("E2E_DRAFT");
        JsonNode draftRows = read(platform, BASE + "/statuses/job?includeDraft=true", 200)
                .body();
        assertThat(codes(draftRows)).contains("E2E_DRAFT");
        assertThat(statusOf(draftRows, "E2E_DRAFT")).isEqualTo("DRAFT");

        // A non-platform caller cannot ask for drafts.
        read(workshop, BASE + "/statuses/job?includeDraft=true", 403);

        String etagBefore = read(workshop, BASE + "/statuses/job", 200).etag();

        write(platform, "post", BASE + "/statuses/job/E2E_DRAFT/publish", "{}", 200);
        JsonNode publishedRows = read(workshop, BASE + "/statuses/job", 200).body();
        assertThat(codes(publishedRows)).contains("E2E_DRAFT");
        assertThat(statusOf(publishedRows, "E2E_DRAFT")).isEqualTo("PUBLISHED");

        String etagAfter = read(workshop, BASE + "/statuses/job", 200).etag();
        assertThat(etagAfter).isNotEqualTo(etagBefore);

        Integer audits = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_audit_events
                WHERE action_code = 'reference.status.published'
                  AND entity_type = 'REFERENCE_DOMAIN'
                  AND entity_id = 'job-status:E2E_DRAFT'
                """, Integer.class);
        assertThat(audits).isEqualTo(1);
    }

    @Test
    void enumLifecycleCreatePublishAndUpdate() throws Exception {
        Login platform = login("platform@test.local");
        Login technician = login("tech.a@test.local");

        JsonNode created = write(platform, "post", BASE + "/enums/severity", """
                {"code":"EXTREME","labelKey":"minor","tone":"danger","icon":"circle",
                 "order":9,"selectable":true,
                 "visibleFor":["platform_admin","workshop_admin","technician"]}
                """, 201);
        int createdVersion = created.get("version").asInt();
        assertThat(codes(read(technician, BASE + "/enums/severity", 200).body()))
                .doesNotContain("EXTREME");
        write(platform, "post", BASE + "/enums/severity/EXTREME/publish", "{}", 200);
        assertThat(codes(read(technician, BASE + "/enums/severity", 200).body()))
                .contains("EXTREME");

        JsonNode updated = write(platform, "put", BASE + "/enums/severity/EXTREME", """
                {"labelKey":"major","tone":"warning","icon":"alert","order":10,
                 "selectable":false,"visibleFor":["technician"]}
                """, 200);
        assertThat(updated.get("labelKey").asText()).isEqualTo("major");
        assertThat(updated.get("version").asInt()).isGreaterThan(createdVersion);
        assertThat(codes(read(login("tech.a@test.local"), BASE + "/enums/severity", 200)
                .body())).contains("EXTREME");
    }

    @Test
    void unknownLabelKeyAndInvalidVisibleForAre422() throws Exception {
        Login platform = login("platform@test.local");
        JsonNode unknown = write(platform, "post", BASE + "/statuses/job", """
                {"code":"BAD_LABEL","labelKey":"not.a.real.key","tone":"info",
                 "order":1,"visibleFor":["technician"]}
                """, 422);
        assertThat(unknown.get("code").asText()).isEqualTo("LABEL_KEY_UNKNOWN");

        JsonNode noVisibility = write(platform, "post", BASE + "/statuses/job", """
                {"code":"BAD_VIS","labelKey":"statusScheduled","tone":"info",
                 "order":1,"visibleFor":[]}
                """, 422);
        assertThat(noVisibility.get("code").asText()).isEqualTo("VISIBLE_FOR_INVALID");

        JsonNode badOrder = write(platform, "post", BASE + "/statuses/job", """
                {"code":"BAD_ORDER","labelKey":"statusScheduled","tone":"info",
                 "order":-1,"visibleFor":["technician"]}
                """, 422);
        assertThat(badOrder.get("code").asText()).isEqualTo("ORDER_INVALID");
    }

    @Test
    void codeIsImmutableOnUpdate() throws Exception {
        Login platform = login("platform@test.local");
        write(platform, "post", BASE + "/statuses/job", """
                {"code":"KEEP_CODE","labelKey":"statusScheduled","tone":"info",
                 "order":50,"visibleFor":["technician"]}
                """, 201);
        JsonNode problem = write(platform, "put", BASE + "/statuses/job/KEEP_CODE", """
                {"code":"RENAMED","labelKey":"statusScheduled","tone":"info",
                 "order":50,"visibleFor":["technician"]}
                """, 422);
        assertThat(problem.get("code").asText()).isEqualTo("CODE_IMMUTABLE");
    }

    @Test
    void retireInUseIs409AndImpactReportsCounts() throws Exception {
        Login platform = login("platform@test.local");

        String templateId = UUID.randomUUID().toString();
        String versionId = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name, description, status, created_at, updated_at, version)
                VALUES (?, 'TPL-REF-1', 'Reference test', 'test', 'ACTIVE',
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, templateId);
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, created_at, updated_at)
                VALUES (?, ?, 1, 'PUBLISHED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, versionId, templateId);

        JsonNode impact = read(platform, BASE + "/template/PUBLISHED/impact", 200).body();
        assertThat(impact.get("templates").asInt()).isGreaterThanOrEqualTo(1);

        JsonNode problem = write(platform, "post",
                BASE + "/statuses/template/PUBLISHED/retire", "{}", 409);
        assertThat(problem.get("code").asText()).isEqualTo("REFERENCE_IN_USE");
    }

    @Test
    void retireUnusedSucceeds() throws Exception {
        Login platform = login("platform@test.local");
        write(platform, "post", BASE + "/statuses/job", """
                {"code":"UNUSED_CODE","labelKey":"statusScheduled","tone":"info",
                 "order":60,"visibleFor":["platform_admin","technician"]}
                """, 201);
        write(platform, "post", BASE + "/statuses/job/UNUSED_CODE/publish", "{}", 200);
        write(platform, "post", BASE + "/statuses/job/UNUSED_CODE/retire", "{}", 200);
        JsonNode retiredRows = read(platform, BASE + "/statuses/job?includeDraft=true", 200)
                .body();
        assertThat(statusOf(retiredRows, "UNUSED_CODE")).isEqualTo("RETIRED");
        assertThat(codes(read(platform, BASE + "/statuses/job", 200).body()))
                .doesNotContain("UNUSED_CODE");
    }

    @Test
    void enumReorderAppliesSortOrderAndDrivesReadOrder() throws Exception {
        Login platform = login("platform@test.local");
        Login technician = login("tech.a@test.local");

        write(platform, "put", BASE + "/enums/severity/reorder", """
                [{"code":"MAJOR","order":1},{"code":"MINOR","order":2}]
                """, 200);

        JsonNode rows = read(technician, BASE + "/enums/severity", 200).body();
        assertThat(rows.get(0).get("code").asText()).isEqualTo("MAJOR");
        assertThat(rows.get(1).get("code").asText()).isEqualTo("MINOR");
        assertThat(rows.get(0).get("order").asInt()).isEqualTo(1);

        write(technician, "put", BASE + "/enums/severity/reorder",
                "[{\"code\":\"MAJOR\",\"order\":1}]", 403);
    }

    @Test
    void reorderAndTransitionReplacementWork() throws Exception {
        Login platform = login("platform@test.local");
        JsonNode reordered = write(platform, "put", BASE + "/statuses/job/reorder", """
                [{"code":"CANCELLED","order":1},{"code":"DRAFT","order":2}]
                """, 200);
        assertThat(reordered.isArray()).isTrue();

        JsonNode transitions = write(platform, "put", BASE + "/transitions/job", """
                [{"fromCode":"DRAFT","toCode":"SCHEDULED","role":"WORKSHOP_ADMIN","guard":{}},
                 {"fromCode":"SCHEDULED","toCode":"CANCELLED","role":"WORKSHOP_ADMIN","guard":{}}]
                """, 200);
        assertThat(transitions.size()).isEqualTo(2);
    }

    @Test
    void everyWriteRouteIsPlatformAdminOnly() throws Exception {
        Login technician = login("tech.a@test.local");
        write(technician, "post", BASE + "/statuses/job", """
                {"code":"NOPE","labelKey":"statusScheduled","tone":"info",
                 "order":1,"visibleFor":["technician"]}
                """, 403);
        write(technician, "put", BASE + "/statuses/job/DRAFT", """
                {"labelKey":"statusScheduled","tone":"info","order":1,
                 "visibleFor":["technician"]}
                """, 403);
        write(technician, "post", BASE + "/statuses/job/DRAFT/publish", "{}", 403);
        write(technician, "post", BASE + "/statuses/job/DRAFT/retire", "{}", 403);
        write(technician, "put", BASE + "/statuses/job/reorder", "[]", 403);
        write(technician, "post", BASE + "/enums/role", """
                {"code":"NOPE","labelKey":"role.technician","tone":"info",
                 "order":1,"visibleFor":["technician"]}
                """, 403);
        write(technician, "put", BASE + "/enums/role/TECHNICIAN", """
                {"labelKey":"role.technician","tone":"info","order":1,
                 "visibleFor":["technician"]}
                """, 403);
        write(technician, "put", BASE + "/enums/severity/reorder", "[]", 403);
        write(technician, "post", BASE + "/enums/role/TECHNICIAN/publish", "{}", 403);
        write(technician, "post", BASE + "/enums/role/TECHNICIAN/retire", "{}", 403);
        write(technician, "put", BASE + "/transitions/job", "[]", 403);
    }

    private JsonNode write(Login login, String method, String path, String body,
                           int expectedStatus) throws Exception {
        var request = "post".equals(method) ? post(path) : put(path);
        var result = mockMvc.perform(request
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is(expectedStatus))
                .andReturn();
        String payload = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        if (payload == null || payload.isBlank()) {
            return objectMapper.createObjectNode();
        }
        return objectMapper.readTree(payload);
    }

    private record Read(JsonNode body, String etag) {
    }

    private Read read(Login login, String path, int expectedStatus) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().is(expectedStatus))
                .andReturn();
        String payload = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        JsonNode body = payload == null || payload.isBlank()
                ? objectMapper.createObjectNode() : objectMapper.readTree(payload);
        return new Read(body, result.getResponse().getHeader("ETag"));
    }

    private static List<String> codes(JsonNode rows) {
        List<String> codes = new java.util.ArrayList<>();
        rows.forEach(row -> codes.add(row.get("code").asText()));
        return codes;
    }

    private static String statusOf(JsonNode rows, String code) {
        for (JsonNode row : rows) {
            if (code.equals(row.get("code").asText())) {
                return row.get("status").asText();
            }
        }
        return null;
    }
}
