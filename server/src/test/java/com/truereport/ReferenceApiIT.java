package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ReferenceApiIT extends IntegrationTestBase {

    private static final String BASE = "/api/v1/reference";

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void jobStatusesHaveTheExactContractShapeAndOrder() throws Exception {
        Login technician = login("tech.a@test.local");
        JsonNode rows = getJson(technician, BASE + "/statuses/job");

        assertThat(rows.size()).isEqualTo(9);
        assertThat(codes(rows)).containsExactly(
                "DRAFT", "SCHEDULED", "ASSIGNED", "IN_PROGRESS", "PENDING_REVIEW",
                "APPROVED", "PUBLISHED", "REJECTED", "CANCELLED");
        for (JsonNode row : rows) {
            assertThat(fieldNames(row)).containsExactlyInAnyOrder(
                    "code", "labelKey", "tone", "icon", "order", "selectable",
                    "visibleFor", "allowedNext", "version", "status");
            assertThat(row.get("status").asText()).isEqualTo("PUBLISHED");
            assertThat(row.get("labelKey").asText()).matches("[A-Za-z0-9_.]+");
            assertThat(row.get("labelKey").asText()).doesNotContain(" ");
            assertThat(row.get("tone").asText())
                    .isIn("neutral", "info", "success", "warning", "danger");
            assertThat(row.get("order").asInt()).isGreaterThan(0);
            assertThat(row.get("visibleFor").isArray()).isTrue();
            assertThat(row.get("allowedNext").isArray()).isTrue();
        }
        JsonNode draft = rows.get(0);
        assertThat(strings(draft.get("allowedNext"))).containsExactly("SCHEDULED", "CANCELLED");
    }

    @Test
    void roleFilteringHidesPlatformOnlyRecordsFromTechnicians() throws Exception {
        Login technician = login("tech.a@test.local");
        Login platform = login("platform@test.local");

        JsonNode technicianRoles = getJson(technician, BASE + "/enums/role");
        assertThat(codes(technicianRoles)).doesNotContain("PLATFORM_ADMIN")
                .contains("TECHNICIAN");

        JsonNode platformRoles = getJson(platform, BASE + "/enums/role");
        assertThat(codes(platformRoles)).contains("PLATFORM_ADMIN", "WORKSHOP_ADMIN", "TECHNICIAN");
    }

    @Test
    void enumRecordsUseCatalogKeysOnly() throws Exception {
        Login technician = login("tech.a@test.local");
        for (String code : List.of("severity", "result", "grade", "measurement-unit", "evidence-type")) {
            JsonNode rows = getJson(technician, BASE + "/enums/" + code);
            assertThat(rows.size()).as(code).isGreaterThan(0);
            for (JsonNode row : rows) {
                assertThat(row.get("labelKey").asText())
                        .as(code + " " + row.get("code").asText())
                        .matches("[A-Za-z0-9_.]+")
                        .doesNotContain(" ");
                assertThat(row.has("label")).isFalse();
            }
        }
    }

    @Test
    void transitionsExposeTheSeededGraph() throws Exception {
        Login admin = login("admin.a@test.local");
        JsonNode rows = getJson(admin, BASE + "/transitions/job");

        assertThat(rows.size()).isGreaterThan(0);
        for (JsonNode row : rows) {
            assertThat(fieldNames(row)).containsExactlyInAnyOrder(
                    "fromCode", "toCode", "role", "guard", "version");
            assertThat(row.get("guard").isObject()).isTrue();
            assertThat(row.get("role").asText()).isNotBlank();
        }
        boolean draftToScheduled = false;
        for (JsonNode row : rows) {
            if ("DRAFT".equals(row.get("fromCode").asText())
                    && "SCHEDULED".equals(row.get("toCode").asText())) {
                draftToScheduled = true;
            }
        }
        assertThat(draftToScheduled).isTrue();
    }

    @Test
    void dropdownsReadTheOptionSetStoreAndBridgeLiteralLabels() throws Exception {
        String setId = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_option_sets
                    (id, code, name, status, sort_order, created_at, updated_at, version)
                VALUES (?, 'ISSUE_TYPE', 'Issue Type', 'ACTIVE', 1,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, setId);
        jdbc.update("""
                INSERT INTO platform_option_values
                    (id, option_set_id, code, label, status, sort_order,
                     metadata_json, created_at, updated_at, version)
                VALUES (?, ?, 'WORN', 'Worn', 'ACTIVE', 2,
                        '{"parentCode":"BRAKES"}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, UUID.randomUUID().toString(), setId);

        JsonNode rows = getJson(login("tech.a@test.local"), BASE + "/dropdowns/ISSUE_TYPE");
        assertThat(rows.size()).isEqualTo(1);
        JsonNode worn = rows.get(0);
        assertThat(fieldNames(worn)).containsExactlyInAnyOrder(
                "code", "labelKey", "label", "order", "selectable", "parentCode", "version");
        assertThat(worn.get("code").asText()).isEqualTo("WORN");
        assertThat(worn.get("labelKey").asText()).isEmpty();
        assertThat(worn.get("label").asText()).isEqualTo("Worn");
        assertThat(worn.get("parentCode").asText()).isEqualTo("BRAKES");
        assertThat(worn.get("selectable").asBoolean()).isTrue();
        assertThat(worn.get("order").asInt()).isEqualTo(2);
    }

    @Test
    void knownDropdownSetWithoutRowsIsAnEmptyList() throws Exception {
        JsonNode rows = getJson(login("tech.a@test.local"), BASE + "/dropdowns/REASON");
        assertThat(rows.isArray()).isTrue();
        assertThat(rows.size()).isZero();
    }

    @Test
    void secondCallWithIfNoneMatchReturns304() throws Exception {
        Login technician = login("tech.a@test.local");
        var first = mockMvc.perform(get(BASE + "/statuses/job")
                        .header("Authorization", "Bearer " + technician.accessToken()))
                .andExpect(status().isOk())
                .andExpect(header().exists("ETag"))
                .andExpect(header().string("Cache-Control", "private, max-age=60, must-revalidate"))
                .andReturn();
        String etag = first.getResponse().getHeader("ETag");
        assertThat(etag).isNotBlank();

        mockMvc.perform(get(BASE + "/statuses/job")
                        .header("Authorization", "Bearer " + technician.accessToken())
                        .header("If-None-Match", etag))
                .andExpect(status().isNotModified())
                .andExpect(header().string("ETag", etag));
    }

    @Test
    void deliveryAndConsentStatusesAreServed() throws Exception {
        Login platform = login("platform@test.local");
        assertThat(codes(getJson(platform, BASE + "/statuses/delivery")))
                .containsExactly("QUEUED", "SENT", "DELIVERED", "FAILED",
                        "RETRY_PENDING", "DEAD_LETTER");
        assertThat(codes(getJson(platform, BASE + "/statuses/consent")))
                .containsExactly("GRANTED", "NOT_GRANTED");
        assertThat(codes(getJson(platform, BASE + "/statuses/publication")))
                .contains("ACTIVE", "REVOKED", "PENDING_CONSENT");

        for (String type : List.of("delivery", "consent", "publication")) {
            for (JsonNode row : getJson(platform, BASE + "/statuses/" + type)) {
                assertThat(row.get("labelKey").asText()).matches("[A-Za-z0-9_.]+");
                assertThat(row.get("labelKey").asText()).doesNotContain(" ");
            }
        }
    }

    @Test
    void platformEnumDomainsCoverTheRemainingClientMaps() throws Exception {
        Login platform = login("platform@test.local");
        assertThat(codes(getJson(platform, BASE + "/enums/content-type")))
                .containsExactly("CATEGORY", "ITEM", "OPTION_SET", "OPTION_VALUE",
                        "TEMPLATE", "DOCUMENT_TYPE", "ISSUE_FIELD");
        assertThat(codes(getJson(platform, BASE + "/statuses/translation")))
                .containsExactly("DRAFT", "TRANSLATING", "REVIEW", "LIVE", "RETIRED");
        assertThat(codes(getJson(platform, BASE + "/enums/input-type")))
                .containsExactly("SELECT", "MULTI_SELECT", "NUMBER", "BOOLEAN", "TEXT");
        assertThat(codes(getJson(platform, BASE + "/enums/measurement-direction")))
                .containsExactly("HIGHER_IS_BETTER", "LOWER_IS_BETTER");
        assertThat(codes(getJson(platform, BASE + "/statuses/document-type")))
                .containsExactly("ACTIVE", "DRAFT", "RETIRED");

        assertThat(codes(getJson(platform, BASE + "/statuses/translation-status")))
                .containsExactly("DRAFT", "TRANSLATING", "REVIEW", "LIVE", "RETIRED");
        assertThat(codes(getJson(platform, BASE + "/statuses/document-type-status")))
                .containsExactly("ACTIVE", "DRAFT", "RETIRED");

        assertThat(codes(getJson(platform, BASE + "/enums/evidence-type")))
                .containsExactly("PHOTO", "VIDEO", "DOCUMENT");
        assertThat(codes(getJson(platform, BASE + "/enums/result")))
                .containsExactly("NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED",
                        "DEFECT_FOUND", "NOT_CHECKED", "NOT_APPLICABLE",
                        "COULD_NOT_VERIFY");
        assertThat(codes(getJson(platform, BASE + "/enums/severity")))
                .containsExactly("MINOR", "MODERATE", "MAJOR", "SAFETY_CRITICAL");

        for (String type : List.of("content-type", "input-type", "measurement-direction")) {
            for (JsonNode row : getJson(platform, BASE + "/enums/" + type)) {
                assertThat(row.get("labelKey").asText()).matches("[A-Za-z0-9_.]+");
                assertThat(row.get("labelKey").asText()).doesNotContain(" ");
                assertThat(row.get("tone").asText())
                        .isIn("neutral", "info", "success", "warning", "danger");
            }
        }
        for (String type : List.of("translation", "document-type")) {
            for (JsonNode row : getJson(platform, BASE + "/statuses/" + type)) {
                assertThat(row.get("labelKey").asText()).matches("[A-Za-z0-9_.]+");
                assertThat(row.get("labelKey").asText()).doesNotContain(" ");
                assertThat(row.get("tone").asText())
                        .isIn("neutral", "info", "success", "warning", "danger");
            }
        }
    }

    @Test
    void clientTaxonomyStatusMapsAreServed() throws Exception {
        Login platform = login("platform@test.local");
        assertThat(codes(getJson(platform, BASE + "/statuses/workshop")))
                .containsExactly("ACTIVE", "INACTIVE", "STANDBY", "RETIRED", "DEPOT_HUB",
                        "DISABLED", "DRAFT", "PUBLISHED");
        assertThat(codes(getJson(platform, BASE + "/statuses/checklist")))
                .containsExactly("ACTIVE", "DRAFT", "PUBLISHED", "RETIRED", "REVIEW",
                        "IN_REVIEW", "PENDING");
        assertThat(codes(getJson(platform, BASE + "/statuses/health")))
                .containsExactly("HEALTHY", "WARNING", "ERROR", "OK", "UNHEALTHY");
        assertThat(codes(getJson(platform, BASE + "/statuses/chip")))
                .containsExactly("DISABLED");

        for (String type : List.of("workshop", "checklist", "health", "chip")) {
            for (JsonNode row : getJson(platform, BASE + "/statuses/" + type)) {
                assertThat(row.get("labelKey").asText()).matches("[A-Za-z0-9_.]+");
                assertThat(row.get("labelKey").asText()).doesNotContain(" ");
            }
        }
    }

    @Test
    void unknownDomainsAre404() throws Exception {
        Login technician = login("tech.a@test.local");
        for (String path : List.of(
                "/statuses/nope", "/enums/nope", "/transitions/nope", "/dropdowns/NOPE")) {
            mockMvc.perform(get(BASE + path)
                            .header("Authorization", "Bearer " + technician.accessToken()))
                    .andExpect(status().isNotFound());
        }
    }

    @Test
    void everyEndpointRequiresAuthentication() throws Exception {
        for (String path : List.of(
                "/statuses/job", "/enums/role", "/transitions/job", "/dropdowns/ISSUE_TYPE")) {
            mockMvc.perform(get(BASE + path))
                    .andExpect(status().isUnauthorized());
        }
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken())
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private static List<String> codes(JsonNode rows) {
        List<String> codes = new ArrayList<>();
        rows.forEach(row -> codes.add(row.get("code").asText()));
        return codes;
    }

    private static List<String> strings(JsonNode values) {
        List<String> strings = new ArrayList<>();
        values.forEach(value -> strings.add(value.asText()));
        return strings;
    }

    private static Set<String> fieldNames(JsonNode node) {
        Set<String> names = new java.util.TreeSet<>();
        node.fieldNames().forEachRemaining(names::add);
        return names;
    }
}
