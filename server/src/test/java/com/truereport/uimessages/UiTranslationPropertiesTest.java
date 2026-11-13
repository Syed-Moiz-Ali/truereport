package com.truereport.uimessages;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UiTranslationPropertiesTest {

    private final UiTranslationProperties properties = new UiTranslationProperties();

    @Test
    void passesThroughAnyLanguageWithoutAnOverride() {
        assertThat(properties.providerCode("hi")).isEqualTo("hi");
        assertThat(properties.providerCode("fr")).isEqualTo("fr");
        assertThat(properties.providerCode("es")).isEqualTo("es");
        assertThat(properties.providerCode("pt-BR")).isEqualTo("pt-BR");
        assertThat(properties.providerCode("xx")).isEqualTo("xx");
        assertThat(properties.providerCode("en-US")).isEqualTo("en-US");
    }

    @Test
    void canonicalizesLanguageScriptAndRegion() {
        UiTranslationProperties noOverrides = new UiTranslationProperties();
        noOverrides.setTargetLanguages(Map.of());
        assertThat(noOverrides.providerCode("pt-br")).isEqualTo("pt-BR");
        assertThat(noOverrides.providerCode("zh-hans")).isEqualTo("zh-Hans");
        assertThat(noOverrides.providerCode("zh-Hant-TW")).isEqualTo("zh-Hant-TW");
        assertThat(noOverrides.providerCode("sr-latn-rs")).isEqualTo("sr-Latn-RS");
        assertThat(noOverrides.providerCode("es_MX")).isEqualTo("es-MX");
    }

    @Test
    void appliesChineseProviderOverrides() {
        assertThat(properties.providerCode("zh-hans")).isEqualTo("zh-CN");
        assertThat(properties.providerCode("zh-Hans")).isEqualTo("zh-CN");
    }

    @Test
    void treatsOverridesAsOptionalAndSupportsCustomMappings() {
        properties.setTargetLanguages(Map.of(
                "pt-br", "pt",
                "zh-Hant", "zh-TW"));
        assertThat(properties.providerCode("pt-BR")).isEqualTo("pt");
        assertThat(properties.providerCode("pt-br")).isEqualTo("pt");
        assertThat(properties.providerCode("zh-Hant")).isEqualTo("zh-TW");
        assertThat(properties.providerCode("hi")).isEqualTo("hi");
    }

    @Test
    void rejectsEmptyLanguageCode() {
        assertThatThrownBy(() -> properties.providerCode(" "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("required");
        assertThatThrownBy(() -> properties.providerCode(null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void derivesBaseLanguageForUnsupportedTargetFallback() {
        assertThat(UiTranslationProperties.baseLanguage("pt-BR")).isEqualTo("pt");
        assertThat(UiTranslationProperties.baseLanguage("zh-Hans")).isEqualTo("zh");
        assertThat(UiTranslationProperties.baseLanguage("es-MX")).isEqualTo("es");
        assertThat(UiTranslationProperties.baseLanguage("hi")).isEqualTo("hi");
    }
}
