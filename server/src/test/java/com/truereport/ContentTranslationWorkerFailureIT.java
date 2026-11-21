package com.truereport;

import com.truereport.shared.i18n.ContentTranslationWorker;
import com.truereport.shared.i18n.TranslationProvider;
import com.truereport.shared.i18n.TranslationProviderException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = {
        "truereport.i18n.translation.max-attempts=2",
        "truereport.i18n.translation.backoff-seconds=0"
})
class ContentTranslationWorkerFailureIT extends IntegrationTestBase {

    static volatile String mode = "mismatch";

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationWorker worker;

    @TestConfiguration
    static class FailingProviderConfig {
        @Bean
        @Primary
        TranslationProvider failingTranslationProvider() {
            return new TranslationProvider() {
                @Override
                public String id() {
                    return "failing";
                }

                @Override
                public Map<String, String> translate(List<String> texts, String sourceLang,
                                                     String targetLang) {
                    if ("nonretryable".equals(mode)) {
                        throw new TranslationProviderException(
                                "language is not supported", false);
                    }
                    return Map.of();
                }
            };
        }
    }

    @Test
    void providerSizeMismatchRetriesThenFailsWithoutThrowing() throws Exception {
        mode = "mismatch";
        Login platform = login("platform@test.local");
        String id = createCategory(platform);

        assertThat(worker.workOnce()).isPositive();
        assertThat(state(id, "es")).isEqualTo("PENDING");
        assertThat(attempts(id, "es")).isEqualTo(1);

        assertThat(worker.workOnce()).isPositive();
        assertThat(state(id, "es")).isEqualTo("FAILED");
        assertThat(attempts(id, "es")).isEqualTo(2);
        String error = jdbc.queryForObject("""
                SELECT error FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'es'
                """, String.class, id);
        assertThat(error).contains("size mismatch");
        assertThat(state(id, "fr")).isEqualTo("FAILED");
    }

    @Test
    void nonRetryableProviderErrorFailsImmediately() throws Exception {
        mode = "nonretryable";
        Login platform = login("platform@test.local");
        String id = createCategory(platform);

        assertThat(worker.workOnce()).isPositive();

        assertThat(state(id, "es")).isEqualTo("FAILED");
        assertThat(attempts(id, "es")).isEqualTo(1);
        String error = jdbc.queryForObject("""
                SELECT error FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'es'
                """, String.class, id);
        assertThat(error).contains("language is not supported");
    }

    private String createCategory(Login platform) throws Exception {
        String code = "FAIL-CAT-" + UUID.randomUUID().toString().substring(0, 8);
        MvcResult result = mockMvc.perform(post("/api/v1/platform/master/categories")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","name":"Failing category"}
                                """.formatted(code)))
                .andExpect(status().is2xxSuccessful()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("id").asText();
    }

    private String state(String id, String lang) {
        return jdbc.queryForObject("""
                SELECT state FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = ?
                """, String.class, id, lang);
    }

    private int attempts(String id, String lang) {
        return jdbc.queryForObject("""
                SELECT attempts FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = ?
                """, Integer.class, id, lang);
    }
}
