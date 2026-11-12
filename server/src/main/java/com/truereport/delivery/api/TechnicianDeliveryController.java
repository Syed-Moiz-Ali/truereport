package com.truereport.delivery.api;

import com.truereport.delivery.DeliveryService;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/technician/legacy/jobs/{jobId}/deliveries")
@PreAuthorize("hasRole('TECHNICIAN')")
public class TechnicianDeliveryController {

    private final DeliveryService service;
    private final CurrentUserService currentUserService;

    public TechnicianDeliveryController(DeliveryService service,
                                        CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public List<DeliveryDto> list(JwtAuthenticationToken authentication,
                                  @PathVariable UUID jobId) {
        return service.forTechnician(currentUserService.require(authentication), jobId);
    }
}
