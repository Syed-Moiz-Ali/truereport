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
    void bundleIsGzippedAndNotCached() throws Exception {
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        String url = "http://localhost:" + port
                + "/api/v1/i18n/ui-messages/workshop_admin/bundle?lang=es";
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
        assertThat(response.headers().firstValue("Cache-Control")).hasValue("no-store");
        assertThat(response.headers().firstValue("ETag")).isEmpty();
        assertThat(response.body().length).isGreaterThan(0);
    }
}
