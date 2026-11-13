package com.truereport.uimessages;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoogleTranslateProviderTest {

    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void retriesOn429ThenSucceeds() throws Exception {
        AtomicInteger calls = new AtomicInteger();
        start(exchange -> {
            int call = calls.incrementAndGet();
            if (call <= 2) {
                respond(exchange, 429, "{}");
            } else {
                respond(exchange, 200, """
                        [[["Bonjour","Hello",null,null,10]],null,"en"]
                        """);
            }
        });
        UiTranslationProperties properties = properties(3);

        String translated = new GoogleTranslateProvider(new ObjectMapper(), properties)
                .translate("Hello", "fr");

        assertThat(translated).isEqualTo("Bonjour");
        assertThat(calls.get()).isEqualTo(3);
    }

    @Test
    void failsCleanlyAfterRepeated5xx() throws Exception {
        AtomicInteger calls = new AtomicInteger();
        start(exchange -> {
            calls.incrementAndGet();
            respond(exchange, 500, "{}");
        });
        UiTranslationProperties properties = properties(2);

        assertThatThrownBy(() -> new GoogleTranslateProvider(new ObjectMapper(), properties)
                .translate("Hello", "fr"))
                .isInstanceOf(UiTextTranslationException.class)
                .hasMessageContaining("HTTP 500");
        assertThat(calls.get()).isEqualTo(2);
    }

    @Test
    void fallsBackToBaseLanguageOnlyForUnsupportedTarget() throws Exception {
        List<String> targets = Collections.synchronizedList(new ArrayList<>());
        start(exchange -> {
            String target = queryParam(exchange, "tl");
            targets.add(target);
            if ("pt-BR".equals(target)) {
                respond(exchange, 400, """
                        {"error":{"message":"Target language is not supported"}}
                        """);
            } else if ("pt".equals(target)) {
                respond(exchange, 200, """
                        [[["Olá","Hello",null,null,10]],null,"en"]
                        """);
            } else {
                respond(exchange, 500, "{}");
            }
        });
        UiTranslationProperties properties = properties(2);

        String translated = new GoogleTranslateProvider(new ObjectMapper(), properties)
                .translate("Hello", "pt-BR");

        assertThat(translated).isEqualTo("Olá");
        assertThat(targets).containsExactly("pt-BR", "pt");
    }

    @Test
    void unsupportedTargetWithoutBaseFailsClearly() throws Exception {
        List<String> targets = Collections.synchronizedList(new ArrayList<>());
        start(exchange -> {
            targets.add(queryParam(exchange, "tl"));
            respond(exchange, 400, """
                    {"error":{"message":"Target language is not supported"}}
                    """);
        });
        UiTranslationProperties properties = properties(2);

        assertThatThrownBy(() -> new GoogleTranslateProvider(new ObjectMapper(), properties)
                .translate("Hello", "xx"))
                .isInstanceOf(UiTextTranslationException.class)
                .hasMessageContaining("xx")
                .hasMessageContaining("HTTP 400");
        assertThat(targets).containsExactly("xx");
    }

    @Test
    void nonUnsupportedBadRequestDoesNotFallback() throws Exception {
        List<String> targets = Collections.synchronizedList(new ArrayList<>());
        start(exchange -> {
            targets.add(queryParam(exchange, "tl"));
            respond(exchange, 400, "{\"error\":{\"message\":\"Bad Request\"}}");
        });
        UiTranslationProperties properties = properties(2);

        assertThatThrownBy(() -> new GoogleTranslateProvider(new ObjectMapper(), properties)
                .translate("Hello", "pt-BR"))
                .isInstanceOf(UiTextTranslationException.class)
                .hasMessageContaining("HTTP 400");
        assertThat(targets).containsExactly("pt-BR");
    }

    @Test
    void rejectsEmptyTargetLanguage() {
        UiTranslationProperties properties = new UiTranslationProperties();
        properties.setBaseUrl("http://127.0.0.1:1/translate");

        assertThatThrownBy(() -> new GoogleTranslateProvider(new ObjectMapper(), properties)
                .translate("Hello", ""))
                .isInstanceOf(UiTextTranslationException.class)
                .hasMessageContaining("Target language code is required");
    }

    private UiTranslationProperties properties(int attempts) {
        UiTranslationProperties properties = new UiTranslationProperties();
        properties.setBaseUrl("http://127.0.0.1:" + server.getAddress().getPort() + "/translate");
        properties.setMaxAttempts(attempts);
        properties.setMaxConcurrency(2);
        return properties;
    }

    private void start(Handler handler) throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/translate", exchange -> {
            try {
                handler.handle(exchange);
            } finally {
                exchange.close();
            }
        });
        server.start();
    }

    private static String queryParam(HttpExchange exchange, String name) {
        String query = exchange.getRequestURI().getRawQuery();
        if (query == null) {
            return null;
        }
        for (String part : query.split("&")) {
            int equals = part.indexOf('=');
            String key = equals < 0 ? part : part.substring(0, equals);
            if (name.equals(URLDecoder.decode(key, StandardCharsets.UTF_8))) {
                String value = equals < 0 ? "" : part.substring(equals + 1);
                return URLDecoder.decode(value, StandardCharsets.UTF_8);
            }
        }
        return null;
    }

    private static void respond(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
    }

    private interface Handler {
        void handle(HttpExchange exchange) throws IOException;
    }
}
