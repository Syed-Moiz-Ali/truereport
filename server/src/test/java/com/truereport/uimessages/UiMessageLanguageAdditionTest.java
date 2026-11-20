package com.truereport.uimessages;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.uimessages.api.UiMessageDtos.ManifestLanguageDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageBundleDto;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Proves the contract rule that adding a language is a data-only change:
 * registration plus a client catalog file is enough, no Java change required.
 */
class UiMessageLanguageAdditionTest {

    @TempDir
    Path directory;

    @Test
    void registeredLanguageWithClientFileAppearsWithoutCodeChanges() throws Exception {
        write("languages.json", """
                {"defaultLanguage":"en","languages":[
                  {"code":"en","name":"English","nativeName":"English","direction":"ltr"}
                ]}
                """);
        write("common/en.json", """
                {"hello":"Hello","onlyEnglish":"English only"}
                """);
        write("platform_admin/en.json", "{}");

        PlatformUiMessageCatalog catalog =
                new PlatformUiMessageCatalog(new ObjectMapper(), directory.toString());
        UiMessageService service = new UiMessageService(catalog);

        assertThat(service.manifest("platform_admin", null).languages())
                .extracting(ManifestLanguageDto::code)
                .containsExactly("en");

        // Data-only change: register the language and drop its catalogs.
        write("languages.json", """
                {"defaultLanguage":"en","languages":[
                  {"code":"en","name":"English","nativeName":"English","direction":"ltr"},
                  {"code":"fr","name":"French","nativeName":"Français","direction":"ltr"}
                ]}
                """);
        write("common/fr.json", "{\"hello\":\"Bonjour\"}");
        write("platform_admin/fr.json", "{\"localOnly\":\"Localisé\"}");
        catalog.invalidate();

        assertThat(service.manifest("platform_admin", null).languages())
                .extracting(ManifestLanguageDto::code)
                .containsExactly("en", "fr");

        UiMessageBundleDto bundle = service.bundle("platform_admin", "fr", null);
        assertThat(bundle.language()).isEqualTo("fr");
        assertThat(bundle.fallbackLanguage()).isEqualTo("en");
        assertThat(bundle.messages())
                .containsEntry("hello", "Bonjour")
                .containsEntry("onlyEnglish", "English only")
                .containsEntry("localOnly", "Localisé");
        assertThat(bundle.catalogs().get("common"))
                .containsEntry("hello", "Bonjour")
                .containsEntry("onlyEnglish", "English only");
        assertThat(bundle.catalogs().get("platform_admin"))
                .containsEntry("localOnly", "Localisé");
    }

    private void write(String file, String content) throws Exception {
        Path target = directory.resolve(file);
        Files.createDirectories(target.getParent());
        Files.writeString(target, content);
    }
}
