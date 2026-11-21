package com.truereport;

import com.truereport.shared.i18n.ContentBackfillService;
import com.truereport.shared.i18n.ContentTranslationService;
import com.truereport.shared.i18n.ContentTranslationWorker;
import com.truereport.shared.i18n.TranslationProvider;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
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

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Worker-level regressions from the live LibreTranslate run: per-text
 * placeholders, one lost token failing one job, NO_CHANGE rejection and locked
 * glossary terms.
 */
@SpringBootTest
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)
@TestPropertySource(properties = {
        "truereport.i18n.translation.worker-enabled=false"
})
class TranslationWorkerQualityTest {

    enum Mode {
        PREFIX, ECHO, DROP_MIDDLE_TOKEN, AMPERSAND, TRUNCATE, DANGLING, SHORT
    }

    static volatile Mode mode = Mode.PREFIX;
    static final AtomicReference<List<String>> SEEN = new AtomicReference<>(List.of());

    private static final Pattern TOKEN = Pattern.compile("#\\d+#");

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ContentTranslationWorker worker;

    @Autowired
    ContentBackfillService backfill;

    @Autowired
    ContentTranslationService translations;

    private final List<String> categoryIds = new ArrayList<>();
    private final List<String> itemIds = new ArrayList<>();
    private final List<String> versionIds = new ArrayList<>();

    @TestConfiguration
    static class QualityProviderConfig {
        @Bean
        @Primary
        TranslationProvider qualityProvider() {
            return new TranslationProvider() {
                @Override
                public String id() {
                    return "quality";
                }

                @Override
                public Map<String, String> translate(List<String> texts, String sourceLang,
                                                     String targetLang) {
                    SEEN.set(List.copyOf(texts));
                    Map<String, String> result = new LinkedHashMap<>();
                    for (int index = 0; index < texts.size(); index++) {
                        String text = texts.get(index);
                        switch (mode) {
                            case ECHO -> result.put(text, text);
                            case DROP_MIDDLE_TOKEN -> result.put(text, index == 1
                                    ? dropFirstToken(text) : "ES:: " + text);
                            case AMPERSAND -> result.put(text, "ES:: "
                                    + text.replace(" and ", " y "));
                            case TRUNCATE -> result.put(text, "ES::");
                            case DANGLING -> result.put(text, "ES:: Suspensi\u00f3n, Direcci\u00f3n &");
                            case SHORT -> result.put(text, "Radiador");
                            default -> result.put(text, "ES:: " + text);
                        }
                    }
                    return result;
                }
            };
        }
    }

    private static String dropFirstToken(String text) {
        Matcher matcher = TOKEN.matcher(text);
        return matcher.find()
                ? text.substring(0, matcher.start()) + text.substring(matcher.end())
                : text;
    }

    @BeforeEach
    void reset() {
        mode = Mode.PREFIX;
        SEEN.set(List.of());
        jdbc.update("DELETE FROM content_translation_job");
    }

    @AfterEach
    void cleanUp() {
        List<String> all = new ArrayList<>();
        all.addAll(categoryIds);
        all.addAll(itemIds);
        all.addAll(versionIds);
        for (String id : all) {
            jdbc.update("DELETE FROM content_translation WHERE entity_id = ?", id);
            jdbc.update("DELETE FROM content_translation_job WHERE entity_id = ?", id);
        }
        for (String id : itemIds) {
            jdbc.update("UPDATE platform_items SET current_published_version_id = NULL WHERE id = ?",
                    id);
        }
        for (String id : versionIds) {
            jdbc.update("DELETE FROM platform_item_versions WHERE id = ?", id);
        }
        for (String id : itemIds) {
            jdbc.update("DELETE FROM platform_items WHERE id = ?", id);
        }
        for (String id : categoryIds) {
            jdbc.update("DELETE FROM platform_categories WHERE id = ?", id);
        }
        categoryIds.clear();
        itemIds.clear();
        versionIds.clear();
    }

