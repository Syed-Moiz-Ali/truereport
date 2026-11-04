package com.truereport.delivery.api;

import com.truereport.delivery.DeliveryService;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workshop/jobs/{jobId}/deliveries")
public class WorkshopDeliveryController {

    private final DeliveryService service;
    private final CurrentUserService currentUserService;

    public WorkshopDeliveryController(DeliveryService service,
                                      CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    public ResponseEntity<DeliveryDto> send(JwtAuthenticationToken authentication,
                                            @PathVariable UUID jobId,
                                            @RequestHeader("Idempotency-Key") String idempotencyKey,
                                            @Valid @RequestBody SendDeliveryRequest request) {
        return ResponseEntity.status(201).body(service.request(
                currentUserService.require(authentication), jobId, request, idempotencyKey));
    }

    @GetMapping
    public List<DeliveryDto> list(JwtAuthenticationToken authentication,
                                  @PathVariable UUID jobId) {
        return service.forAdmin(currentUserService.require(authentication), jobId);
    }

    @PostMapping("/{deliveryId}/retry")
    public DeliveryDto retry(JwtAuthenticationToken authentication,
                             @PathVariable UUID jobId,
                             @PathVariable UUID deliveryId,
                             @RequestHeader("Idempotency-Key") String idempotencyKey) {
        return service.retry(currentUserService.require(authentication), jobId, deliveryId,
                idempotencyKey);
    }
}
