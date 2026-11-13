package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Dynamic language lifecycle: registry status, translation overlay backlog,
 * coverage math, publish gating, new-content gating, workshop CRUD gap and
 * the platform overview aggregation.
 */
class PlatformLanguageLifecycleIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void lifecycleTransitionsForwardOnlyWithRetireAndReopen() throws Exception {
        Login platform = login("platform@test.local");

        JsonNode created = postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية",
                 "nativeName":"中文","direction":"ltr","active":true,"sortOrder":10}
                """);
        assertThat(created.get("code").asText()).isEqualTo("zh-hans");
        assertThat(created.get("status").asText()).isEqualTo("DRAFT");
        assertThat(created.get("active").asBoolean()).isFalse();

        // Forward jump is allowed; backward movement is rejected.
        JsonNode translating = postStatus(platform, "zh-Hans", "TRANSLATING");
        assertThat(translating.get("status").asText()).isEqualTo("TRANSLATING");

        mockMvc.perform(post("/api/v1/platform/i18n/languages/zh-Hans/status")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"DRAFT\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LANGUAGE_STATUS_TRANSITION_INVALID"));

        JsonNode retired = postStatus(platform, "zh-Hans", "RETIRED");
        assertThat(retired.get("status").asText()).isEqualTo("RETIRED");

        mockMvc.perform(post("/api/v1/platform/i18n/languages/zh-Hans/status")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"REVIEW\"}"))
                .andExpect(status().isConflict());

        JsonNode reopened = postStatus(platform, "zh-Hans", "DRAFT");
        assertThat(reopened.get("status").asText()).isEqualTo("DRAFT");

        mockMvc.perform(post("/api/v1/platform/i18n/languages/zh-Hans/status")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"KLINGON\"}"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void draftLanguageHiddenFromPublicList() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية","nativeName":"中文"}
                """);

        JsonNode publicList = getAnonymousJson("/api/v1/i18n/languages");
        Set<String> codes = new HashSet<>();
        publicList.forEach(node -> codes.add(node.get("code").asText()));
        assertThat(codes).contains("en", "ar");
        assertThat(codes).doesNotContain("zh-hans");

        JsonNode adminList = getJson(platform, "/api/v1/platform/i18n/languages");
        Set<String> adminCodes = new HashSet<>();
        adminList.forEach(node -> adminCodes.add(node.get("code").asText()));
        assertThat(adminCodes).contains("zh-hans");

        // A DRAFT language cannot be selected as the personal language.
        mockMvc.perform(put("/api/v1/i18n/me")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"language\":\"zh-Hans\"}"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void backlogContainsAllLiveEntityGroups() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية","nativeName":"中文"}
                """);

        JsonNode backlog = getJson(platform, "/api/v1/platform/i18n/languages/zh-Hans/backlog");
        assertThat(backlog.get("language").get("code").asText()).isEqualTo("zh-hans");
        assertThat(backlog.get("totalRequired").asInt()).isGreaterThan(0);
        assertThat(backlog.get("approvedCount").asInt()).isZero();
        assertThat(backlog.get("coveragePercent").asInt()).isZero();

        Set<String> groups = new HashSet<>();
        for (JsonNode group : backlog.get("groups")) {
            groups.add(group.get("entityType").asText());
            assertThat(group.get("total").asInt()).isGreaterThan(0);
            for (JsonNode item : group.get("items")) {
                assertThat(item.get("status").asText()).isEqualTo("MISSING");
                assertThat(item.get("defaultText").asText()).isNotBlank();
                assertThat(item.get("text").isNull()).isTrue();
            }
        }
        assertThat(groups).containsExactlyInAnyOrder("CATEGORY", "ITEM", "OPTION_SET",
                "OPTION_VALUE", "TEMPLATE", "DOCUMENT_TYPE", "ISSUE_FIELD");
    }

    @Test
    void upsertMovesLanguageToTranslatingAndCoverageMath() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية","nativeName":"中文"}
                """);

        JsonNode backlog = getJson(platform, "/api/v1/platform/i18n/languages/zh-Hans/backlog");
        JsonNode first = backlog.get("groups").get(0).get("items").get(0);

        JsonNode saved = putJson(platform, "/api/v1/platform/i18n/translations", """
                {"entityType":"%s","entityId":"%s","field":"%s","language":"zh-Hans",
                 "text":"翻译文本","status":"APPROVED"}
                """.formatted(first.get("entityType").asText(), first.get("entityId").asText(),
                first.get("field").asText()));
        assertThat(saved.get("status").asText()).isEqualTo("APPROVED");
        assertThat(saved.get("text").asText()).isEqualTo("翻译文本");
        assertThat(saved.get("entityCode").asText()).isNotBlank();

        JsonNode all = getJson(platform, "/api/v1/platform/i18n/languages");
        String status = null;
        for (JsonNode entry : all) {
            if ("zh-hans".equals(entry.get("code").asText())) {
                status = entry.get("status").asText();
            }
        }
        assertThat(status).isEqualTo("TRANSLATING");

        JsonNode coverage = getJson(platform, "/api/v1/platform/i18n/coverage?language=zh-Hans");
        assertThat(coverage.get("language").asText()).isEqualTo("zh-hans");
        assertThat(coverage.get("totalRequired").asInt())
                .isEqualTo(backlog.get("totalRequired").asInt());
        assertThat(coverage.get("approvedCount").asInt()).isEqualTo(1);
        assertThat(coverage.get("coveragePercent").asInt()).isGreaterThanOrEqualTo(0);

        JsonNode refreshed = getJson(platform, "/api/v1/platform/i18n/languages/zh-Hans/backlog");
        assertThat(refreshed.get("approvedCount").asInt()).isEqualTo(1);
    }

    @Test
    void publishBlockedUntilCompleteThenLive() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية","nativeName":"中文"}
                """);

        mockMvc.perform(post("/api/v1/platform/i18n/languages/zh-Hans/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REQUIRED"));

        approveEverything(platform);
        attachUiMessages("zh-Hans");

        JsonNode published = postJson(platform,
                "/api/v1/platform/i18n/languages/zh-Hans/publish", "{}");
        assertThat(published.get("status").asText()).isEqualTo("LIVE");
        assertThat(published.get("coveragePercent").asInt()).isEqualTo(100);

        JsonNode publicList = getAnonymousJson("/api/v1/i18n/languages");
        Set<String> codes = new HashSet<>();
        publicList.forEach(node -> codes.add(node.get("code").asText()));
        assertThat(codes).contains("zh-hans");

        JsonNode me = putJson(platform, "/api/v1/i18n/me", "{\"language\":\"zh-Hans\"}");
        assertThat(me.get("language").asText()).isEqualTo("zh-hans");
    }

    @Test
    void newContentGatedWhenExtendedLanguageLive() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية","nativeName":"中文"}
                """);
        approveEverything(platform);
        attachUiMessages("zh-Hans");
        postJson(platform, "/api/v1/platform/i18n/languages/zh-Hans/publish", "{}");

        // Creating new live content is blocked while zh-Hans is LIVE.
        mockMvc.perform(post("/api/v1/platform/master/categories")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"CAT-GATED","nameEn":"Gated","nameAr":"محجوب","sortOrder":99}
                                """))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REQUIRED"));

        mockMvc.perform(post("/api/v1/platform/document-types")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"GATED_DOC","nameEn":"Gated doc","nameAr":"مستند محجوب"}
                                """))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REQUIRED"));

        // Publishing an item without approved zh-Hans overlays is blocked.
        JsonNode item = getJson(platform, "/api/v1/platform/master/items?search=BRK-PAD-01");
        String itemId = item.get(0).get("id").asText();
        JsonNode draft = postJson(platform,
                "/api/v1/platform/master/items/" + itemId + "/versions", "{}");
        String versionId = draft.get("versions").get(0).get("id").asText();
        mockMvc.perform(post("/api/v1/platform/master/items/" + itemId
                                + "/versions/" + versionId + "/publish")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REQUIRED"));
    }

    @Test
    void workshopUpdateDeactivateAndReactivate() throws Exception {
        Login platform = login("platform@test.local");
        UUID workshopId = fixture.workshopA().getId();

        JsonNode updated = putJson(platform, "/api/v1/platform/workshops/" + workshopId, """
                {"name":"Workshop A Renamed","location":"North Branch","contactEmail":"a@example.test"}
                """);
        assertThat(updated.get("id").asText()).isEqualTo(workshopId.toString());
        assertThat(updated.get("name").asText()).isEqualTo("Workshop A Renamed");
        assertThat(updated.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(updated.has("memberCount")).isTrue();

        JsonNode deactivated = postJson(platform,
                "/api/v1/platform/workshops/" + workshopId + "/deactivate",
                "{\"reason\":\"maintenance\"}");
        assertThat(deactivated.get("status").asText()).isEqualTo("DISABLED");

        JsonNode reactivated = postJson(platform,
                "/api/v1/platform/workshops/" + workshopId + "/reactivate",
                "{\"reason\":\"reopened\"}");
        assertThat(reactivated.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(reactivated.get("name").asText()).isEqualTo("Workshop A Renamed");
    }

    @Test
    void overviewShape() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");

        JsonNode overview = getJson(platform, "/api/v1/platform/overview");
        for (String key : List.of("workshops", "staff", "jobs", "reports",
                "checklist", "languages", "recentActivity", "alerts")) {
            assertThat(overview.has(key)).as("overview.%s", key).isTrue();
        }
        assertThat(overview.get("workshops").get("total").asInt()).isGreaterThanOrEqualTo(2);
        assertThat(overview.get("workshops").get("active").asInt()).isGreaterThanOrEqualTo(1);
        assertThat(overview.get("checklist").get("categories").asInt()).isEqualTo(6);
        assertThat(overview.get("checklist").get("templates").asInt()).isEqualTo(1);
        assertThat(overview.get("languages").get("live").asInt()).isGreaterThanOrEqualTo(2);
        assertThat(overview.get("recentActivity").isArray()).isTrue();
        assertThat(overview.get("recentActivity").size()).isLessThanOrEqualTo(8);
        assertThat(overview.get("alerts").isArray()).isTrue();
        for (JsonNode alert : overview.get("alerts")) {
            assertThat(alert.has("severity")).isTrue();
            assertThat(alert.has("title")).isTrue();
            assertThat(alert.has("route")).isTrue();
        }
    }

    @Test
    void directStatusLiveRequiresApprovalsJustLikePublish() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"zh-Hans","nameEn":"Chinese","nameAr":"الصينية","nativeName":"中文"}
                """);

        mockMvc.perform(post("/api/v1/platform/i18n/languages/zh-Hans/status")
                        .header("Authorization", bearer(platform))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"LIVE\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REQUIRED"));

        mockMvc.perform(post("/api/v1/platform/i18n/languages/zh-Hans/publish")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("TRANSLATION_REQUIRED"));

        approveEverything(platform);
        attachUiMessages("zh-Hans");

        JsonNode live = postStatus(platform, "zh-Hans", "LIVE");
        assertThat(live.get("status").asText()).isEqualTo("LIVE");

        JsonNode publicList = getAnonymousJson("/api/v1/i18n/languages");
        Set<String> codes = new HashSet<>();
        publicList.forEach(node -> codes.add(node.get("code").asText()));
        assertThat(codes).contains("zh-hans");
    }

    // ------------------------------------------------------------------ helpers

    private void attachUiMessages(String code) {
        jdbc.update("""
                UPDATE platform_languages SET ui_messages_path = 'platform_admin/en.json'
                WHERE LOWER(code) = LOWER(?)
                """, code);
    }

    private void approveEverything(Login login) throws Exception {
        JsonNode backlog = getJson(login, "/api/v1/platform/i18n/languages/zh-Hans/backlog");
        List<String[]> queue = new ArrayList<>();
        for (JsonNode group : backlog.get("groups")) {
            for (JsonNode item : group.get("items")) {
                queue.add(new String[]{item.get("entityType").asText(),
                        item.get("entityId").asText(), item.get("field").asText()});
            }
        }
        assertThat(queue).isNotEmpty();
        for (String[] entry : queue) {
            putJson(login, "/api/v1/platform/i18n/translations", """
                    {"entityType":"%s","entityId":"%s","field":"%s","language":"zh-Hans",
                     "text":"翻译-%s-%s","status":"APPROVED"}
                    """.formatted(entry[0], entry[1], entry[2], entry[1], entry[2]));
        }
        JsonNode coverage = getJson(login, "/api/v1/platform/i18n/coverage?language=zh-Hans");
        assertThat(coverage.get("approvedCount").asInt())
                .isEqualTo(coverage.get("totalRequired").asInt());
    }

    private JsonNode postStatus(Login login, String code, String status) throws Exception {
        return postJson(login, "/api/v1/platform/i18n/languages/" + code + "/status",
                "{\"status\":\"%s\"}".formatted(status));
    }

    private String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }

    private JsonNode postJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(post(path)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode putJson(Login login, String path, String body) throws Exception {
        var result = mockMvc.perform(put(path)
                        .header("Authorization", bearer(login))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", bearer(login)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getAnonymousJson(String path) throws Exception {
        var result = mockMvc.perform(get(path))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
