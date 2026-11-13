package com.truereport.uimessages;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Google Translate provider configuration.
 *
 * <p>{@code target-languages} is an optional override map, not a supported
 * language allowlist. Any language code from the registry is accepted and is
 * passed through to the provider after canonicalization. Add an override only
 * when Google expects a different code, for example {@code zh-Hans -> zh-CN}
 * or {@code zh-Hant -> zh-TW}.</p>
 */
@Component
@ConfigurationProperties(prefix = "truereport.i18n.translation")
public class UiTranslationProperties {

    private String baseUrl = "https://translate.googleapis.com/translate_a/single";
    private String sourceLanguage = "en";

    /**
     * Optional provider-code overrides keyed by app language code. Missing
     * entries never reject a language; the canonicalized app code is used.
     */
    private Map<String, String> targetLanguages = new LinkedHashMap<>(Map.of(
            "zh-hans", "zh-CN",
            "zh-Hans", "zh-CN"));
    private int maxConcurrency = 3;
    private int maxAttempts = 3;
    private Duration connectTimeout = Duration.ofSeconds(10);
    private Duration readTimeout = Duration.ofSeconds(20);

    /**
     * Resolves an app language code to the code sent to Google.
     *
     * <p>Resolution order: exact override, case-insensitive override,
     * canonicalized provider code, then the original trimmed code.</p>
     */
    public String providerCode(String languageCode) {
        if (languageCode == null || languageCode.isBlank()) {
            throw new IllegalArgumentException("Target language code is required");
        }
        String requested = languageCode.trim();
        String exact = targetLanguages.get(requested);
        if (exact != null && !exact.isBlank()) {
            return exact.trim();
        }
        for (Map.Entry<String, String> entry : targetLanguages.entrySet()) {
            if (entry.getKey().equalsIgnoreCase(requested)
                    && entry.getValue() != null && !entry.getValue().isBlank()) {
                return entry.getValue().trim();
            }
        }
        String canonical = canonicalize(requested);
        return canonical.isBlank() ? requested : canonical;
    }

    /**
     * Canonicalizes a BCP-47-like code: language lowercase, script title case,
     * region uppercase, and variants lowercase.
     */
    public static String canonicalize(String languageCode) {
        if (languageCode == null || languageCode.isBlank()) {
            throw new IllegalArgumentException("Target language code is required");
        }
        String[] subtags = languageCode.trim().replace('_', '-').split("-");
        StringBuilder canonical = new StringBuilder(subtags[0].toLowerCase(Locale.ROOT));
        for (int i = 1; i < subtags.length; i++) {
            String subtag = subtags[i];
            if (subtag.isBlank()) {
                continue;
            }
            canonical.append('-');
            if (isScript(subtag)) {
                canonical.append(subtag.substring(0, 1).toUpperCase(Locale.ROOT))
                        .append(subtag.substring(1).toLowerCase(Locale.ROOT));
            } else if (isRegion(subtag)) {
                canonical.append(subtag.toUpperCase(Locale.ROOT));
            } else {
                canonical.append(subtag.toLowerCase(Locale.ROOT));
            }
        }
        return canonical.toString();
    }

    /**
     * Base language used only when the provider explicitly rejects a target
     * language code. Example: {@code pt-BR -> pt}, {@code zh-Hans -> zh}.
     */
    public static String baseLanguage(String providerCode) {
        if (providerCode == null || providerCode.isBlank()) {
            return "";
        }
        int dash = providerCode.indexOf('-');
        return dash > 0 ? providerCode.substring(0, dash) : providerCode;
    }

    private static boolean isScript(String subtag) {
        return subtag.length() == 4 && subtag.chars().allMatch(Character::isLetter);
    }

    private static boolean isRegion(String subtag) {
        if (subtag.length() == 2 && subtag.chars().allMatch(Character::isLetter)) {
            return true;
        }
        return subtag.length() == 3 && subtag.chars().allMatch(Character::isDigit);
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getSourceLanguage() {
        return sourceLanguage;
    }

    public void setSourceLanguage(String sourceLanguage) {
        this.sourceLanguage = sourceLanguage;
    }

    public Map<String, String> getTargetLanguages() {
        return targetLanguages;
    }

    public void setTargetLanguages(Map<String, String> targetLanguages) {
        this.targetLanguages = targetLanguages == null
                ? new LinkedHashMap<>() : new LinkedHashMap<>(targetLanguages);
    }

    public int getMaxConcurrency() {
        return maxConcurrency;
    }

    public void setMaxConcurrency(int maxConcurrency) {
        this.maxConcurrency = maxConcurrency;
    }

    public int getMaxAttempts() {
        return maxAttempts;
    }

    public void setMaxAttempts(int maxAttempts) {
        this.maxAttempts = maxAttempts;
    }

    public Duration getConnectTimeout() {
        return connectTimeout;
    }

    public void setConnectTimeout(Duration connectTimeout) {
        this.connectTimeout = connectTimeout;
    }

    public Duration getReadTimeout() {
        return readTimeout;
    }

    public void setReadTimeout(Duration readTimeout) {
        this.readTimeout = readTimeout;
    }
}
