package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformUiMessagesIT extends IntegrationTestBase {

    @Test
    void legacyManifestDelegatesToPlatformAdmin() throws Exception {
        JsonNode legacy = getJson("/api/v1/i18n/ui-messages/manifest");
        JsonNode client = getJson("/api/v1/i18n/ui-messages/platform_admin/manifest");

        assertThat(legacy.get("defaultLanguage").asText()).isEqualTo("en");
        assertThat(legacy.get("client").asText()).isEqualTo("platform_admin");
        assertThat(legacy.get("namespaces").toString()).isEqualTo("[\"common\",\"platform_admin\"]");
        assertThat(legacy).isEqualTo(client);

        Set<String> codes = new HashSet<>();
        for (JsonNode language : legacy.get("languages")) {
            codes.add(language.get("code").asText());
            assertThat(language.get("name").asText()).isNotBlank();
            assertThat(language.get("nativeName").asText()).isNotBlank();
            assertThat(language.get("direction").asText()).isIn("ltr", "rtl");
            assertThat(language.get("version").asInt()).isGreaterThanOrEqualTo(1);
        }
        assertThat(codes).containsExactly("en");
    }

    @Test
    void manifestAndRegistryExposeEnglishOnlyForPlatformAdmin() throws Exception {
        Login platform = login("platform@test.local");
        JsonNode registry = getJson(platform, "/api/v1/platform/i18n/languages");
        assertThat(registry.size()).isEqualTo(1);
        assertThat(registry.get(0).get("code").asText()).isEqualTo("en");
        assertThat(registry.get(0).get("status").asText()).isEqualTo("LIVE");
    }

    @Test
    void manifestSupportsNamespaceFilterAndRejectsUnknown() throws Exception {
        JsonNode filtered = getJson(
                "/api/v1/i18n/ui-messages/platform_admin/manifest?namespaces=common");
        assertThat(filtered.get("namespaces").size()).isEqualTo(1);
        assertThat(filtered.get("namespaces").get(0).asText()).isEqualTo("common");

        mockMvc.perform(get("/api/v1/i18n/ui-messages/platform_admin/manifest?namespaces=nope"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void responsesAreNeverCached() throws Exception {
        mockMvc.perform(get("/api/v1/i18n/ui-messages/platform_admin/manifest"))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"));
        mockMvc.perform(get("/api/v1/i18n/ui-messages/platform_admin/bundle?lang=en"))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"));
    }

    @Test
    void bundleServesNamespacesAndFlatMessages() throws Exception {
        JsonNode bundle = getJson(
                "/api/v1/i18n/ui-messages/platform_admin/bundle?lang=en"
                        + "&namespaces=platform_admin,common");
        assertThat(bundle.get("language").asText()).isEqualTo("en");
        assertThat(bundle.get("fallbackLanguage").asText()).isEqualTo("en");
        assertThat(bundle.get("client").asText()).isEqualTo("platform_admin");
        assertThat(bundle.get("catalogs").get("common").get("button.save").asText())
                .isEqualTo("Save");
        assertThat(bundle.get("catalogs").get("platform_admin").size()).isGreaterThan(100);
        assertThat(bundle.get("messages").get("button.save").asText()).isEqualTo("Save");
        assertThat(bundle.get("messages").get("nav.dashboard").asText()).isNotBlank();
        assertThat(bundle.get("versions").get("common").asInt()).isGreaterThanOrEqualTo(1);
        assertThat(bundle.get("versions").get("platform_admin").asInt())
                .isGreaterThanOrEqualTo(1);
    }

    @Test
    void legacyBundleMatchesPlatformAdminClientBundle() throws Exception {
        JsonNode legacy = getJson("/api/v1/i18n/ui-messages/bundle?lang=en"
                + "&namespaces=platform_admin,common");
        JsonNode client = getJson("/api/v1/i18n/ui-messages/platform_admin/bundle?lang=en"
                + "&namespaces=platform_admin,common");
        assertThat(legacy).isEqualTo(client);
    }

    @Test
    void workshopManifestAdvertisesRegisteredLanguagesWithCatalogs() throws Exception {
        JsonNode manifest = getJson("/api/v1/i18n/ui-messages/workshop_admin/manifest");
        assertThat(manifest.get("client").asText()).isEqualTo("workshop_admin");
        assertThat(manifest.get("namespaces").toString())
                .isEqualTo("[\"common\",\"workshop_admin\"]");
        assertThat(manifest.get("languages"))
                .extracting(node -> node.get("code").asText())
                .containsExactly("en", "es");
        assertThat(manifest.get("languages").get(1).get("nativeName").asText())
                .isEqualTo("Español");
    }

    @Test
    void workshopBundleMergesCommonAndFallsBackToEnglishPerKey() throws Exception {
        JsonNode en = getJson("/api/v1/i18n/ui-messages/workshop_admin/bundle?lang=en");
        JsonNode es = getJson("/api/v1/i18n/ui-messages/workshop_admin/bundle?lang=es");

        assertThat(es.get("language").asText()).isEqualTo("es");
        assertThat(es.get("fallbackLanguage").asText()).isEqualTo("en");
        assertThat(es.get("messages").get("signInTitle").asText())
                .isEqualTo("Iniciar sesión")
                .isNotEqualTo(en.get("messages").get("signInTitle").asText());
        // Untranslated keys still resolve to their English value.
        assertThat(es.get("messages").get("twoFactorLabel").asText())
                .isEqualTo("Authentication code");

        // Split locked: 59 dotted platform keys in common, 1237 ARB keys per client.
        assertThat(en.get("catalogs").get("common").size()).isEqualTo(59);
        assertThat(en.get("catalogs").get("workshop_admin").size()).isEqualTo(1237);
        assertThat(en.get("messages").size()).isEqualTo(1296);
        // Catalogs are English-filled per key, so es has the same shape as en.
        assertThat(es.get("catalogs").get("common").size()).isEqualTo(59);
        assertThat(es.get("catalogs").get("workshop_admin").size()).isEqualTo(1237);
        assertThat(es.get("messages").size()).isEqualTo(1296);

        // Client translations live in the client namespace; common is platform-only.
        assertThat(es.get("catalogs").get("workshop_admin").get("signInTitle").asText())
                .isEqualTo("Iniciar sesión");
        assertThat(es.get("catalogs").get("common").has("signInTitle")).isFalse();

        Set<String> englishKeys = new HashSet<>();
        en.get("messages").fieldNames().forEachRemaining(englishKeys::add);
        Set<String> spanishKeys = new HashSet<>();
        es.get("messages").fieldNames().forEachRemaining(spanishKeys::add);
        assertThat(spanishKeys).containsAll(englishKeys);
    }

    @Test
    void unknownClientAndUnavailableLanguageAreNotFound() throws Exception {
        mockMvc.perform(get("/api/v1/i18n/ui-messages/nope/manifest"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/i18n/ui-messages/nope/bundle?lang=en"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/i18n/ui-messages/platform_admin/bundle?lang=es"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/i18n/ui-messages/workshop_admin/bundle?lang=xx"))
                .andExpect(status().isNotFound());
    }

    @Test
    void aMissingLanguageFallsBackToTheRegistryDefault() throws Exception {
        JsonNode bundle = getJson("/api/v1/i18n/ui-messages/workshop_admin/bundle");
        assertThat(bundle.get("language").asText()).isEqualTo("en");
    }

    @Test
    void everyAdvertisedLanguageServesItsOwnCatalog() throws Exception {
        JsonNode manifest = getJson("/api/v1/i18n/ui-messages/technician/manifest");
        JsonNode en = getJson("/api/v1/i18n/ui-messages/technician/bundle?lang=en");
        Set<String> englishKeys = keysOf(en.get("messages"));
        for (JsonNode language : manifest.get("languages")) {
            String code = language.get("code").asText();
            JsonNode bundle = getJson("/api/v1/i18n/ui-messages/technician/bundle?lang=" + code);
            assertThat(bundle.get("language").asText()).isEqualTo(code);
            assertThat(keysOf(bundle.get("messages"))).containsAll(englishKeys);
        }
    }

    @Test
    void englishCatalogsAreFlatAndNonEmpty() throws Exception {
        for (String path : new String[]{"common/en.json", "platform_admin/en.json",
                "workshop_admin/en.json", "technician/en.json"}) {
            JsonNode catalog = readResource(path);
            assertThat(catalog.isObject()).as(path).isTrue();
            catalog.fields().forEachRemaining(entry -> {
                assertThat(entry.getValue().isTextual()).as(path + " " + entry.getKey()).isTrue();
                assertThat(entry.getValue().asText()).as(path + " " + entry.getKey()).isNotBlank();
            });
        }
        assertThat(flatKeys(readResource("common/en.json"))).isNotEmpty();
    }

    private JsonNode readResource(String path) throws Exception {
        try (var stream = getClass().getResourceAsStream("/i18n/" + path)) {
            assertThat(stream).as("missing resource /i18n/" + path).isNotNull();
            return objectMapper.readTree(stream);
        }
    }

    private static Set<String> flatKeys(JsonNode node) {
        Set<String> keys = new HashSet<>();
        node.fieldNames().forEachRemaining(keys::add);
        return keys;
    }

    private static Set<String> keysOf(JsonNode node) {
        Set<String> keys = new HashSet<>();
        node.fieldNames().forEachRemaining(keys::add);
        return keys;
    }

    private JsonNode getJson(String path) throws Exception {
        var result = mockMvc.perform(get(path))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private JsonNode getJson(Login login, String path) throws Exception {
        var result = mockMvc.perform(get(path)
                        .header("Authorization", "Bearer " + login.accessToken()))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }
}
