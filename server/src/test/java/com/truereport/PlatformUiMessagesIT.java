package com.truereport;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PlatformUiMessagesIT extends IntegrationTestBase {

    private static final String ROOT = "/i18n/platform_admin/";

    @Test
    void manifestLoadsFromJson() throws Exception {
        JsonNode manifest = getAnonymousJson("/api/v1/i18n/ui-messages/manifest");
        assertThat(manifest.get("defaultLanguage").asText()).isEqualTo("en");
        assertThat(manifest.get("namespaces").get("common").asInt()).isGreaterThanOrEqualTo(1);
        assertThat(manifest.get("namespaces").get("platform_admin").asInt())
                .isGreaterThanOrEqualTo(1);

        Set<String> codes = new HashSet<>();
        for (JsonNode language : manifest.get("languages")) {
            codes.add(language.get("code").asText());
            assertThat(language.get("direction").asText()).isIn("ltr", "rtl");
            assertThat(language.get("nativeName").asText()).isNotBlank();
            assertThat(language.get("nameEn").asText()).isNotBlank();
            assertThat(language.get("versions").get("common").asInt()).isGreaterThanOrEqualTo(1);
            assertThat(language.get("versions").get("platform_admin").asInt())
                    .isGreaterThanOrEqualTo(1);
        }
        assertThat(codes).containsExactlyInAnyOrder("en", "ar", "zh-Hans");
        for (JsonNode language : manifest.get("languages")) {
            if ("ar".equals(language.get("code").asText())) {
                assertThat(language.get("direction").asText()).isEqualTo("rtl");
            }
        }
    }

    @Test
    void manifestSupportsNamespaceFilterAndRejectsUnknown() throws Exception {
        JsonNode filtered = getAnonymousJson("/api/v1/i18n/ui-messages/manifest?namespaces=common");
        assertThat(filtered.get("namespaces").size()).isEqualTo(1);
        assertThat(filtered.get("namespaces").has("common")).isTrue();

        mockMvc.perform(get("/api/v1/i18n/ui-messages/manifest?namespaces=nope"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void manifestSupportsEtagAndCacheHeaders() throws Exception {
        var first = mockMvc.perform(get("/api/v1/i18n/ui-messages/manifest"))
                .andExpect(status().isOk())
                .andExpect(header().exists("ETag"))
                .andExpect(header().string("Vary", "Origin"))
                .andReturn();
        String etag = first.getResponse().getHeader("ETag");
        assertThat(etag).isNotBlank();
        assertThat(first.getResponse().getHeader("Cache-Control")).contains("private");

        mockMvc.perform(get("/api/v1/i18n/ui-messages/manifest")
                        .header("If-None-Match", etag))
                .andExpect(status().isNotModified());
    }

    @Test
    void bundleServesFlatCatalogFromJson() throws Exception {
        JsonNode manifest = getAnonymousJson("/api/v1/i18n/ui-messages/manifest");
        JsonNode bundle = getAnonymousJson(
                "/api/v1/i18n/ui-messages/bundle?lang=en&namespaces=platform_admin,common");
        assertThat(bundle.get("language").asText()).isEqualTo("en");
        assertThat(bundle.get("fallbackLanguage").asText()).isEqualTo("en");
        assertThat(bundle.get("versions").get("common").asInt())
                .isEqualTo(manifest.get("namespaces").get("common").asInt());
        assertThat(bundle.get("versions").get("platform_admin").asInt())
                .isEqualTo(manifest.get("namespaces").get("platform_admin").asInt());
        assertThat(bundle.get("catalogs").get("common").get("button.save").asText())
                .isEqualTo("Save");
        assertThat(bundle.get("catalogs").get("platform_admin").size()).isGreaterThan(100);
        assertThat(bundle.get("missingKeys").get("common").size()).isZero();
        assertThat(bundle.get("missingKeys").get("platform_admin").size()).isZero();

        var response = mockMvc.perform(get(
                        "/api/v1/i18n/ui-messages/bundle?lang=en&namespaces=platform_admin,common"))
                .andExpect(status().isOk())
                .andExpect(header().exists("ETag"))
                .andReturn();
        String etag = response.getResponse().getHeader("ETag");
        mockMvc.perform(get("/api/v1/i18n/ui-messages/bundle?lang=en&namespaces=platform_admin,common")
                        .header("If-None-Match", etag))
                .andExpect(status().isNotModified());
    }

    @Test
    void bundleRejectsUnknownLanguageAndRequiresLanguage() throws Exception {
        mockMvc.perform(get("/api/v1/i18n/ui-messages/bundle?lang=xx"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/i18n/ui-messages/bundle"))
                .andExpect(status().isUnprocessableEntity());
        mockMvc.perform(get("/api/v1/i18n/ui-messages/bundle?lang=en&namespaces=nope"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void everyManifestLanguageServesItsOwnJsonCatalog() throws Exception {
        JsonNode manifest = readResource("manifest.json");
        JsonNode en = getAnonymousJson(
                "/api/v1/i18n/ui-messages/bundle?lang=en&namespaces=platform_admin,common");
        Set<String> enCommon = keysOf(en.get("catalogs").get("common"));
        Set<String> enAdmin = keysOf(en.get("catalogs").get("platform_admin"));

        for (JsonNode language : manifest.get("languages")) {
            String code = language.get("code").asText();
            JsonNode bundle = getAnonymousJson(
                    "/api/v1/i18n/ui-messages/bundle?lang=" + code
                            + "&namespaces=platform_admin,common");
            assertThat(bundle.get("language").asText()).isEqualTo(code);
            assertThat(keysOf(bundle.get("catalogs").get("common"))).isEqualTo(enCommon);
            assertThat(keysOf(bundle.get("catalogs").get("platform_admin"))).isEqualTo(enAdmin);
            assertThat(bundle.get("missingKeys").get("common").size()).isZero();
            assertThat(bundle.get("missingKeys").get("platform_admin").size()).isZero();
        }
        JsonNode zhHans = getAnonymousJson(
                "/api/v1/i18n/ui-messages/bundle?lang=zh-Hans&namespaces=common");
        assertThat(zhHans.get("catalogs").get("common").get("button.save").asText())
                .isEqualTo("保存");
    }

    @Test
    void everyManifestFileExistsIsFlatAndHasEnArParity() throws Exception {
        JsonNode manifest = readResource("manifest.json");
        Set<String> enKeys = flatKeys(readResource("en.json"));
        Set<String> arKeys = flatKeys(readResource("ar.json"));
        assertThat(arKeys).isEqualTo(enKeys);
        for (JsonNode language : manifest.get("languages")) {
            JsonNode catalog = readResource(language.get("file").asText());
            assertThat(catalog.isObject()).isTrue();
            Iterator<Map.Entry<String, JsonNode>> fields = catalog.fields();
            while (fields.hasNext()) {
                Map.Entry<String, JsonNode> entry = fields.next();
                assertThat(entry.getValue().isTextual())
                        .as(language.get("code").asText() + " key " + entry.getKey())
                        .isTrue();
                assertThat(entry.getValue().asText()).isNotBlank();
            }
            assertThat(flatKeys(catalog)).isEqualTo(enKeys);
        }
    }

    private JsonNode readResource(String file) throws Exception {
        try (var stream = getClass().getResourceAsStream(ROOT + file)) {
            assertThat(stream).as("missing resource " + ROOT + file).isNotNull();
            return objectMapper.readTree(stream);
        }
    }

    private static Set<String> flatKeys(JsonNode node) {
        Set<String> keys = new HashSet<>();
        node.fieldNames().forEachRemaining(keys::add);
        return keys;
    }

    private static Set<String> keysOf(JsonNode catalog) {
        Set<String> keys = new HashSet<>();
        catalog.fieldNames().forEachRemaining(keys::add);
        return keys;
    }

    private JsonNode getAnonymousJson(String path) throws Exception {
        var result = mockMvc.perform(get(path))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }
}
