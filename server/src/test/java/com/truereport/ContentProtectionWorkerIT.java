package com.truereport;

import com.truereport.shared.i18n.ContentTranslationWorker;
import com.truereport.shared.i18n.TranslationProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ContentProtectionWorkerIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationWorker worker;

    @TestConfiguration
    static class DroppingProviderConfig {
        @Bean
        @Primary
        TranslationProvider droppingProvider() {
            return new TranslationProvider() {
                @Override
                public String id() {
                    return "dropping";
                }

                @Override
                public Map<String, String> translate(List<String> texts, String sourceLang,
                                                     String targetLang) {
                    Map<String, String> result = new LinkedHashMap<>();
                    for (String text : texts) {
                        // Intentionally drops every protection token.
                        result.put(text, "translated");
                    }
                    return result;
                }
            };
        }
    }

    @Test
    void lostPlaceholderFailsTheJobAndWritesNoTranslation() throws Exception {
        Login platform = login("platform@test.local");
        String code = "LOST-CAT-" + UUID.randomUUID().toString().substring(0, 8);
        MvcResult result = mockMvc.perform(post("/api/v1/platform/master/categories")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","name":"Check {name}"}
                                """.formatted(code)))
                .andExpect(status().is2xxSuccessful()).andReturn();
        String id = objectMapper.readTree(result.getResponse().getContentAsString())
                .get("id").asText();

        assertThat(worker.workOnce()).isPositive();

        String error = jdbc.queryForObject("""
                SELECT error FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'es'
                """, String.class, id);
        assertThat(error).contains("PLACEHOLDER_LOST");
        assertThat(jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'es'
                """, Integer.class, id)).isZero();
        assertThat(jdbc.queryForObject("""
                SELECT state FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'es'
                """, String.class, id)).isEqualTo("FAILED");
    }
}
