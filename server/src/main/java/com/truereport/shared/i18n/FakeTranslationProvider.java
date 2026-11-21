package com.truereport.shared.i18n;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Deterministic provider for local development and tests. Output is
 * {@code [[<targetLang>]] <text>}; no network access and no language is
 * special-cased.
 */
@Component
@ConditionalOnProperty(name = "truereport.i18n.translation.provider",
        havingValue = "fake", matchIfMissing = true)
public class FakeTranslationProvider implements TranslationProvider {

    public static final String ID = "fake";

    @Override
    public String id() {
        return ID;
    }

    @Override
    public Map<String, String> translate(List<String> texts, String sourceLang,
                                         String targetLang) {
        Map<String, String> result = new LinkedHashMap<>();
        for (String text : texts) {
            result.put(text, "[[" + targetLang + "]] " + text);
        }
        return result;
    }
}
