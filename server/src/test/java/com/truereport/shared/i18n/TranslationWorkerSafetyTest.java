package com.truereport.shared.i18n;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TranslationWorkerSafetyTest {

    @Test
    void fakeProviderWithWorkerEnabledFailsProduction() {
        assertThatThrownBy(() -> TranslationWorkerSafety.assertSafe(true, "fake"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("I18N_TRANSLATION_PROVIDER=libretranslate")
                .hasMessageContaining("I18N_WORKER_ENABLED=false");
        assertThatThrownBy(() -> TranslationWorkerSafety.assertSafe(true, " FAKE "))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> TranslationWorkerSafety.assertSafe(true, ""))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void fakeProviderWithWorkerDisabledIsAllowed() {
        assertThatCode(() -> TranslationWorkerSafety.assertSafe(false, "fake"))
                .doesNotThrowAnyException();
        assertThatCode(() -> TranslationWorkerSafety.assertSafe(false, ""))
                .doesNotThrowAnyException();
    }

    @Test
    void realProviderWithWorkerEnabledIsAllowed() {
        assertThatCode(() -> TranslationWorkerSafety.assertSafe(true, "libretranslate"))
                .doesNotThrowAnyException();
        assertThatCode(() -> TranslationWorkerSafety.assertSafe(true, " LibreTranslate "))
                .doesNotThrowAnyException();
    }
}
