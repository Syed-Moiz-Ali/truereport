package com.truereport.shared.i18n;

/**
 * Pure production decision for the translation worker. Kept out of Spring so it
 * can be unit-tested and reused by startup guards.
 */
public final class TranslationWorkerSafety {

    private TranslationWorkerSafety() {
    }

    public static void assertSafe(boolean workerEnabled, String provider) {
        if (!workerEnabled) {
            return;
        }
        String normalized = provider == null ? "" : provider.trim().toLowerCase();
        if (normalized.isEmpty() || normalized.equals("fake")) {
            throw new IllegalStateException(
                    "Set I18N_TRANSLATION_PROVIDER=libretranslate or "
                            + "I18N_WORKER_ENABLED=false in production");
        }
    }
}
