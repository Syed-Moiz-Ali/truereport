package com.truereport.shared.i18n;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Health signal for the content translation dependency.
 *
 * <p>When LibreTranslate is the active provider, `/actuator/health` turns DOWN
 * if the service is unreachable, so a deployment cannot look healthy while
 * every translation job is failing.</p>
 */
@Component
public class TranslationProviderHealthIndicator implements HealthIndicator {

    private final ObjectProvider<TranslationProvider> provider;
    private final String url;
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(3))
            .build();

    public TranslationProviderHealthIndicator(
            ObjectProvider<TranslationProvider> provider,
            @Value("${truereport.i18n.translation.libretranslate.url:}") String url) {
        this.provider = provider;
        this.url = url == null ? "" : url.replaceAll("/+$", "");
    }

    @Override
    public Health health() {
        TranslationProvider active = provider.getIfAvailable();
        if (active == null) {
            return Health.down().withDetail("provider", "none").build();
        }
        if (!LibreTranslateProvider.ID.equals(active.id())) {
            return Health.up()
                    .withDetail("provider", active.id())
                    .withDetail("note", "non-network provider")
                    .build();
        }
        if (url.isBlank()) {
            return Health.down()
                    .withDetail("provider", active.id())
                    .withDetail("reason", "libretranslate URL is not configured")
                    .build();
        }
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(url + "/languages"))
                    .timeout(Duration.ofSeconds(3))
                    .GET()
                    .build();
            HttpResponse<Void> response = client.send(request, HttpResponse.BodyHandlers.discarding());
            if (response.statusCode() == 200) {
                return Health.up()
                        .withDetail("provider", active.id())
                        .withDetail("url", url)
                        .build();
            }
            return Health.down()
                    .withDetail("provider", active.id())
                    .withDetail("url", url)
                    .withDetail("status", response.statusCode())
                    .build();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return Health.down(exception)
                    .withDetail("provider", active.id())
                    .withDetail("url", url)
                    .build();
        } catch (Exception exception) {
            return Health.down(exception)
                    .withDetail("provider", active.id())
                    .withDetail("url", url)
                    .build();
        }
    }
}
