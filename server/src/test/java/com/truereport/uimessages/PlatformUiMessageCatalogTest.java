package com.truereport.uimessages;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.error.ApiException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

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
    void atomicWriteValidatesAndReplacesFile() throws Exception {
        write("platform_admin/en.json", "{\"platform_admin.hello\":\"Hello\"}");
        PlatformUiMessageCatalog catalog = catalog();
        Map<String, String> values = new LinkedHashMap<>();
        values.put("platform_admin.hello", "Bonjour");
        Path target = catalog.writeAtomic("platform_admin/fr.json", values);
        assertThat(Files.exists(target)).isTrue();
        catalog.invalidate();
        assertThat(catalog.load("platform_admin/fr.json").flat())
                .containsEntry("platform_admin.hello", "Bonjour");
    }

    @Test
    void publishGuardRequiresKeyAndPlaceholderParity() throws Exception {
        write("platform_admin/en.json", "{\"platform_admin.hello\":\"Hello {name}\"}");
        write("platform_admin/fr.json", "{\"platform_admin.hello\":\"Bonjour\"}");
        PlatformUiMessageCatalog catalog = catalog();
        assertThatThrownBy(() -> catalog.requirePublishable("fr",
                "platform_admin/fr.json", "platform_admin/en.json"))
                .isInstanceOf(ApiException.class);

        write("platform_admin/fr.json", "{\"platform_admin.hello\":\"Bonjour {name}\"}");
        catalog.invalidate();
        catalog.requirePublishable("fr", "platform_admin/fr.json",
                "platform_admin/en.json");
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
