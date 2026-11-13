package com.truereport;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.uimessages.PlatformUiMessageCatalog;
import com.truereport.uimessages.UiTextTranslationException;
import com.truereport.uimessages.UiTextTranslationProvider;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Comparator;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = {
        "truereport.i18n.ui-messages-dir=target/test-ui-messages",
        "truereport.i18n.generation.synchronous=true"
})
@Import(PlatformUiMessagesGenerationIT.FakeTranslationConfig.class)
class PlatformUiMessagesGenerationIT extends IntegrationTestBase {

    private static final Path DIRECTORY = Path.of("target/test-ui-messages");
    private static final Path SOURCE = Path.of(
            "src/main/resources/i18n/platform_admin/en.json");
    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");

    @Autowired
    FakeTranslationProvider provider;

    @Autowired
    PlatformUiMessageCatalog catalog;

    @Autowired
    JdbcTemplate jdbc;

    @BeforeEach
    void prepareDirectory() throws Exception {
        deleteDirectory();
        Files.createDirectories(DIRECTORY.resolve("platform_admin"));
        Files.copy(SOURCE, DIRECTORY.resolve("platform_admin/en.json"),
                StandardCopyOption.REPLACE_EXISTING);
        provider.reset();
        catalog.invalidate();
    }

    @AfterEach
    void cleanDirectory() throws Exception {
        deleteDirectory();
        catalog.invalidate();
    }

    @Test
    void generatesLanguageJsonAndLinksPath() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi", "Hindi", "हिन्दी");

        JsonNode started = generate(platform, "hi", false);
        assertThat(started.get("jobStatus").asText()).isEqualTo("COMPLETED");
        assertThat(started.get("keysTranslated").asInt())
                .isEqualTo(readFlat(SOURCE).size());
        assertThat(started.get("failedKeys").size()).isZero();

        JsonNode statusNode = getJson(platform,
                "/api/v1/platform/i18n/languages/hi/ui-messages/generation");
        assertThat(statusNode.get("jobStatus").asText()).isEqualTo("COMPLETED");
        assertThat(statusNode.get("status").asText()).isEqualTo("TRANSLATING");
        assertThat(statusNode.get("path").asText()).isEqualTo("platform_admin/hi.json");

        Path generatedFile = DIRECTORY.resolve("platform_admin/hi.json");
        assertThat(Files.exists(generatedFile)).isTrue();
        Map<String, String> generated = readFlat(generatedFile);
        Map<String, String> source = readFlat(SOURCE);
        assertThat(generated.keySet()).isEqualTo(source.keySet());
        for (String key : source.keySet()) {
            assertThat(placeholders(generated.get(key)))
                    .as(key + " placeholders").isEqualTo(placeholders(source.get(key)));
        }
        assertThat(generated.values().stream().anyMatch(value -> value.startsWith("[hi] ")))
                .isTrue();

        JsonNode languages = getJson(platform, "/api/v1/platform/i18n/languages");
        boolean found = false;
        for (JsonNode language : languages) {
            if ("hi".equals(language.get("code").asText())) {
                found = true;
                assertThat(language.get("uiMessagesPath").asText())
                        .isEqualTo("platform_admin/hi.json");
                assertThat(language.get("status").asText()).isEqualTo("TRANSLATING");
            }
        }
        assertThat(found).isTrue();

        JsonNode manifestBefore = getAnonymousJson("/api/v1/i18n/ui-messages/manifest");
        assertThat(codes(manifestBefore)).doesNotContain("hi");

