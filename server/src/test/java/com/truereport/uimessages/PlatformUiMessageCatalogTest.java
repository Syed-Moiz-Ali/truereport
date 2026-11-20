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
    void readsOneNamespacePerFile() throws Exception {
        registry("en");
        write("platform_admin/en.json", "{\"hello\":\"Hello {name}\"}");
        PlatformUiMessageCatalog catalog = catalog();
        PlatformUiMessageCatalog.NamespaceCatalog loaded =
                catalog.namespace("platform_admin", "en");
        assertThat(loaded.values().get("hello")).isEqualTo("Hello {name}");
        assertThat(loaded.language()).isEqualTo("en");
        assertThat(loaded.version()).isGreaterThan(0);
    }

    @Test
    void versionChangesWhenFileChanges() throws Exception {
        registry("en");
        write("platform_admin/en.json", "{\"hello\":\"Hello\"}");
        PlatformUiMessageCatalog catalog = catalog();
        int before = catalog.namespace("platform_admin", "en").version();
        write("platform_admin/en.json", "{\"hello\":\"Hello there\"}");
        catalog.invalidate();
        assertThat(catalog.namespace("platform_admin", "en").version()).isNotEqualTo(before);
    }

    @Test
    void registryDeclaresOrderedLanguagesAndDefault() throws Exception {
        registry("en", "es");
        PlatformUiMessageCatalog catalog = catalog();
        PlatformUiMessageCatalog.Registry registry = catalog.registry();
        assertThat(registry.defaultLanguage()).isEqualTo("en");
        assertThat(registry.languages())
                .extracting(PlatformUiMessageCatalog.Language::code)
                .containsExactly("en", "es");
        assertThat(registry.find("ES").nativeName()).isEqualTo("Español");
        assertThat(registry.find("fr")).isNull();
    }

    @Test
    void onlyRegisteredLanguagesWithAClientFileAreAdvertised() throws Exception {
        registry("en", "es", "fr");
        write("platform_admin/en.json", "{}");
        write("platform_admin/es.json", "{}");
        PlatformUiMessageCatalog catalog = catalog();
        assertThat(catalog.languagesForClient("platform_admin"))
                .extracting(PlatformUiMessageCatalog.Language::code)
                .containsExactly("en", "es");
        assertThat(catalog.hasLanguageCatalog("platform_admin", "fr")).isFalse();
        assertThat(catalog.hasLanguageCatalog("technician", "es")).isFalse();
    }

    @Test
    void unknownClientIsRejected() throws Exception {
        registry("en");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.languagesForClient("unknown"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void startupValidationRequiresEnglishForEveryClientAndCommon() throws Exception {
        registry("en");
        write("common/en.json", "{}");
        write("workshop_admin/en.json", "{}");
        write("technician/en.json", "{}");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(catalog::validateOnStartup)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("platform_admin/en.json");

        write("platform_admin/en.json", "{}");
        catalog.invalidate();
        catalog.validateOnStartup();
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
                "common/../../en.json"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void invalidJsonFailsFast() throws Exception {
        write("platform_admin/en.json", "{not-json");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.namespace("platform_admin", "en"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot read UI message file");
    }

    @Test
    void nonFlatJsonFailsFast() throws Exception {
        write("platform_admin/en.json", "{\"hello\":{\"nested\":true}}");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.namespace("platform_admin", "en"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("must be flat");
    }

    @Test
    void coverageReportsMissingKeysAndPlaceholderMismatch() throws Exception {
        write("common/en.json", "{\"hello\":\"Hello {name}\",\"bye\":\"Bye\"}");
        write("platform_admin/en.json", "{}");
        write("platform_admin/es.json", "{\"hello\":\"Hola\"}");
        PlatformUiMessageCatalog catalog = catalog();
        PlatformUiMessageCatalog.StaticCoverage coverage =
                catalog.coverage("platform_admin/es.json");
        assertThat(coverage.total()).isEqualTo(2);
        assertThat(coverage.missing()).isEqualTo(1);
        assertThat(coverage.placeholderMismatch()).isEqualTo(1);

        write("platform_admin/es.json", "{\"hello\":\"Hola {name}\",\"bye\":\"Adiós\"}");
        catalog.invalidate();
        PlatformUiMessageCatalog.StaticCoverage complete =
                catalog.coverage("platform_admin/es.json");
        assertThat(complete.missing()).isZero();
        assertThat(complete.placeholderMismatch()).isZero();
    }

    private PlatformUiMessageCatalog catalog() {
        return new PlatformUiMessageCatalog(objectMapper, directory.toString());
    }

    private void registry(String... codes) throws Exception {
        StringBuilder languages = new StringBuilder();
        for (String code : codes) {
            if (!languages.isEmpty()) {
                languages.append(',');
            }
            languages.append("{\"code\":\"").append(code).append("\",\"name\":\"")
                    .append(code).append("\",\"nativeName\":\"")
                    .append("es".equals(code) ? "Español" : code)
                    .append("\",\"direction\":\"ltr\"}");
        }
        write("languages.json", "{\"defaultLanguage\":\"en\",\"languages\":["
                + languages + "]}");
    }

    private void write(String file, String content) throws Exception {
        Path target = directory.resolve(file);
        Files.createDirectories(target.getParent());
        Files.writeString(target, content);
    }
}
