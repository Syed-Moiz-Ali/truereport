package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import com.truereport.uimessages.UiTextTranslationProvider;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = {
        "truereport.i18n.generation.synchronous=false"
})
class ContentGenerationCancelIT extends IntegrationTestBase {

    @org.springframework.beans.factory.annotation.Autowired
    JdbcTemplate jdbc;

    @AfterEach
    void cleanupAudit() {
        jdbc.update("""
                DELETE FROM platform_audit_events
                WHERE entity_type = 'LANGUAGE' AND entity_id = 'hi'
                """);
    }

    @TestConfiguration
    static class TranslationConfig {
        @Bean
        @Primary
        SlowProvider slowProvider() {
            return new SlowProvider();
        }
    }

    static class SlowProvider implements UiTextTranslationProvider {
        @Override
        public String translate(String text, String targetLanguage) {
            try {
                Thread.sleep(200);
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
            }
            return "[" + targetLanguage + "] " + text;
        }
    }

    @Test
    void cancelMovesRunningGenerationToCancelled() throws Exception {
        Login platform = login("platform@test.local");
        postJson(platform, "/api/v1/platform/seed/default-checklist", "{}");
        postJson(platform, "/api/v1/platform/i18n/languages", """
                {"code":"hi","nativeName":"Hindi","direction":"ltr"}
                """);

        JsonNode started = postJson(platform,
                "/api/v1/platform/i18n/languages/hi/content/generate",
                "{\"entityTypes\":[\"CATEGORY\"],\"force\":true}");
        assertThat(started.get("jobStatus").asText()).isIn("QUEUED", "RUNNING");

        JsonNode cancelled = postJson(platform,
                "/api/v1/platform/i18n/languages/hi/content/generation/cancel", "{}");
        assertThat(cancelled.get("jobStatus").asText()).isEqualTo("CANCELLED");

        JsonNode status = getJson(platform,
                "/api/v1/platform/i18n/languages/hi/content/generation");
        assertThat(status.get("jobStatus").asText()).isEqualTo("CANCELLED");
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