    @Test
    void batchPlaceholdersAreIsolatedAndOneLostTokenFailsOnlyThatJob() {
        mode = Mode.DROP_MIDDLE_TOKEN;
        String categoryId = category("Q-CAT-" + suffix(), "Body");
        Map<String, String> sources = Map.of(
                "label", "Pressure {min}",
                "instruction", "Torque to 12 V",
                "standardSpec", "VIN 1HGCM82633A004352 range 85\u2013100");
        String versionId = item("Q-ITEM-" + suffix(), categoryId, sources);

        ContentBackfillService.Result enqueued = backfill.backfill(List.of("es"),
                List.of("ITEM"), false);
        assertThat(enqueued.enqueued()).isEqualTo(3);

        worker.workOnce();

        List<String> texts = SEEN.get();
        assertThat(texts).hasSize(3);
        List<Set<String>> tokenSets = texts.stream().map(TranslationWorkerQualityTest::tokens)
                .toList();
        for (int left = 0; left < tokenSets.size(); left++) {
            assertThat(tokenSets.get(left)).as("protected text %d", left).isNotEmpty();
            for (int right = left + 1; right < tokenSets.size(); right++) {
                assertThat(tokenSets.get(left))
                        .as("batch texts %d and %d must not share tokens", left, right)
                        .doesNotContainAnyElementsOf(tokenSets.get(right));
            }
        }

        Map<String, String> states = statesByField(versionId);
        List<String> failedFields = states.entrySet().stream()
                .filter(entry -> "FAILED".equals(entry.getValue()))
                .map(Map.Entry::getKey).toList();
        assertThat(failedFields).as("exactly one job loses its token").hasSize(1);
        assertThat(failedJobError(versionId, failedFields.get(0)))
                .contains("PLACEHOLDER_LOST")
                .doesNotContain("PLACEHOLDER_LOST: PLACEHOLDER_LOST");

        for (Map.Entry<String, String> entry : sources.entrySet()) {
            if (entry.getKey().equals(failedFields.get(0))) {
                assertThat(rowCount(versionId, entry.getKey())).isZero();
                continue;
            }
            String body = translatedText(versionId, entry.getKey());
            assertThat(states.get(entry.getKey())).isEqualTo("DONE");
            assertThat(body)
                    .as("%s keeps its own placeholders", entry.getKey())
                    .isEqualTo("ES:: " + entry.getValue())
                    .doesNotContain("#T");
        }
    }

    @Test
    void ampersandsAreTranslatedAndUrlsStayIntact() {
        mode = Mode.AMPERSAND;
        String sentenceId = category("Q-AMP-" + suffix(),
                "Suspension, Steering & Underbody");
        String urlId = category("Q-URL-" + suffix(),
                "See https://example.test/a?x=1&y=2 & more");

        backfill.backfill(List.of("es"), List.of("CATEGORY"), false);
        worker.workOnce();

        assertThat(SEEN.get()).hasSize(2).noneMatch(text -> text.contains("&"));
        assertThat(SEEN.get()).anyMatch(text -> text.contains(" and "));

        String sentence = translatedText(sentenceId, "name");
        assertThat(sentence).contains(" y ").doesNotContain("&");
        String url = translatedText(urlId, "name");
        assertThat(url).contains("https://example.test/a?x=1&y=2");
        assertThat(jobState(sentenceId, "name")).isEqualTo("DONE");
        assertThat(jobState(urlId, "name")).isEqualTo("DONE");
    }

    @Test
    void shortenedOrDanglingOutputIsTruncatedAndNotStored() {
        mode = Mode.TRUNCATE;
        String shortId = category("Q-TRUNC-" + suffix(),
                "Suspension, Steering & Underbody");
        backfill.backfill(List.of("es"), List.of("CATEGORY"), false);
        worker.workOnce();

        assertThat(jobState(shortId, "name")).isEqualTo("FAILED");
        assertThat(jobError(shortId, "name")).isEqualTo("TRUNCATED");
        assertThat(rowCount(shortId, "name")).isZero();

        jdbc.update("DELETE FROM content_translation_job");
        mode = Mode.DANGLING;
        String danglingId = category("Q-DANGLE-" + suffix(), "Braking Systems & Tyres");
        backfill.backfill(List.of("es"), List.of("CATEGORY"), false);
        worker.workOnce();

        assertThat(jobState(danglingId, "name")).isEqualTo("FAILED");
        assertThat(jobError(danglingId, "name")).isEqualTo("TRUNCATED");
        assertThat(rowCount(danglingId, "name")).isZero();
    }

    @Test
    void legitimateShortTranslationIsNotFlagged() {
        mode = Mode.SHORT;
        String categoryId = category("Q-SHORT-" + suffix(), "Radiator");

        backfill.backfill(List.of("es"), List.of("CATEGORY"), false);
        worker.workOnce();

        assertThat(translatedText(categoryId, "name")).isEqualTo("Radiador");
        assertThat(jobState(categoryId, "name")).isEqualTo("DONE");
    }

