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
    void loadsFlatCatalogAndComputesVersions() throws Exception {
        write("platform_admin/en.json", "{\"platform_admin.hello\":\"Hello {name}\"}");
        PlatformUiMessageCatalog catalog = catalog();
        PlatformUiMessageCatalog.LanguageCatalog loaded =
                catalog.load("platform_admin/en.json");
        assertThat(loaded.flat().get("platform_admin.hello")).isEqualTo("Hello {name}");
        assertThat(loaded.catalogs().get("platform_admin").get("hello"))
                .isEqualTo("Hello {name}");
        assertThat(loaded.versions().get("platform_admin")).isGreaterThan(0);
        assertThat(loaded.etag()).isNotBlank();
    }

    @Test
    void etagChangesWhenFileChanges() throws Exception {
        write("platform_admin/en.json", "{\"platform_admin.hello\":\"Hello\"}");
        PlatformUiMessageCatalog catalog = catalog();
        String before = catalog.load("platform_admin/en.json").etag();
        write("platform_admin/en.json", "{\"platform_admin.hello\":\"Hello there\"}");
        catalog.invalidate();
        assertThat(catalog.load("platform_admin/en.json").etag()).isNotEqualTo(before);
    }

    @Test
    void rejectsAbsoluteAndTraversalPaths() {
        assertThatThrownBy(() -> PlatformUiMessageCatalog.validateRelativePath("../en.json"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> PlatformUiMessageCatalog.validateRelativePath("/tmp/en.json"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> PlatformUiMessageCatalog.validateRelativePath("C:/tmp/en.json"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> PlatformUiMessageCatalog.validateRelativePath(
                "platform_admin/../../en.json"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void missingFileFailsFast() {
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.load("platform_admin/fr.json"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("fr.json");
    }

    @Test
    void invalidJsonFailsFast() throws Exception {
        write("platform_admin/en.json", "{not-json");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.load("platform_admin/en.json"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot read UI message file");
    }

    @Test
    void nonFlatJsonFailsFast() throws Exception {
        write("platform_admin/en.json", "{\"platform_admin.hello\":{\"nested\":true}}");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.load("platform_admin/en.json"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("must be flat");
    }

    @Test
    void manifestDeclaresStaticLanguagesAndNormalizesFiles() throws Exception {
        write("platform_admin/manifest.json", """
                {"defaultLanguage":"en","languages":[
                  {"code":"en","nativeName":"English","direction":"ltr","file":"en.json"},
                  {"code":"ta","nativeName":"Tamil","direction":"ltr","file":"ta.json"}
                ]}
                """);
        PlatformUiMessageCatalog catalog = catalog();
        PlatformUiMessageCatalog.StaticManifest manifest = catalog.manifest();
        assertThat(manifest.defaultLanguage()).isEqualTo("en");
        assertThat(manifest.languages()).extracting(PlatformUiMessageCatalog.StaticLanguage::code)
                .containsExactly("en", "ta");
        assertThat(manifest.find("ta").file()).isEqualTo("platform_admin/ta.json");
    }

    @Test
    void coverageReportsMissingKeysAndPlaceholderMismatch() throws Exception {
        write("platform_admin/en.json", """
                {"platform_admin.hello":"Hello {name}","platform_admin.bye":"Bye"}
                """);
        write("platform_admin/ta.json", "{\"platform_admin.hello\":\"Vanakkam\"}");
        PlatformUiMessageCatalog catalog = catalog();
        PlatformUiMessageCatalog.StaticCoverage coverage =
                catalog.coverage("platform_admin/ta.json");
        assertThat(coverage.total()).isEqualTo(2);
        assertThat(coverage.missing()).isEqualTo(1);
        assertThat(coverage.placeholderMismatch()).isEqualTo(1);

        write("platform_admin/ta.json", """
                {"platform_admin.hello":"Vanakkam {name}","platform_admin.bye":"Bye"}
                """);
        catalog.invalidate();
        PlatformUiMessageCatalog.StaticCoverage complete =
                catalog.coverage("platform_admin/ta.json");
        assertThat(complete.missing()).isZero();
        assertThat(complete.placeholderMismatch()).isZero();
    }

    private PlatformUiMessageCatalog catalog() {
        return new PlatformUiMessageCatalog(objectMapper, directory.toString());
    }

    private void write(String file, String content) throws Exception {
        Path target = directory.resolve(file);
        Files.createDirectories(target.getParent());
        Files.writeString(target, content);
    }
}
