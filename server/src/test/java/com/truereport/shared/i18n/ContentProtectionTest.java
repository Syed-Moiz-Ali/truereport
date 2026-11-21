package com.truereport.shared.i18n;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ContentProtectionTest {

    private final ContentProtector protector = new ContentProtector();

    @Test
    void placeholdersAndStructuredTokensSurviveTranslation() {
        String source = "Replace {name} at 3.0 mm for VIN 1HGCM82633A004352; "
                + "range 85–100, 12 V, plate DXB-1001, mail ops@example.test, "
                + "see https://example.test/help, token $1 %s.";
        ContentProtector.Protection protection = protector.protect(source, null, List.of());
        assertThat(protection.text()).doesNotContain("1HGCM82633A004352", "3.0 mm", "85–100",
                "DXB-1001", "ops@example.test", "https://example.test/help");

        String translated = "[[es]] " + protection.text();
        String restored = protector.restore(translated, protection);

        assertThat(restored).contains("{name}", "3.0 mm", "85–100", "12 V", "DXB-1001",
                "ops@example.test", "https://example.test/help", "1HGCM82633A004352",
                "$1", "%s");
    }

    @Test
    void lostPlaceholderFailsWithPlaceholderLost() {
        ContentProtector.Protection protection = protector.protect("Hello {name}", null,
                List.of());
        String token = protection.replacements().keySet().iterator().next();
        String lost = protection.text().replace(token, "");

        assertThatThrownBy(() -> protector.restore(lost, protection))
                .isInstanceOf(ContentProtector.PlaceholderLostException.class)
                .hasMessageContaining(ContentProtector.PLACEHOLDER_LOST);
    }

    @Test
    void alteredTokenWrapperFailsInsteadOfCorruptingText() {
        ContentProtector.Protection protection = protector.protect("Hello {name}", null,
                List.of());
        String token = protection.replacements().keySet().iterator().next();
        String altered = protection.text().replace(token, token.substring(0, token.length() - 1));

        assertThatThrownBy(() -> protector.restore(altered, protection))
                .isInstanceOf(ContentProtector.PlaceholderLostException.class)
                .hasMessageContaining(ContentProtector.PLACEHOLDER_LOST)
                .hasMessageContaining("wrapper altered");
    }

    @Test
    void batchTextsUseDisjointTokensAndRestoreTheirOwnValues() {
        List<String> sources = List.of(
                "Pressure 15 psi",
                "VIN 1HGCM82633A004352",
                "Range 85\u2013100 for 5 minutes");
        List<ContentProtector.Protection> protections = sources.stream()
                .map(source -> protector.protect(source, null, List.of()))
                .toList();

        List<java.util.Set<String>> tokens = protections.stream()
                .map(protection -> protection.replacements().keySet())
                .toList();
        for (int left = 0; left < tokens.size(); left++) {
            assertThat(tokens.get(left)).isNotEmpty();
            for (int right = left + 1; right < tokens.size(); right++) {
                assertThat(tokens.get(left))
                        .as("text %d and %d must not share tokens", left, right)
                        .doesNotContainAnyElementsOf(tokens.get(right));
            }
        }

        for (int index = 0; index < sources.size(); index++) {
            String providerOutput = "[[es]] " + protections.get(index).text();
            assertThat(protector.restore(providerOutput, protections.get(index)))
                    .isEqualTo("[[es]] " + sources.get(index));
        }
    }

    @Test
    void postEditRunsBeforeRestoreSoProtectedValuesStayIntact() {
        TranslationGlossaryStore store = new TranslationGlossaryStore(null);
        ContentProtector.Protection protection = protector.protect(
                "Visit https://example.test/inspection for details", null, List.of());

        String providerOutput = "Visite " + protection.text() + " para m\u00e1s detalles";
        String postEdited = store.applyPostEdit(providerOutput,
                List.of(entry("inspection", "inspecci\u00f3n", false)));
        String restored = protector.restore(postEdited, protection);

        assertThat(restored).contains("https://example.test/inspection")
                .doesNotContain("inspecci\u00f3n");
    }

    @Test
    void providerHostileSymbolsAreProtectedAndRestored() {
        String source = "Temperature >50 C & humidity <80% for 5 minutes";
        ContentProtector.Protection protection = protector.protect(source, null, List.of());

        assertThat(protection.text()).doesNotContain(">", "<");
        // "&" stays for the worker, which normalizes it to "and".
        assertThat(protection.text()).contains("&");
        assertThat(protector.restore("ES:: " + protection.text(), protection))
                .isEqualTo("ES:: " + source);
    }

    @Test
    void lockedTermIsRestoredEvenWhenProviderEchoesTheProtectedText() {
        ContentProtector.Protection protection = protector.protect("Urgency", null,
                List.of(new ContentProtector.GlossaryTerm("urgency", "urgencia", false, true)));

        assertThat(protection.text()).doesNotContain("Urgency");
        assertThat(protector.restore(protection.text(), protection)).isEqualTo("urgencia");
    }

    @Test
    void lockedGlossaryTermIsPreProtectedAndRestoredToItsTranslation() {
        ContentProtector.Protection protection = protector.protect("Brake pad worn", null,
                List.of(new ContentProtector.GlossaryTerm("Brake pad", "Pastilla de freno",
                        false, true)));

        assertThat(protection.text()).doesNotContain("Brake pad");
        assertThat(protector.restore("[[es]] " + protection.text(), protection))
                .contains("Pastilla de freno");
    }

    @Test
    void glossaryPostEditHonoursCaseSensitivity() {
        TranslationGlossaryStore store = new TranslationGlossaryStore(null);
        List<TranslationGlossaryStore.Entry> insensitive = List.of(entry("Worn", "desgastado",
                false));
        List<TranslationGlossaryStore.Entry> sensitive = List.of(entry("Worn", "desgastado",
                true));

        assertThat(store.applyPostEdit("worn and Worn", insensitive))
                .isEqualTo("desgastado and desgastado");
        assertThat(store.applyPostEdit("worn and Worn", sensitive))
                .isEqualTo("worn and desgastado");
    }

    private static TranslationGlossaryStore.Entry entry(String term, String translation,
                                                        boolean caseSensitive) {
        return new TranslationGlossaryStore.Entry("id", "en", "es", term, translation,
                caseSensitive, false);
    }
}
