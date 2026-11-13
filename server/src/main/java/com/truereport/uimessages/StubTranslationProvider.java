package com.truereport.uimessages;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Deterministic translation provider for local end-to-end runs and tests.
 * Enabled with {@code truereport.i18n.translation.provider=stub}.
 */
@Component
@ConditionalOnProperty(name = "truereport.i18n.translation.provider",
        havingValue = "stub")
public class StubTranslationProvider implements UiTextTranslationProvider {

    @Override
    public String translate(String text, String targetLanguage) {
        return "[" + targetLanguage + "] " + text;
    }
}
