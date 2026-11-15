package com.truereport;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class PlatformUiMessagesCompressionIT {

    @LocalServerPort
    int port;

    @Test
    void bundleUsesWeakEtagAndGzipCompression() throws Exception {
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        String url = "http://localhost:" + port
                + "/api/v1/i18n/ui-messages/bundle?lang=en&namespaces=platform_admin,common";
        HttpResponse<byte[]> response = client.send(
                HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .header("Accept-Encoding", "gzip")
                        .timeout(Duration.ofSeconds(20))
                        .GET()
                        .build(),
                HttpResponse.BodyHandlers.ofByteArray());

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.headers().firstValue("Content-Encoding")).hasValue("gzip");
        String etag = response.headers().firstValue("ETag").orElseThrow();
        assertThat(etag).startsWith("W/");
        assertThat(response.body().length).isGreaterThan(0);

        HttpResponse<Void> notModified = client.send(
                HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .header("Accept-Encoding", "gzip")
                        .header("If-None-Match", etag)
                        .timeout(Duration.ofSeconds(20))
                        .GET()
                        .build(),
                HttpResponse.BodyHandlers.discarding());
        assertThat(notModified.statusCode()).isEqualTo(304);
    }
}