        jdbc.update("UPDATE platform_languages SET status = 'LIVE', active = TRUE WHERE code = 'hi'");
        JsonNode manifestAfter = getAnonymousJson("/api/v1/i18n/ui-messages/manifest");
        assertThat(codes(manifestAfter)).contains("hi");
        JsonNode hiLanguage = language(manifestAfter, "hi");
        assertThat(hiLanguage.get("path").asText()).isEqualTo("platform_admin/hi.json");
    }

    @Test
    void forceFalseSkipsAndForceRegenerates() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi", "Hindi", "हिन्दी");
        generate(platform, "hi", false);
        String first = Files.readString(DIRECTORY.resolve("platform_admin/hi.json"));

        provider.prefix = "[v2]";
        JsonNode skipped = generate(platform, "hi", false);
        assertThat(skipped.get("jobStatus").asText()).isEqualTo("COMPLETED");
        assertThat(Files.readString(DIRECTORY.resolve("platform_admin/hi.json")))
                .isEqualTo(first);

        JsonNode regenerated = generate(platform, "hi", true);
        assertThat(regenerated.get("jobStatus").asText()).isEqualTo("COMPLETED");
        assertThat(Files.readString(DIRECTORY.resolve("platform_admin/hi.json")))
                .isNotEqualTo(first)
                .contains("[v2]");
    }

    @Test
    void failedGenerationDoesNotOverwriteOrRelink() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi", "Hindi", "हिन्दी");
        generate(platform, "hi", false);
        Path generatedFile = DIRECTORY.resolve("platform_admin/hi.json");
        String before = Files.readString(generatedFile);

        provider.prefix = "[broken]";
        provider.failContains = "Dashboard";
        JsonNode failed = generate(platform, "hi", true);
        assertThat(failed.get("jobStatus").asText()).isEqualTo("FAILED");
        assertThat(failed.get("failedKeys").size()).isGreaterThan(0);
        assertThat(Files.readString(generatedFile)).isEqualTo(before);

        JsonNode languages = getJson(platform, "/api/v1/platform/i18n/languages");
        for (JsonNode language : languages) {
            if ("hi".equals(language.get("code").asText())) {
                assertThat(language.get("uiMessagesPath").asText())
                        .isEqualTo("platform_admin/hi.json");
            }
        }
    }

    @Test
    void duplicateActiveJobIsRejected() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi");
        jdbc.update("""
                INSERT INTO platform_ui_message_generation_jobs
                    (id, language_code, status, total_keys, translated_keys,
                     failed_keys_json, created_at, updated_at)
                VALUES (?, ?, 'QUEUED', 0, 0, '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, "job-queued-1", "hi");

        mockMvc.perform(post("/api/v1/platform/i18n/languages/hi/ui-messages/generate")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"force\":true}"))
                .andExpect(status().isConflict());
    }

    @Test
    void cancelStopsQueuedJobAndPersistsStatus() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi");
        jdbc.update("""
                INSERT INTO platform_ui_message_generation_jobs
                    (id, language_code, status, total_keys, translated_keys,
                     failed_keys_json, created_at, updated_at)
                VALUES (?, ?, 'QUEUED', 0, 0, '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, "job-queued-2", "hi");

        JsonNode cancelled = objectMapper.readTree(mockMvc.perform(post(
                        "/api/v1/platform/i18n/languages/hi/ui-messages/generation/cancel")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertThat(cancelled.get("jobStatus").asText()).isEqualTo("CANCELLED");

        String status = jdbc.queryForObject("""
                SELECT status FROM platform_ui_message_generation_jobs WHERE id = 'job-queued-2'
                """, String.class);
        assertThat(status).isEqualTo("CANCELLED");
    }

    @Test
    void completedJobStatusIsPersistedAcrossServiceRestart() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi");
        jdbc.update("""
                INSERT INTO platform_ui_message_generation_jobs
                    (id, language_code, status, total_keys, translated_keys,
                     failed_keys_json, created_at, updated_at)
                VALUES (?, ?, 'COMPLETED', 10, 10, '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, "job-completed-1", "hi");

        JsonNode status = getJson(platform,
                "/api/v1/platform/i18n/languages/hi/ui-messages/generation");
        assertThat(status.get("jobId").asText()).isEqualTo("job-completed-1");
        assertThat(status.get("jobStatus").asText()).isEqualTo("COMPLETED");
    }

    @Test
    void retryFailedProcessesOnlyFailedKeys() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi");
        provider.failContains = "Dashboard";
        JsonNode failed = generate(platform, "hi", true);
        assertThat(failed.get("jobStatus").asText()).isEqualTo("FAILED");
        int failedKeys = failed.get("failedKeys").size();
        assertThat(failedKeys).isGreaterThan(0);

        provider.reset();
        JsonNode retried = objectMapper.readTree(mockMvc.perform(post(
                        "/api/v1/platform/i18n/languages/hi/ui-messages/generation/retry-failed")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isAccepted())
                .andReturn().getResponse().getContentAsString());
        assertThat(retried.get("jobStatus").asText()).isEqualTo("COMPLETED");
        assertThat(provider.calls).isEqualTo(failedKeys);

        Path generatedFile = DIRECTORY.resolve("platform_admin/hi.json");
        assertThat(Files.exists(generatedFile)).isTrue();
        assertThat(readFlat(generatedFile).keySet())
                .isEqualTo(readFlat(SOURCE).keySet());
    }

    @Test
    void manifestExcludesLanguageWithMissingFile() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "ko", "Korean", "한국어");
        jdbc.update("""
                UPDATE platform_languages
                SET status = 'LIVE', active = TRUE,
                    ui_messages_path = 'platform_admin/missing.json'
                WHERE code = 'ko'
                """);

        JsonNode manifest = getAnonymousJson("/api/v1/i18n/ui-messages/manifest");
        assertThat(codes(manifest)).doesNotContain("ko");
    }

    @Test
    void rejectsTraversalInDatabasePath() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "ja", "Japanese", "日本語");
        jdbc.update("""
                UPDATE platform_languages
                SET status = 'LIVE', active = TRUE,
                    ui_messages_path = '../platform_admin/en.json'
                WHERE code = 'ja'
                """);

        JsonNode manifest = getAnonymousJson("/api/v1/i18n/ui-messages/manifest");
        assertThat(codes(manifest)).doesNotContain("ja");
    }

    private void createLanguage(Login login, String code) throws Exception {
        createLanguage(login, code, code.toUpperCase(java.util.Locale.ROOT), code);
    }

    private void createLanguage(Login login, String code, String nameEn, String nativeName)
            throws Exception {
        var result = mockMvc.perform(post("/api/v1/platform/i18n/languages")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","nameEn":"%s","nameAr":"%s","nativeName":"%s"}
                                """.formatted(code, nameEn, nameEn, nativeName)))
                .andExpect(status().isCreated())
                .andReturn();
        objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode generate(Login login, String code, boolean force) throws Exception {
        var result = mockMvc.perform(post(
                                "/api/v1/platform/i18n/languages/" + code
                                        + "/ui-messages/generate")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"force":%s,"reviewStatus":"TRANSLATING"}
                                """.formatted(force)))
                .andExpect(status().is2xxSuccessful())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
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

    private static Set<String> codes(JsonNode manifest) {
        Set<String> codes = new TreeSet<>();
        manifest.get("languages").forEach(node -> codes.add(node.get("code").asText()));
        return codes;
    }

    private static JsonNode language(JsonNode manifest, String code) {
        for (JsonNode node : manifest.get("languages")) {
            if (code.equals(node.get("code").asText())) {
                return node;
            }
        }
        throw new IllegalArgumentException("missing language " + code);
    }

    private static Map<String, String> readFlat(Path path) throws IOException {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.readValue(path.toFile(), new TypeReference<Map<String, String>>() {
        });
    }

    private static Set<String> placeholders(String value) {
        Set<String> names = new TreeSet<>();
        Matcher matcher = PLACEHOLDER.matcher(value == null ? "" : value);
        while (matcher.find()) {
            names.add(matcher.group(1));
        }
        return names;
    }

    private static void deleteDirectory() throws IOException {
        if (!Files.exists(DIRECTORY)) {
            return;
        }
        try (Stream<Path> paths = Files.walk(DIRECTORY)) {
            paths.sorted(Comparator.reverseOrder()).forEach(path -> {
                try {
                    Files.deleteIfExists(path);
                } catch (IOException ignored) {
                    // best effort cleanup
                }
            });
        }
    }

    @TestConfiguration
    static class FakeTranslationConfig {

        @Bean
        @Primary
        FakeTranslationProvider fakeTranslationProvider() {
            return new FakeTranslationProvider();
        }
    }

    static class FakeTranslationProvider implements UiTextTranslationProvider {

        volatile String prefix = "[hi]";
        volatile String failContains;
        volatile int calls;

        @Override
        public String translate(String text, String targetLanguage) {
            calls++;
            if (failContains != null && text.contains(failContains)) {
                throw new UiTextTranslationException("fake translation failure");
            }
            return prefix + " " + text;
        }

        void reset() {
            prefix = "[hi]";
            failContains = null;
            calls = 0;
        }
    }
}
