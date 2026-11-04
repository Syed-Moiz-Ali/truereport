package com.truereport.delivery.api;

import com.truereport.delivery.DeliveryService;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform/deliveries")
public class PlatformDeliveryController {

    private final DeliveryService service;
    private final CurrentUserService currentUserService;

    public PlatformDeliveryController(DeliveryService service,
                                      CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public List<DeliveryDto> list(JwtAuthenticationToken authentication) {
        return service.forPlatform(currentUserService.require(authentication));
    }
}
