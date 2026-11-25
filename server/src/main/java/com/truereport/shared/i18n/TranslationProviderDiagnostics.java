package com.truereport.shared.i18n;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

/**
 * Logs which translation provider is active at startup.
 *
 * <p>The default provider is {@code fake}, which only prefixes text with the
 * target language. This line makes that visible instead of leaving the console
 * wondering why Spanish looks like {@code [[es]] Tread depth}.</p>
 */
@Component
public class TranslationProviderDiagnostics {

    private static final Logger log = LoggerFactory.getLogger(TranslationProviderDiagnostics.class);

    public TranslationProviderDiagnostics(ObjectProvider<TranslationProvider> provider) {
        TranslationProvider active = provider.getIfAvailable();
        if (active == null) {
            log.warn("Content translation: no provider bean is active; translation jobs cannot run");
            return;
        }
        if (FakeTranslationProvider.ID.equals(active.id())) {
            log.warn("Content translation provider is 'fake' ([[lang]] prefixed text). "
                    + "Set I18N_TRANSLATION_PROVIDER=libretranslate for real translations.");
        } else {
            log.info("Content translation provider: {}", active.id());
        }
    }
}
