package com.truereport.uimessages;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.Semaphore;

@Component
@ConditionalOnProperty(name = "truereport.i18n.translation.provider",
        havingValue = "google", matchIfMissing = true)
public class GoogleTranslateProvider implements UiTextTranslationProvider {

    private static final Logger log = LoggerFactory.getLogger(GoogleTranslateProvider.class);

    private final ObjectMapper objectMapper;
    private final UiTranslationProperties properties;
    private final HttpClient httpClient;
    private final Semaphore permits;

    public GoogleTranslateProvider(ObjectMapper objectMapper,
                                   UiTranslationProperties properties) {
        this.objectMapper = objectMapper;
        this.properties = properties;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(properties.getConnectTimeout())
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
        this.permits = new Semaphore(Math.max(1, properties.getMaxConcurrency()));
    }

    @Override
    public String translate(String text, String targetLanguage) {
        if (text == null || text.isBlank()) {
            return text;
        }
        String providerLanguage;
        try {
            providerLanguage = properties.providerCode(targetLanguage);
        } catch (IllegalArgumentException invalid) {
            throw new UiTextTranslationException(invalid.getMessage(), invalid);
        }
        String fallbackLanguage = UiTranslationProperties.baseLanguage(providerLanguage);
        String activeLanguage = providerLanguage;
        boolean fallbackTried = false;
        boolean acquired = false;
        try {
            permits.acquire();
            acquired = true;
            int attempts = Math.max(1, properties.getMaxAttempts());
            RuntimeException last = null;
            int attempt = 1;
            while (attempt <= attempts) {
                try {
                    HttpResponse<String> response = httpClient.send(
                            HttpRequest.newBuilder(URI.create(uri(text, activeLanguage)))
                                    .timeout(properties.getReadTimeout())
                                    .GET()
                                    .build(),
                            HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
                    int status = response.statusCode();
                    if (status >= 200 && status < 300) {
                        return parse(response.body(), targetLanguage);
                    }
                    if (!fallbackTried
                            && !fallbackLanguage.isBlank()
                            && !fallbackLanguage.equals(activeLanguage)
                            && isUnsupportedTarget(status, response.body())) {
                        fallbackTried = true;
                        log.warn("Translation provider rejected target {}; retrying with {}",
                                activeLanguage, fallbackLanguage);
                        activeLanguage = fallbackLanguage;
                        continue;
                    }
                    if ((status == 429 || status >= 500 || status == 408)
                            && attempt < attempts) {
                        log.warn("Translation provider returned {} for {}; retrying",
                                status, activeLanguage);
                        sleep(attempt);
                        attempt++;
                        continue;
                    }
                    throw new UiTextTranslationException(
                            "Translation provider rejected target language '"
                                    + activeLanguage + "' (HTTP " + status + ")");
                } catch (IOException error) {
                    last = new UiTextTranslationException(
                            "Translation provider request failed for " + activeLanguage,
                            error);
                    if (attempt < attempts) {
                        log.warn("Translation provider network failure for {}; retrying",
                                activeLanguage);
                        sleep(attempt);
                        attempt++;
                    } else {
                        break;
                    }
                } catch (InterruptedException interrupted) {
                    Thread.currentThread().interrupt();
                    throw new UiTextTranslationException(
                            "Translation provider was interrupted", interrupted);
                }
            }
            throw last == null
                    ? new UiTextTranslationException(
                            "Translation provider failed for " + providerLanguage)
                    : last;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new UiTextTranslationException(
                    "Translation provider was interrupted", interrupted);
        } finally {
            if (acquired) {
                permits.release();
            }
        }
    }

    private static boolean isUnsupportedTarget(int status, String body) {
        if (status != 400 && status != 422) {
            return false;
        }
        String lower = body == null ? "" : body.toLowerCase(java.util.Locale.ROOT);
        boolean mentionsLanguage = lower.contains("target")
                || lower.contains("language");
        boolean unsupported = lower.contains("unsupported")
                || lower.contains("not supported")
                || lower.contains("invalid_target")
                || lower.contains("invalid target");
        return mentionsLanguage && unsupported;
    }

    private String uri(String text, String providerLanguage) {
        String base = properties.getBaseUrl();
        if (base == null || base.isBlank()) {
            throw new UiTextTranslationException("Translation provider base URL is not configured");
        }
        String separator = base.contains("?") ? "&" : "?";
        return base + separator
                + "client=gtx"
                + "&sl=" + encode(properties.getSourceLanguage())
                + "&tl=" + encode(providerLanguage)
                + "&dt=t"
                + "&q=" + encode(text);
    }

    private String parse(String body, String targetLanguage) {
        try {
            JsonNode root = objectMapper.readTree(body);
            if (root == null || !root.isArray() || root.isEmpty()) {
                throw new UiTextTranslationException(
                        "Translation provider returned an invalid payload for " + targetLanguage);
            }
            JsonNode segments = root.get(0);
            if (segments == null || !segments.isArray()) {
                throw new UiTextTranslationException(
                        "Translation provider returned no translated segments for "
                                + targetLanguage);
            }
            StringBuilder translated = new StringBuilder();
            for (JsonNode segment : segments) {
                if (segment.isArray() && !segment.isEmpty()
                        && segment.get(0).isTextual()) {
                    translated.append(segment.get(0).asText());
                }
            }
            if (translated.isEmpty()) {
                throw new UiTextTranslationException(
                        "Translation provider returned an empty translation for "
                                + targetLanguage);
            }
            return translated.toString();
        } catch (IOException error) {
            throw new UiTextTranslationException(
                    "Cannot parse translation provider response for " + targetLanguage, error);
        }
    }

    private static String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static void sleep(int attempt) {
        try {
            Thread.sleep(Duration.ofMillis(250L * (1L << Math.min(attempt - 1, 4))).toMillis());
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new UiTextTranslationException("Translation retry was interrupted",
                    interrupted);
        }
    }
}
