package com.truereport.delivery;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DeliveryProviderRegistryTest {

    @Test
    void onlyTheConfiguredEmailProviderIsAvailable() {
        DeliveryProviderRegistry registry = new DeliveryProviderRegistry(
                List.of(provider("smtp")), "smtp");

        assertThat(registry.isConfigured("EMAIL")).isTrue();
        assertThat(registry.isConfigured("SMS")).isFalse();
        assertThat(registry.isConfigured("WHATSAPP")).isFalse();
        assertThat(registry.availableChannels()).containsExactly("EMAIL");
        assertThatThrownBy(() -> registry.forChannel("SMS"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("SMS");
    }

    @Test
    void configuredSmsProviderIsOffered() {
        DeliveryProviderRegistry registry = new DeliveryProviderRegistry(
                List.of(provider("smtp"), provider("sms")), "smtp");

        assertThat(registry.isConfigured("SMS")).isTrue();
        assertThat(registry.availableChannels()).containsExactly("EMAIL", "SMS");
    }

    @Test
    void fakeNeverBacksARealChannel() {
        DeliveryProviderRegistry registry = new DeliveryProviderRegistry(
                List.of(provider("fake")), "smtp");

        assertThat(registry.isConfigured("EMAIL")).isFalse();
        assertThat(registry.isConfigured("SMS")).isFalse();
        assertThat(registry.isConfigured("WHATSAPP")).isFalse();
        assertThat(registry.availableChannels()).isEmpty();
        assertThatThrownBy(() -> registry.forChannel("WHATSAPP"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("WHATSAPP");
    }

    @Test
    void testProfileCanExplicitlyUseTheFakeEmailProvider() {
        DeliveryProviderRegistry registry = new DeliveryProviderRegistry(
                List.of(provider("fake")), "fake");

        assertThat(registry.isConfigured("EMAIL")).isTrue();
        assertThat(registry.availableChannels()).containsExactly("EMAIL");
    }

    private static DeliveryProvider provider(String name) {
        DeliveryProvider provider = mock(DeliveryProvider.class);
        when(provider.name()).thenReturn(name);
        return provider;
    }
}
