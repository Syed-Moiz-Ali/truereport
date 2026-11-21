package com.truereport.shared.i18n;

/**
 * Provider failure with an explicit retry policy. Non-retryable failures (bad
 * language, 4xx validation) must not be retried; 429/5xx/timeouts are
 * retryable and may carry a server-provided delay.
 */
public class TranslationProviderException extends RuntimeException {

    private final boolean retryable;
    private final long retryAfterSeconds;

    public TranslationProviderException(String message, boolean retryable) {
        this(message, retryable, 0, null);
    }

    public TranslationProviderException(String message, boolean retryable,
                                        long retryAfterSeconds, Throwable cause) {
        super(message, cause);
        this.retryable = retryable;
        this.retryAfterSeconds = Math.max(0, retryAfterSeconds);
    }

    public boolean retryable() {
        return retryable;
    }

    public long retryAfterSeconds() {
        return retryAfterSeconds;
    }
}
