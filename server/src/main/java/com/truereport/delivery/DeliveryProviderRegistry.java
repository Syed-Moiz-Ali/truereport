package com.truereport.delivery;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Resolves the provider bean for a delivery channel. There is no implicit
 * fallback to the fake provider: a channel is available only when a real bean
 * for it (or the configured email provider) exists.
 */
@Component
public class DeliveryProviderRegistry {

    private static final List<String> CHANNEL_ORDER = List.of("EMAIL", "SMS", "WHATSAPP");

    private final Map<String, DeliveryProvider> providers = new LinkedHashMap<>();
    private final String emailProvider;

    public DeliveryProviderRegistry(List<DeliveryProvider> providers,
                                    @Value("${truereport.delivery.email-provider:smtp}")
                                    String emailProvider) {
        for (DeliveryProvider provider : providers) {
            this.providers.put(provider.name(), provider);
        }
        this.emailProvider = emailProvider;
    }

    public DeliveryProvider forChannel(String channel) {
        String name = providerName(channel);
        DeliveryProvider provider = name == null ? null : providers.get(name);
        if (provider == null) {
            throw new IllegalStateException("No delivery provider configured for " + channel);
        }
        return provider;
    }

    /**
     * EMAIL is available when the configured email provider exists; SMS and
     * WhatsApp require a bean whose {@code name()} is the lower-case channel.
     */
    public boolean isConfigured(String channel) {
        String name = providerName(channel);
        return name != null && providers.containsKey(name);
    }

    /** Configured channels in the fixed UI order. */
    public List<String> availableChannels() {
        return CHANNEL_ORDER.stream().filter(this::isConfigured).toList();
    }

    private String providerName(String channel) {
        if (channel == null || channel.isBlank()) {
            return null;
        }
        String normalized = channel.trim().toUpperCase(Locale.ROOT);
        if (normalized.equals("EMAIL")) {
            return emailProvider == null || emailProvider.isBlank()
                    ? null : emailProvider.trim().toLowerCase(Locale.ROOT);
        }
        return normalized.toLowerCase(Locale.ROOT);
    }
}
