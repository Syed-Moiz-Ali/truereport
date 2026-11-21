package com.truereport.shared.i18n;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * LibreTranslate adapter. Sends a JSON array as {@code q}; if the server rejects
 * arrays (400), it falls back to one request per text. 4xx is non-retryable
 * (except 429); 5xx and timeouts are retryable. {@code Retry-After} is surfaced
 * to the worker.
 */
@Component
@ConditionalOnProperty(name = "truereport.i18n.translation.provider",
        havingValue = "libretranslate")
public class LibreTranslateProvider implements TranslationProvider {

    public static final String ID = "libretranslate";

    private final String baseUrl;
    private final Duration timeout;
    private final String apiKey;
    private final int batchSize;
    private final String format;
    private final ObjectMapper objectMapper;
    private final HttpClient client;

    @org.springframework.beans.factory.annotation.Autowired
    public LibreTranslateProvider(
            @Value("${truereport.i18n.translation.libretranslate.url:http://localhost:5000}")
            String baseUrl,
            @Value("${truereport.i18n.translation.libretranslate.timeout:10s}")
            Duration timeout,
            @Value("${truereport.i18n.translation.libretranslate.api-key:}")
            String apiKey,
            @Value("${truereport.i18n.translation.libretranslate.batch-size:20}")
            int batchSize,
            @Value("${truereport.i18n.translation.libretranslate.format:text}")
            String format,
            ObjectMapper objectMapper) {
        this(baseUrl, timeout, apiKey, batchSize, format, objectMapper,
                HttpClient.newBuilder().connectTimeout(timeout).build());
    }

    LibreTranslateProvider(String baseUrl, Duration timeout, String apiKey, int batchSize,
                           String format, ObjectMapper objectMapper, HttpClient client) {
        this.baseUrl = baseUrl == null ? "http://localhost:5000" : baseUrl.replaceAll("/+$", "");
        this.timeout = timeout == null ? Duration.ofSeconds(10) : timeout;
        this.apiKey = apiKey;
        this.batchSize = Math.max(1, batchSize);
        this.format = format == null || format.isBlank() ? "text" : format;
        this.objectMapper = objectMapper;
        this.client = client;
    }

    @Override
    public String id() {
        return ID;
    }

    @Override
    public Map<String, String> translate(List<String> texts, String sourceLang,
                                         String targetLang) {
        if (texts == null || texts.isEmpty()) {
            return Map.of();
        }
        Map<String, String> result = new LinkedHashMap<>();
        for (int start = 0; start < texts.size(); start += batchSize) {
            List<String> chunk = texts.subList(start, Math.min(texts.size(), start + batchSize));
            if (chunk.size() > 1) {
                try {
                    apply(result, chunk, request(chunk, sourceLang, targetLang, true));
                } catch (TranslationProviderException exception) {
                    if (exception.retryable()) {
                        throw exception;
                    }
                    // Server rejected arrays: retry each text individually.
                    for (String text : chunk) {
                        apply(result, List.of(text),
                                request(List.of(text), sourceLang, targetLang, false));
                    }
                }
            } else {
                apply(result, chunk, request(chunk, sourceLang, targetLang, false));
            }
        }
        return result;
    }

    private List<String> request(List<String> texts, String sourceLang, String targetLang,
                                 boolean asArray) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("q", asArray ? texts : texts.get(0));
        body.put("source", sourceLang);
        body.put("target", targetLang);
        body.put("format", format);
        if (apiKey != null && !apiKey.isBlank()) {
            body.put("api_key", apiKey);
        }
        byte[] payload;
        try {
            payload = objectMapper.writeValueAsBytes(body);
        } catch (IOException exception) {
            throw new TranslationProviderException("Cannot serialise translation request",
                    false, 0, exception);
        }
        HttpRequest request = HttpRequest.newBuilder(URI.create(baseUrl + "/translate"))
                .timeout(timeout)
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .POST(HttpRequest.BodyPublishers.ofByteArray(payload))
                .build();
        HttpResponse<String> response;
        try {
            response = client.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (HttpTimeoutException exception) {
            throw new TranslationProviderException("LibreTranslate request timed out after "
                    + timeout, true, 0, exception);
        } catch (IOException exception) {
            throw new TranslationProviderException("LibreTranslate request failed: "
                    + exception.getMessage(), true, 0, exception);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new TranslationProviderException("LibreTranslate request interrupted",
                    true, 0, exception);
        }
        int status = response.statusCode();
        if (status == 200) {
            return parse(response.body(), texts.size());
        }
        long retryAfter = retryAfterSeconds(response);
        if (status == 429) {
            throw new TranslationProviderException(
                    "LibreTranslate rate limited (429): " + response.body(), true, retryAfter, null);
        }
        if (status >= 500) {
            throw new TranslationProviderException("LibreTranslate server error (" + status
                    + "): " + response.body(), true, retryAfter, null);
        }
        throw new TranslationProviderException("LibreTranslate rejected the request (" + status
                + "): " + response.body(), false, 0, null);
    }

    private List<String> parse(String body, int expected) {
        try {
            JsonNode root = objectMapper.readTree(body);
            JsonNode translated = root.get("translatedText");
            if (translated == null) {
                throw new TranslationProviderException(
                        "LibreTranslate response has no translatedText", true);
            }
            List<String> result = new ArrayList<>();
            if (translated.isArray()) {
                translated.forEach(node -> result.add(node.asText()));
            } else {
                result.add(translated.asText());
            }
            if (result.size() != expected) {
                throw new TranslationProviderException("LibreTranslate size mismatch: expected "
                        + expected + " but got " + result.size(), true);
            }
            return result;
        } catch (IOException exception) {
            throw new TranslationProviderException("Cannot parse LibreTranslate response", true,
                    0, exception);
        }
    }

    private static void apply(Map<String, String> result, List<String> texts,
                              List<String> translated) {
        if (translated.size() != texts.size()) {
            throw new TranslationProviderException("LibreTranslate size mismatch: expected "
                    + texts.size() + " but got " + translated.size(), true);
        }
        for (int index = 0; index < texts.size(); index++) {
            result.put(texts.get(index), translated.get(index));
        }
    }

    private static long retryAfterSeconds(HttpResponse<String> response) {
        return response.headers().firstValue("Retry-After")
                .map(value -> {
                    try {
                        return Long.parseLong(value.trim());
                    } catch (NumberFormatException exception) {
                        return 0L;
                    }
                }).orElse(0L);
    }
}
