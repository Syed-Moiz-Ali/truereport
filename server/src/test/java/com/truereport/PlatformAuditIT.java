package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformAuditIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void filtersAndPaginatesAuditEvents() throws Exception {
        seedEvents();
        Login platform = login("platform@test.local");

        JsonNode page = getJson(platform,
                "/api/v1/platform/audit-events?action=SETTINGS_UPDATED&page=0&size=1");
        assertThat(page.get("total").asInt()).isEqualTo(2);
        assertThat(page.get("items").size()).isEqualTo(1);
        assertThat(page.get("items").get(0).get("action").asText())
                .isEqualTo("SETTINGS_UPDATED");

        JsonNode actor = getJson(platform,
                "/api/v1/platform/audit-events?actor=PLATFORM_ADMIN&page=0&size=10");
        assertThat(actor.get("total").asInt()).isGreaterThanOrEqualTo(2);

        JsonNode search = getJson(platform,
                "/api/v1/platform/audit-events?search=LANGUAGE_PUBLISHED&page=0&size=10");
        assertThat(search.get("total").asInt()).isEqualTo(1);
        assertThat(search.get("items").get(0).get("entityType").asText())
                .isEqualTo("LANGUAGE");

        JsonNode date = getJson(platform,
                "/api/v1/platform/audit-events?dateFrom=2000-01-01&dateTo=2999-01-01"
                        + "&page=0&size=10");
        assertThat(date.get("total").asInt()).isGreaterThanOrEqualTo(1);
    }

    @Test
    void exportsFilteredAuditEventsAndAuditsTheExport() throws Exception {
        seedEvents();
        Login platform = login("platform@test.local");

        var csv = mockMvc.perform(get("/api/v1/platform/audit-events/export")
                        .param("format", "csv")
                        .param("action", "SETTINGS_UPDATED")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type",
                        org.hamcrest.Matchers.containsString("text/csv")))
                .andReturn().getResponse().getContentAsString();
        assertThat(csv).contains("id,action,entityType,entityId")
                .contains("SETTINGS_UPDATED")
                .doesNotContain("LANGUAGE_PUBLISHED");

        var json = mockMvc.perform(get("/api/v1/platform/audit-events/export")
                        .param("format", "json")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        assertThat(json).contains("SETTINGS_UPDATED").contains("LANGUAGE_PUBLISHED");

        Integer exports = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_audit_events
                WHERE action_code = 'AUDIT_EVENTS_EXPORTED'
                """, Integer.class);
        assertThat(exports).isGreaterThanOrEqualTo(1);
    }

    @Test
    void auditEndpointsRequirePlatformAdmin() throws Exception {
        Login workshopAdmin = login("admin.a@test.local");
        mockMvc.perform(get("/api/v1/platform/audit-events?page=0&size=10")
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken()))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/platform/audit-events/export")
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken()))
                .andExpect(status().isForbidden());
    }

    private void seedEvents() {
        insert("SETTINGS_UPDATED", "PLATFORM_SETTINGS", "PLATFORM_ADMIN",
                "{\"sessionTimeoutMinutes\":60}");
        insert("SETTINGS_UPDATED", "PLATFORM_SETTINGS", "PLATFORM_ADMIN",
                "{\"webhooksEnabled\":true}");
        insert("LANGUAGE_PUBLISHED", "LANGUAGE", "PLATFORM_ADMIN",
                "{\"status\":\"LIVE\"}");
    }

    private void insert(String action, String entityType, String role,
                        String afterJson) {
        jdbc.update("""
                INSERT INTO platform_audit_events
                    (id, actor_user_id, actor_role, action_code, entity_type,
                     entity_id, reason, before_json, after_json, trace_id,
                     ip_address, occurred_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?, NULL, NULL, CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                role, action, entityType, UUID.randomUUID().toString(),
                "test reason", afterJson);
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        return objectMapper.readTree(mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }
}
