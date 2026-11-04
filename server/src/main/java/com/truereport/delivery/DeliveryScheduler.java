package com.truereport.delivery;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "truereport.delivery.worker-enabled", havingValue = "true", matchIfMissing = true)
public class DeliveryScheduler {

    private final DeliveryService service;

    public DeliveryScheduler(DeliveryService service) {
        this.service = service;
    }

    @Scheduled(fixedDelayString = "${truereport.delivery.worker-delay-ms:2000}")
    public void run() {
        service.poll();
    }
}
