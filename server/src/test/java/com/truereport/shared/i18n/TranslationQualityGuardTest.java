package com.truereport.shared.i18n;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Pre-provider normalization and post-provider content-loss policy.
 */
class TranslationQualityGuardTest {

    private final ContentProtector protector = new ContentProtector();

    @Test
    void textualAmpersandBecomesAndButUrlAmpersandsStayProtected() {
        ContentProtector.Protection protection = protector.protect(
                "See https://example.test/a?x=1&y=2 & more", null, List.of());

        String providerText = ContentTranslationWorker.normalizeAmpersands(
                protection.text());
        assertThat(providerText).doesNotContain("&").contains(" and ");

        String restored = protector.restore("ES:: " + providerText, protection);
        assertThat(restored).contains("https://example.test/a?x=1&y=2 and more");
    }

    @Test
    void shortOutputAndDanglingConjunctionAreTruncated() {
        assertThat(ContentTranslationWorker.truncated(
                "Suspension, Steering & Underbody", "Suspensión")).isTrue();
        assertThat(ContentTranslationWorker.truncated(
                "Suspension, Steering & Underbody", "Suspensión, Dirección &")).isTrue();
        assertThat(ContentTranslationWorker.truncated(
                "Suspension, Steering & Underbody", "Suspensión, Dirección y")).isTrue();
        assertThat(ContentTranslationWorker.truncated(
                "Suspension, Steering & Underbody", "Suspensión, Dirección y Carrocería"))
                .isFalse();
    }

    @Test
    void legitimateShortTranslationIsNotFlagged() {
        assertThat(ContentTranslationWorker.truncated("Urgency", "Urgencia")).isFalse();
        assertThat(ContentTranslationWorker.truncated("Radiator", "Radiador")).isFalse();
    }
}
