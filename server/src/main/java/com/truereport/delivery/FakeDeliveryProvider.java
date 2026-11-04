package com.truereport.delivery;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

@Component
@ConditionalOnProperty(name = "truereport.delivery.fake-enabled", havingValue = "true", matchIfMissing = true)
public class FakeDeliveryProvider implements DeliveryProvider {

    private final List<DeliveryMessage> messages = new ArrayList<>();
    private final AtomicInteger failuresRemaining = new AtomicInteger();
    private String lastProviderMessageId;

    @Override
    public String name() {
        return "fake";
    }

    @Override
    public synchronized DeliveryResult send(DeliveryMessage message) {
        if (failuresRemaining.getAndUpdate(value -> Math.max(0, value - 1)) > 0) {
            return DeliveryResult.failed("FAKE_PROVIDER_FAILURE", "Simulated provider failure");
        }
        messages.add(message);
        lastProviderMessageId = "fake-" + UUID.randomUUID();
        return DeliveryResult.sent(lastProviderMessageId);
    }

    public synchronized List<DeliveryMessage> messages() {
        return List.copyOf(messages);
    }

    public synchronized DeliveryMessage lastMessage() {
        return messages.isEmpty() ? null : messages.get(messages.size() - 1);
    }

    public synchronized String lastProviderMessageId() {
        return lastProviderMessageId;
    }

    public void failNext(int count) {
        failuresRemaining.set(Math.max(0, count));
    }

    public synchronized void clear() {
        messages.clear();
        lastProviderMessageId = null;
        failuresRemaining.set(0);
    }
}
