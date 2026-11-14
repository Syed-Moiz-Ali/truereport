package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformLanguageDeleteIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void deleteUnusedLanguageRemovesTranslationsAndAudits() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"xx","nativeName":"Test language","direction":"ltr"}
                """);
        JsonNode category = getJson(platform, "/api/v1/platform/master/categories").get(0);
        putJson(platform, "/api/v1/platform/i18n/translations", """
                {"entityType":"CATEGORY","entityId":"%s","field":"name",
                 "language":"xx","text":"xx-name","status":"DRAFT"}
                """.formatted(category.get("id").asText()));

        mockMvc.perform(delete("/api/v1/platform/i18n/languages/xx")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isNoContent());

        boolean found = false;
        for (JsonNode language : getJson(platform, "/api/v1/platform/i18n/languages")) {
            if ("xx".equals(language.get("code").asText())) {
                found = true;
            }
        }
        assertThat(found).isFalse();
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_translations WHERE lang = 'xx'",
                Integer.class)).isZero();
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_audit_events
                WHERE action_code = 'LANGUAGE_DELETED' AND entity_id = 'xx'
                """, Integer.class)).isEqualTo(1);
    }

    @Test
    void defaultLanguageCannotBeDeleted() throws Exception {
        Login platform = login("platform@test.local");
        mockMvc.perform(delete("/api/v1/platform/i18n/languages/en")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isConflict());
    }

    @Test
    void languageReferencedByUserPreferenceCannotBeDeleted() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"yy","nativeName":"Referenced language","direction":"ltr"}
                """);
        jdbc.update("""
                INSERT INTO platform_user_language_preferences
                    (user_id, language_code, updated_at)
                VALUES (?, 'yy', CURRENT_TIMESTAMP)
                """, fixture.platform().getId().toString());

        mockMvc.perform(delete("/api/v1/platform/i18n/languages/yy")
                        .header("Authorization", bearer(platform)))
                .andExpect(status().isConflict());
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

    private String bearer(Login login) {
        return "Bearer " + login.accessToken();
    }
}
