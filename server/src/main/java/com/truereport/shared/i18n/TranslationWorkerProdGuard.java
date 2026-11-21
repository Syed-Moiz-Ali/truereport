package com.truereport.shared.i18n;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Fails production startup when the translation worker would run against the
 * fake provider and write machine placeholder rows.
 */
@Component
@Profile("prod")
public class TranslationWorkerProdGuard implements ApplicationRunner {

    private final boolean workerEnabled;
    private final String provider;

    public TranslationWorkerProdGuard(
            @Value("${truereport.i18n.translation.worker-enabled:true}") boolean workerEnabled,
            @Value("${truereport.i18n.translation.provider:fake}") String provider) {
        this.workerEnabled = workerEnabled;
        this.provider = provider;
    }

    @Override
    public void run(ApplicationArguments args) {
        TranslationWorkerSafety.assertSafe(workerEnabled, provider);
    }
}
