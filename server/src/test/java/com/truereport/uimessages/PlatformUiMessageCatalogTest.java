package com.truereport.uimessages;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PlatformUiMessageCatalogTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @TempDir
    Path directory;

    @Test
    void addingLanguageFileAndManifestEntryExposesIt() throws Exception {
        writeManifest("en");
        write("en.json", "{\"platform_admin.hello\":\"Hello\"}");
        PlatformUiMessageCatalog catalog = new PlatformUiMessageCatalog(
                objectMapper, directory.toString());
        assertThat(catalog.snapshot().language("fr")).isNull();

        writeManifest("en", "fr");
        write("fr.json", "{\"platform_admin.hello\":\"Bonjour\"}");
        PlatformUiMessageCatalog.Snapshot reloaded = catalog.reload();
        assertThat(reloaded.language("fr")).isNotNull();
        assertThat(reloaded.language("fr").catalogs().get("platform_admin").get("hello"))
                .isEqualTo("Bonjour");
    }

    @Test
    void etagAndVersionChangeWhenFileChanges() throws Exception {
        writeManifest("en");
        write("en.json", "{\"common.button.save\":\"Save\"}");
        PlatformUiMessageCatalog catalog = new PlatformUiMessageCatalog(
                objectMapper, directory.toString());
        PlatformUiMessageCatalog.Language before = catalog.snapshot().language("en");
        String etagBefore = before.etag();
        int versionBefore = before.versions().get("common");

        write("en.json", "{\"common.button.save\":\"Save now\"}");
        PlatformUiMessageCatalog.Language after = catalog.reload().language("en");
        assertThat(after.etag()).isNotEqualTo(etagBefore);
        assertThat(after.versions().get("common")).isNotEqualTo(versionBefore);
    }

    @Test
    void missingLanguageFileFailsFast() throws Exception {
        writeManifest("en");
        write("en.json", "{\"platform_admin.hello\":\"Hello\"}");
        write("manifest.json", """
                {"defaultLanguage":"en","languages":[
                  {"code":"en","name":"English","nativeName":"English","direction":"ltr","file":"en.json"},
                  {"code":"fr","name":"French","nativeName":"Français","direction":"ltr","file":"fr.json"}
                ]}
                """);
        PlatformUiMessageCatalog catalog = new PlatformUiMessageCatalog(
                objectMapper, directory.toString());
        assertThatThrownBy(catalog::snapshot)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("fr.json");
    }

    @Test
    void invalidLanguageJsonFailsFast() throws Exception {
        writeManifest("en");
        write("en.json", "{not-json");
        PlatformUiMessageCatalog catalog = new PlatformUiMessageCatalog(
                objectMapper, directory.toString());
        assertThatThrownBy(catalog::snapshot)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot read UI message file 'en.json'");
    }

    @Test
    void nonFlatLanguageJsonFailsFast() throws Exception {
        writeManifest("en");
        write("en.json", "{\"platform_admin.hello\":{\"nested\":true}}");
        PlatformUiMessageCatalog catalog = new PlatformUiMessageCatalog(
                objectMapper, directory.toString());
        assertThatThrownBy(catalog::snapshot)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("must be flat");
    }

    @Test
    void defaultLanguageMustBeListedInManifest() throws Exception {
        write("manifest.json", """
                {"defaultLanguage":"zz","languages":[
                  {"code":"en","name":"English","nativeName":"English","direction":"ltr","file":"en.json"}
                ]}
                """);
        write("en.json", "{\"platform_admin.hello\":\"Hello\"}");
        PlatformUiMessageCatalog catalog = new PlatformUiMessageCatalog(
                objectMapper, directory.toString());
        assertThatThrownBy(catalog::snapshot)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Default UI message language");
    }

    private void writeManifest(String defaultLanguage, String... additionalCodes) throws Exception {
        StringBuilder languages = new StringBuilder();
        languages.append("""
                {"code":"en","name":"English","nativeName":"English","direction":"ltr","file":"en.json"}
                """);
        for (String code : additionalCodes) {
            languages.append("""
                    ,{"code":"%s","name":"%s","nativeName":"%s","direction":"ltr","file":"%s.json"}
                    """.formatted(code, code, code, code));
        }
        write("manifest.json", """
                {"defaultLanguage":"%s","languages":[%s]}
                """.formatted(defaultLanguage, languages));
    }

    private void write(String file, String content) throws Exception {
        Files.writeString(directory.resolve(file), content);
    }
}
