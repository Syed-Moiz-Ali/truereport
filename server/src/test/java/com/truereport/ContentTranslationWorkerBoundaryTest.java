package com.truereport;

import com.truereport.shared.i18n.ContentTranslationWorker;
import com.truereport.shared.i18n.TranslationJobStore;
import com.truereport.shared.i18n.TranslationProvider;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)
@TestPropertySource(properties = {
        "truereport.i18n.translation.stale-timeout-seconds=1",
        "truereport.i18n.translation.worker-enabled=false"
})
class ContentTranslationWorkerBoundaryTest {

    static final AtomicBoolean TRANSACTION_SEEN = new AtomicBoolean(false);
    static final AtomicBoolean DB_READ_OK = new AtomicBoolean(false);

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    TranslationJobStore jobs;

    @Autowired
    ContentTranslationWorker worker;

    private String categoryId;

    @TestConfiguration
    static class BoundaryProviderConfig {
        @Bean
        @Primary
        TranslationProvider boundaryProvider(JdbcTemplate jdbcTemplate) {
            return new TranslationProvider() {
                @Override
                public String id() {
                    return "boundary";
                }

                @Override
                public Map<String, String> translate(List<String> texts, String sourceLang,
                                                     String targetLang) {
                    TRANSACTION_SEEN.set(
                            TransactionSynchronizationManager.isActualTransactionActive());
                    jdbcTemplate.queryForObject("SELECT 1", Integer.class);
                    DB_READ_OK.set(true);
                    Map<String, String> result = new LinkedHashMap<>();
                    for (String text : texts) {
                        result.put(text, "[[" + targetLang + "]] " + text);
                    }
                    return result;
                }
            };
        }
    }

    @AfterEach
    void cleanUp() {
        if (categoryId == null) {
            return;
        }
        jdbc.update("DELETE FROM content_translation WHERE entity_id = ?", categoryId);
        jdbc.update("DELETE FROM content_translation_job WHERE entity_id = ?", categoryId);
        jdbc.update("DELETE FROM platform_categories WHERE id = ?", categoryId);
    }

    @Test
    void providerRunsWithoutAnOpenTransactionAndStaleRunningJobsRecover() {
        categoryId = createCategory("BOUNDARY-CAT-" + UUID.randomUUID().toString().substring(0, 8),
                "Boundary");
        jobs.enqueue("CATEGORY", categoryId, "name", "es", TranslationJobStore.FROM_CANONICAL);
        jobs.enqueue("CATEGORY", categoryId, "name", "fr", TranslationJobStore.FROM_CANONICAL);

        // Simulate a crash after claim: a RUNNING lease older than the timeout.
        jdbc.update("""
                UPDATE content_translation_job
                SET state = 'RUNNING', attempts = 1, updated_at = ?
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = 'fr'
                """, LocalDateTime.now().minusMinutes(10), categoryId);

        assertThat(worker.workOnce()).isEqualTo(2);

        assertThat(TRANSACTION_SEEN).as("provider must run outside a transaction").isFalse();
        assertThat(DB_READ_OK).isTrue();
        assertThat(body("es")).isEqualTo("[[es]] Boundary");
        assertThat(body("fr")).isEqualTo("[[fr]] Boundary");
        assertThat(state("es")).isEqualTo("DONE");
        assertThat(state("fr")).isEqualTo("DONE");
    }

    private String createCategory(String code, String name) {
        String id = UUID.randomUUID().toString();
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 0, 'ACTIVE', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name);
        return id;
    }

    private String body(String lang) {
        return jdbc.queryForObject("""
                SELECT body FROM content_translation
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND field_name = 'name'
                  AND lang = ?
                """, String.class, categoryId, lang);
    }

    private String state(String lang) {
        return jdbc.queryForObject("""
                SELECT state FROM content_translation_job
                WHERE entity_type = 'CATEGORY' AND entity_id = ? AND lang = ?
                """, String.class, categoryId, lang);
    }
}
