package com.truereport.uimessages;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UiTextTokenProtectorTest {

    private final UiTextTokenProtector protector = new UiTextTokenProtector();

    @Test
    void restoresPlaceholdersAfterTranslation() {
        UiTextTokenProtector.Prepared prepared =
                protector.protect("Hello {name}, you have {count} items");
        String translated = protector.restoreAndValidate(prepared,
                "Bonjour " + token(prepared, "{name}") + ", vous avez "
                        + token(prepared, "{count}") + " articles");
        assertThat(translated).isEqualTo("Bonjour {name}, vous avez {count} articles");
    }

    @Test
    void failsWhenProviderDropsProtectedTokens() {
        UiTextTokenProtector.Prepared prepared = protector.protect("Hello {name}");
        assertThatThrownBy(() -> protector.restoreAndValidate(prepared, "Bonjour"))
                .isInstanceOf(UiTextTranslationException.class)
                .hasMessageContaining("protected token");
    }

    @Test
    void protectsUrlsEmailsAndTechnicalTokens() {
        UiTextTokenProtector.Prepared prepared = protector.protect(
                "See https://example.test/a?b=1 or support@truereport.test for LTR help");
        assertThat(prepared.tokens()).hasSizeGreaterThanOrEqualTo(3);
        assertThat(prepared.text()).doesNotContain("https://example.test")
                .doesNotContain("support@truereport.test")
                .doesNotContain("LTR");
        String restored = protector.restoreAndValidate(prepared, prepared.text());
        assertThat(restored).isEqualTo(
                "See https://example.test/a?b=1 or support@truereport.test for LTR help");
    }

    @Test
    void skipsValuesWithoutLettersAndAllowlistedTokens() {
        assertThat(protector.shouldSkip("1234")).isTrue();
        assertThat(protector.shouldSkip("LTR")).isTrue();
        assertThat(protector.shouldSkip("ED25519-SHA512")).isTrue();
        assertThat(protector.shouldSkip("support@truereport.test")).isTrue();
        assertThat(protector.shouldSkip("https://example.test")).isTrue();
        assertThat(protector.shouldSkip("Hello")).isFalse();
    }

    private static String token(UiTextTokenProtector.Prepared prepared, String original) {
        return prepared.tokens().entrySet().stream()
                .filter(entry -> entry.getValue().equals(original))
                .map(java.util.Map.Entry::getKey)
                .findFirst()
                .orElseThrow();
    }
}