    @Test
    void echoedTranslationFailsNoChangeAndRemovesThePreviousRow() {
        mode = Mode.ECHO;
        String categoryId = category("Q-NOCHANGE-" + suffix(), "Body panels");
        insertRow("CATEGORY", categoryId, "name", "es", "Paneles", "MACHINE", "STALE",
                translations.hash("an older source"));

        ContentTranslationService.Coverage before = coverageName();

        ContentBackfillService.Result enqueued = backfill.backfill(List.of("es"),
                List.of("CATEGORY"), false);
        assertThat(enqueued.enqueued()).isEqualTo(1);

        worker.workOnce();

        assertThat(rowCount(categoryId, "name")).isZero();
        assertThat(jobState(categoryId, "name")).isEqualTo("FAILED");
        assertThat(jobError(categoryId, "name")).isEqualTo("NO_CHANGE");

        ContentTranslationService.Coverage after = coverageName();
        assertThat(after.translated()).isEqualTo(before.translated());
        assertThat(after.stale()).isEqualTo(before.stale() - 1);
        assertThat(after.missing()).isEqualTo(before.missing() + 1);
    }

    @Test
    void lockedGlossaryTermIsTranslatedWhenProviderEchoes() {
        mode = Mode.ECHO;
        String categoryId = category("Q-LOCK-" + suffix(), "Urgency");

        backfill.backfill(List.of("es"), List.of("CATEGORY"), false);
        worker.workOnce();

        assertThat(SEEN.get()).as("locked term never reaches the provider")
                .noneMatch(text -> text.contains("Urgency"));
        assertThat(translatedText(categoryId, "name")).isEqualTo("urgencia");
        assertThat(jobState(categoryId, "name")).isEqualTo("DONE");
    }

    // ---------------------------------------------------------------- helpers

    private static Set<String> tokens(String text) {
        Set<String> found = new java.util.LinkedHashSet<>();
        Matcher matcher = TOKEN.matcher(text);
        while (matcher.find()) {
            found.add(matcher.group());
        }
        return found;
    }

    private ContentTranslationService.Coverage coverageName() {
        return translations.coverage("es", "CATEGORY").stream()
                .filter(row -> "name".equals(row.field()))
                .findFirst().orElseThrow();
    }

    private Map<String, String> statesByField(String entityId) {
        Map<String, String> result = new LinkedHashMap<>();
        jdbc.query("""
                SELECT field_name, state FROM content_translation_job WHERE entity_id = ?
                ORDER BY field_name
                """, rs -> {
            result.put(rs.getString("field_name"), rs.getString("state"));
        }, entityId);
        return result;
    }

    private String failedJobError(String entityId, String field) {
        return jdbc.queryForObject("""
                SELECT error FROM content_translation_job
                WHERE entity_id = ? AND field_name = ? AND state = 'FAILED'
                """, String.class, entityId, field);
    }

    private void insertRow(String entityType, String entityId, String field, String lang,
                           String body, String origin, String rowStatus, String sourceHash) {
        jdbc.update("""
                INSERT INTO content_translation
                    (id, entity_type, entity_id, field_name, lang, body, origin, status,
                     source_lang, source_hash, provider, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'en', ?, 'quality', CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP)
                """, UUID.randomUUID().toString(), entityType, entityId, field, lang, body,
                origin, rowStatus, sourceHash);
    }

    private String category(String code, String name) {
        String id = UUID.randomUUID().toString();
        categoryIds.add(id);
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 0, 'ACTIVE', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name);
        return id;
    }

    private String item(String code, String categoryId, Map<String, String> sources) {
        String itemId = UUID.randomUUID().toString();
        String versionId = UUID.randomUUID().toString();
        itemIds.add(itemId);
        versionIds.add(versionId);
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id,
                     sample_data, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'PUBLISHED', NULL, FALSE, 0, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, itemId, code, categoryId);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction, standard_spec,
                     safety_critical, multi_point, allow_free_text_note, note_requirement,
                     evidence_requirement, min_photos, created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', ?, ?, ?, FALSE, FALSE, FALSE, 'OPTIONAL',
                        'NONE', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, versionId, itemId, sources.get("label"), sources.get("instruction"),
                sources.get("standardSpec"));
        jdbc.update("UPDATE platform_items SET current_published_version_id = ? WHERE id = ?",
                versionId, itemId);
        return versionId;
    }

    private int rowCount(String entityId, String field) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation
                WHERE entity_id = ? AND field_name = ? AND lang = 'es'
                """, Integer.class, entityId, field);
        return count == null ? 0 : count;
    }

    private String translatedText(String entityId, String field) {
        return jdbc.queryForObject("""
                SELECT body FROM content_translation
                WHERE entity_id = ? AND field_name = ? AND lang = 'es'
                """, String.class, entityId, field);
    }

    private String jobState(String entityId, String field) {
        return jdbc.queryForObject("""
                SELECT state FROM content_translation_job WHERE entity_id = ? AND field_name = ?
                """, String.class, entityId, field);
    }

    private String jobError(String entityId, String field) {
        return jdbc.queryForObject("""
                SELECT error FROM content_translation_job WHERE entity_id = ? AND field_name = ?
                """, String.class, entityId, field);
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
