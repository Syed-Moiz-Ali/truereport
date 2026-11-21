package com.truereport.shared.i18n;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LibreTranslateProviderTest {

    private HttpServer server;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @AfterEach
    void stop() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void arrayRequestReturnsTranslatedTextInOrder() {
        List<String> bodies = new ArrayList<>();
        start(exchange -> respond(exchange, 200, """
                {"translatedText":["uno","dos"]}
                """, Map.of()), bodies);

        TranslationProvider provider = provider(Duration.ofSeconds(5), 20);
        Map<String, String> result = provider.translate(List.of("one", "two"), "en", "es");

        assertThat(result).containsEntry("one", "uno").containsEntry("two", "dos");
        assertThat(bodies).hasSize(1);
        assertThat(bodies.get(0)).contains("\"q\":[\"one\",\"two\"]");
    }

    @Test
    void singleRequestUsesAStringQ() {
        List<String> bodies = new ArrayList<>();
        start(exchange -> respond(exchange, 200, """
                {"translatedText":"uno"}
                """, Map.of()), bodies);

        TranslationProvider provider = provider(Duration.ofSeconds(5), 1);
        Map<String, String> result = provider.translate(List.of("one"), "en", "es");

        assertThat(result).containsEntry("one", "uno");
        assertThat(bodies.get(0)).contains("\"q\":\"one\"");
    }

    @Test
    void batchRejectedFallsBackToPerTextRequests() {
        Deque<Integer> statuses = new ArrayDeque<>(List.of(400, 200, 200));
        List<String> bodies = new ArrayList<>();
        start(exchange -> {
            int status = statuses.removeFirst();
            respond(exchange, status, status == 400
                    ? "{\"error\":\"q must be a string\"}"
                    : "{\"translatedText\":\"uno\"}", Map.of());
        }, bodies);

        TranslationProvider provider = provider(Duration.ofSeconds(5), 20);
        Map<String, String> result = provider.translate(List.of("one", "two"), "en", "es");

        assertThat(result).containsEntry("one", "uno").containsEntry("two", "uno");
        assertThat(bodies).hasSize(3);
    }

    @Test
    void rateLimitIsRetryableWithRetryAfter() {
        Deque<Integer> statuses = new ArrayDeque<>(List.of(429, 200));
        start(exchange -> {
            int status = statuses.removeFirst();
            respond(exchange, status, status == 429
                    ? "{\"error\":\"slow down\"}"
                    : "{\"translatedText\":\"uno\"}", Map.of("Retry-After", "3"));
        }, new ArrayList<>());

        TranslationProvider provider = provider(Duration.ofSeconds(5), 20);
        assertThatThrownBy(() -> provider.translate(List.of("one"), "en", "es"))
                .isInstanceOf(TranslationProviderException.class)
                .satisfies(exception -> {
                    TranslationProviderException providerException =
                            (TranslationProviderException) exception;
                    assertThat(providerException.retryable()).isTrue();
                    assertThat(providerException.retryAfterSeconds()).isEqualTo(3);
                });

        assertThat(provider.translate(List.of("one"), "en", "es"))
                .containsEntry("one", "uno");
    }

    @Test
    void serverErrorIsRetryableThenSucceeds() {
        Deque<Integer> statuses = new ArrayDeque<>(List.of(500, 200));
        start(exchange -> {
            int status = statuses.removeFirst();
            respond(exchange, status, status == 500
                    ? "{\"error\":\"boom\"}"
                    : "{\"translatedText\":\"uno\"}", Map.of());
        }, new ArrayList<>());

        TranslationProvider provider = provider(Duration.ofSeconds(5), 20);
        assertThatThrownBy(() -> provider.translate(List.of("one"), "en", "es"))
                .isInstanceOf(TranslationProviderException.class)
                .satisfies(exception ->
                        assertThat(((TranslationProviderException) exception).retryable()).isTrue());
        assertThat(provider.translate(List.of("one"), "en", "es"))
                .containsEntry("one", "uno");
    }

    @Test
    void clientErrorIsNonRetryableAndMentionsTheLanguage() {
        start(exchange -> respond(exchange, 400,
                "{\"error\":\"language fr is not supported\"}", Map.of()), new ArrayList<>());

        TranslationProvider provider = provider(Duration.ofSeconds(5), 20);
        assertThatThrownBy(() -> provider.translate(List.of("one"), "en", "fr"))
                .isInstanceOf(TranslationProviderException.class)
                .hasMessageContaining("language")
                .satisfies(exception ->
                        assertThat(((TranslationProviderException) exception).retryable()).isFalse());
    }

    @Test
    void timeoutIsRetryable() {
        start(exchange -> {
            try {
                Thread.sleep(500);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
            }
            respond(exchange, 200, "{\"translatedText\":\"uno\"}", Map.of());
        }, new ArrayList<>());

        TranslationProvider provider = provider(Duration.ofMillis(100), 20);
        assertThatThrownBy(() -> provider.translate(List.of("one"), "en", "es"))
                .isInstanceOf(TranslationProviderException.class)
                .satisfies(exception ->
                        assertThat(((TranslationProviderException) exception).retryable()).isTrue());
    }

    private TranslationProvider provider(Duration timeout, int batchSize) {
        return new LibreTranslateProvider("http://127.0.0.1:" + server.getAddress().getPort(),
                timeout, null, batchSize, "text", objectMapper,
                java.net.http.HttpClient.newBuilder().connectTimeout(timeout).build());
    }

    private interface Script {
        void handle(HttpExchange exchange) throws IOException;
    }

    private void start(Script script, List<String> bodies) {
        try {
            server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            server.createContext("/translate", exchange -> {
                String body = new String(exchange.getRequestBody().readAllBytes(),
                        StandardCharsets.UTF_8);
                bodies.add(body);
                script.handle(exchange);
            });
            server.start();
        } catch (IOException exception) {
            throw new IllegalStateException(exception);
        }
    }

    private static void respond(HttpExchange exchange, int status, String body,
                                Map<String, String> headers) throws IOException {
        headers.forEach((name, value) -> exchange.getResponseHeaders().add(name, value));
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
