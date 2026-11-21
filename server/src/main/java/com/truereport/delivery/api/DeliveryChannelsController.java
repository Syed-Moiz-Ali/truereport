package com.truereport.delivery.api;

import com.truereport.delivery.DeliveryProviderRegistry;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Which delivery channels the server can actually send right now. The Workshop
 * Admin UI uses this instead of offering channels that would dead-letter.
 */
@RestController
@RequestMapping("/api/v1/workshop/delivery-channels")
@PreAuthorize("hasRole('WORKSHOP_ADMIN')")
public class DeliveryChannelsController {

    private static final List<String> CHANNELS = List.of("EMAIL", "SMS", "WHATSAPP");

    private final DeliveryProviderRegistry providers;

    public DeliveryChannelsController(DeliveryProviderRegistry providers) {
        this.providers = providers;
    }

    @GetMapping
    public ChannelsDto channels() {
        return new ChannelsDto(CHANNELS.stream()
                .map(channel -> new ChannelDto(channel, providers.isConfigured(channel)))
                .toList());
    }

    public record ChannelDto(String channel, boolean available) {
    }

    public record ChannelsDto(List<ChannelDto> channels) {
    }
}
