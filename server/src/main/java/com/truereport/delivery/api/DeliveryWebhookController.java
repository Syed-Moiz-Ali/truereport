package com.truereport.delivery.api;

import com.truereport.delivery.DeliveryWebhookService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/delivery/webhooks")
public class DeliveryWebhookController {

    private final DeliveryWebhookService service;

    public DeliveryWebhookController(DeliveryWebhookService service) {
        this.service = service;
    }

    @PostMapping("/{provider}")
    public ResponseEntity<Void> webhook(@PathVariable String provider,
                                        @RequestHeader("X-Delivery-Signature") String signature,
                                        @RequestBody String payload) {
        service.handle(provider, payload, signature);
        return ResponseEntity.ok().build();
    }
}
