package com.truereport.delivery;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class DeliveryProviderRegistry {

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
        String name = channel.equals("EMAIL") ? emailProvider : "fake";
        DeliveryProvider provider = providers.get(name);
        if (provider == null) {
            throw new IllegalStateException("No delivery provider configured for " + channel);
        }
        return provider;
    }
}
