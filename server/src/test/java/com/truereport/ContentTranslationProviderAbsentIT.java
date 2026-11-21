package com.truereport;

import com.truereport.shared.i18n.ContentTranslationWorker;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = "truereport.i18n.translation.provider=none")
class ContentTranslationProviderAbsentIT extends IntegrationTestBase {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationWorker worker;

    @Test
    void savesSucceedAndJobsStayPendingWithoutAProvider() throws Exception {
        Login platform = login("platform@test.local");
        String code = "NOPROV-CAT-" + UUID.randomUUID().toString().substring(0, 8);
        MvcResult result = mockMvc.perform(post("/api/v1/platform/master/categories")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","name":"No provider category"}
                                """.formatted(code)))
                .andExpect(status().is2xxSuccessful()).andReturn();
        String id = objectMapper.readTree(result.getResponse().getContentAsString())
                .get("id").asText();

        assertThat(worker.workOnce()).isZero();
        Integer pending = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND state = 'PENDING'
                """, Integer.class, id);
        assertThat(pending).isEqualTo(2);
        Integer running = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND state <> 'PENDING'
                """, Integer.class, id);
        assertThat(running).isZero();
    }
}
