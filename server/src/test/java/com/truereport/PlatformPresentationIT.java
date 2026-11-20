package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.uimessages.PlatformUiMessageCatalog;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * The Platform Admin dashboard must not derive copy or formatting in Dart:
 * the overview and config-health endpoints own labels, keys and display values.
 */
class PlatformPresentationIT extends IntegrationTestBase {

    private static final Set<String> TONES =
            Set.of("neutral", "info", "success", "warning", "danger");
    private static final Map<String, String[]> ALERT_KEYS = Map.of(
            "checklistIncomplete", new String[]{
                    "dashboard.alert.checklist.title", "dashboard.alert.checklist.body",
                    "dashboard.alert.checklist.action"},
            "languagesIncomplete", new String[]{
                    "dashboard.alert.languages.title", "dashboard.alert.languages.body",
                    "dashboard.alert.languages.action"},
            "reportFailures", new String[]{
                    "dashboard.alert.reportsFailed.title", "dashboard.alert.reportsFailed.body",
                    "dashboard.alert.reportsFailed.action"},
            "unpublishedReports", new String[]{
                    "dashboard.alert.reportsUnpublished.title",
                    "dashboard.alert.reportsUnpublished.body",
                    "dashboard.alert.reportsUnpublished.action"});

    @Autowired
    PlatformUiMessageCatalog uiMessages;

    @Autowired
    org.springframework.jdbc.core.JdbcTemplate jdbc;

    @Test
    void metricCardsAreOrderedFormattedAndKeyed() throws Exception {
        JsonNode overview = getJson(login("platform@test.local"), "/api/v1/platform/overview");
        JsonNode cards = overview.get("metricCards");

        assertThat(cards.isArray()).isTrue();
        assertThat(cards.size()).isEqualTo(7);
        int previousOrder = 0;
        List<String> codes = new java.util.ArrayList<>();
        Map<String, String> catalog = uiMessages.namespace("platform_admin", "en").values();
        for (JsonNode card : cards) {
            assertThat(fieldNames(card)).containsExactlyInAnyOrder(
                    "code", "labelKey", "value", "captionKey", "tone", "order");
            assertThat(card.get("value").isTextual()).as("formatted value").isTrue();
            assertThat(card.get("value").asText()).matches("[0-9,]+");
            assertThat(card.get("order").asInt()).isGreaterThan(previousOrder);
            previousOrder = card.get("order").asInt();
            assertThat(TONES).contains(card.get("tone").asText());
            assertThat(catalog).containsKey(card.get("labelKey").asText());
            assertThat(catalog).containsKey(card.get("captionKey").asText());
            codes.add(card.get("code").asText());
        }
        assertThat(codes).containsExactly("activeWorkshops", "technicians", "activeJobs",
                "pendingReviews", "publishedReports", "checklistHealth", "languagesLive");
    }

    @Test
    void localizedAlertsUseResolvableKeysAndStringArgs() throws Exception {
        jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order,
                     status, created_at, updated_at, version)
                VALUES ('zz-test', 'Test', 'ltr', FALSE, FALSE, 99, 'DRAFT',
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """);
        JsonNode overview = getJson(login("platform@test.local"), "/api/v1/platform/overview");
        JsonNode alerts = overview.get("localizedAlerts");
        Map<String, String> catalog = uiMessages.namespace("platform_admin", "en").values();

        assertThat(alerts.isArray()).isTrue();
        assertThat(alerts.size()).isGreaterThan(0);
        int previousOrder = 0;
        for (JsonNode alert : alerts) {
            String code = alert.get("code").asText();
            assertThat(ALERT_KEYS).as("alert code must have catalog keys: " + code)
                    .containsKey(code);
            assertThat(fieldNames(alert)).containsExactlyInAnyOrder(
                    "code", "severity", "order", "titleKey", "bodyKey", "args", "action");
            assertThat(TONES).contains(alert.get("severity").asText());
            assertThat(alert.get("order").asInt()).isGreaterThan(previousOrder);
            previousOrder = alert.get("order").asInt();

            String[] expected = ALERT_KEYS.get(code);
            assertThat(alert.get("titleKey").asText()).isEqualTo(expected[0]);
            assertThat(alert.get("bodyKey").asText()).isEqualTo(expected[1]);
            assertThat(alert.get("action").get("labelKey").asText()).isEqualTo(expected[2]);
            assertThat(catalog).containsKeys(expected[0], expected[1], expected[2]);

            JsonNode args = alert.get("args");
            assertThat(args.isObject()).isTrue();
            args.fields().forEachRemaining(entry ->
                    assertThat(entry.getValue().isTextual())
                            .as("arg " + entry.getKey()).isTrue());
            assertThat(alert.get("action").get("route").asText()).startsWith("/");
        }
    }

    @Test
    void configHealthChecksExposeKeysAndTones() throws Exception {
        JsonNode response = getJson(login("platform@test.local"),
                "/api/v1/platform/config-health");
        JsonNode checks = response.get("checks");
        Map<String, String> catalog = uiMessages.namespace("platform_admin", "en").values();

        assertThat(checks.isArray()).isTrue();
        assertThat(checks.size()).isGreaterThanOrEqualTo(6);
        for (JsonNode check : checks) {
            assertThat(fieldNames(check)).contains(
                    "code", "status", "labelKey", "descriptionKey", "tone");
            assertThat(TONES).contains(check.get("tone").asText());
            assertThat(catalog).containsKey(check.get("labelKey").asText());
            assertThat(catalog).containsKey(check.get("descriptionKey").asText());
            assertThat(check.get("code").asText()).isNotBlank();
            assertThat(check.get("status").asText()).isIn("OK", "WARNING", "ERROR");
        }
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private static Set<String> fieldNames(JsonNode node) {
        Set<String> names = new HashSet<>();
        node.fieldNames().forEachRemaining(names::add);
        return names;
    }
}
