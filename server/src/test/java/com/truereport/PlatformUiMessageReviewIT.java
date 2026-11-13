package com.truereport;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = "truereport.i18n.ui-messages-dir=target/review-ui-messages")
class PlatformUiMessageReviewIT extends IntegrationTestBase {

    private static final Path DIRECTORY = Path.of("target/review-ui-messages");
    private static final Path SOURCE = Path.of(
            "src/main/resources/i18n/platform_admin/en.json");

    @Autowired
    JdbcTemplate jdbc;

    @BeforeEach
    void prepare() throws Exception {
        deleteDirectory();
        Files.createDirectories(DIRECTORY.resolve("platform_admin"));
        Files.copy(SOURCE, DIRECTORY.resolve("platform_admin/en.json"));
    }

    @AfterEach
    void clean() throws Exception {
        deleteDirectory();
    }

    @Test
    void reviewSaveApproveAndDownload() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "hi");
        Map<String, String> source = read(SOURCE);
        Map<String, String> translated = new LinkedHashMap<>();
        source.forEach((key, value) -> translated.put(key, "hi " + value));
        Path target = DIRECTORY.resolve("platform_admin/hi.json");
        write(target, translated);

        JsonNode review = getJson(platform,
                "/api/v1/platform/i18n/languages/hi/ui-messages/review");
        assertThat(review.get("totalKeys").asInt()).isEqualTo(source.size());
        assertThat(review.get("changedKeys").asInt()).isEqualTo(source.size());

        String firstKey = source.keySet().iterator().next();
        String edited = "edited translation";
        mockMvc.perform(put("/api/v1/platform/i18n/languages/hi/ui-messages/review")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("translations", Map.of(firstKey, edited)))))
                .andExpect(status().isOk());

        assertThat(read(target).get(firstKey)).isEqualTo(edited);
        String hash = jdbc.queryForObject("""
                SELECT ui_messages_hash FROM platform_languages WHERE code = 'hi'
                """, String.class);
        assertThat(hash).isNotBlank();

        JsonNode approved = objectMapper.readTree(mockMvc.perform(
                        post("/api/v1/platform/i18n/languages/hi/ui-messages/approve")
                                .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertThat(approved.get("status").asText()).isEqualTo("REVIEW");
        assertThat(approved.get("hash").asText()).isEqualTo(hash);

        byte[] downloaded = mockMvc.perform(
                        get("/api/v1/platform/i18n/languages/hi/ui-messages/download")
                                .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(downloaded).isEqualTo(Files.readAllBytes(target));
    }

    @Test
    void publishIsBlockedUntilReviewFileIsComplete() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "ja");
        Map<String, String> source = read(SOURCE);
        String missing = source.keySet().iterator().next();
        Map<String, String> partial = new LinkedHashMap<>(source);
        partial.remove(missing);
        write(DIRECTORY.resolve("platform_admin/ja.json"), partial);

        mockMvc.perform(post("/api/v1/platform/i18n/languages/ja/publish")
                        .header("Authorization", "Bearer " + platform.accessToken()))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void saveRejectsPlaceholderMismatch() throws Exception {
        Login platform = login("platform@test.local");
        createLanguage(platform, "ko");
        Map<String, String> source = read(SOURCE);
        Map<String, String> translated = new LinkedHashMap<>();
        source.forEach((key, value) -> translated.put(key, value));
        String keyWithPlaceholder = source.entrySet().stream()
                .filter(entry -> entry.getValue().contains("{"))
                .map(Map.Entry::getKey)
                .findFirst()
                .orElseThrow();
        translated.put(keyWithPlaceholder, "no placeholders");
        write(DIRECTORY.resolve("platform_admin/ko.json"), translated);

        mockMvc.perform(put("/api/v1/platform/i18n/languages/ko/ui-messages/review")
                        .header("Authorization", "Bearer " + platform.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "translations",
                                Map.of(keyWithPlaceholder, "still no placeholders")))))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void reviewRequiresPlatformAdmin() throws Exception {
        Login workshopAdmin = login("admin.a@test.local");
        mockMvc.perform(get("/api/v1/platform/i18n/languages/en/ui-messages/review")
                        .header("Authorization", "Bearer " + workshopAdmin.accessToken()))
                .andExpect(status().isForbidden());
    }

    private void createLanguage(Login login, String code) throws Exception {
        mockMvc.perform(post("/api/v1/platform/i18n/languages")
                        .header("Authorization", "Bearer " + login.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","nameEn":"%s","nameAr":"%s","nativeName":"%s"}
                                """.formatted(code, code, code, code)))
                .andExpect(status().isCreated());
        jdbc.update("""
                UPDATE platform_languages SET ui_messages_path = ?
                WHERE code = ?
                """, "platform_admin/" + code + ".json", code);
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        return objectMapper.readTree(mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    private static Map<String, String> read(Path path) throws IOException {
        return new ObjectMapper().readValue(path.toFile(),
                new TypeReference<Map<String, String>>() {
                });
    }

    private static void write(Path path, Map<String, String> values)
            throws IOException {
        Files.createDirectories(path.getParent());
        new ObjectMapper().writerWithDefaultPrettyPrinter()
                .writeValue(path.toFile(), values);
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
                    // best effort
                }
            });
        }
    }
}
