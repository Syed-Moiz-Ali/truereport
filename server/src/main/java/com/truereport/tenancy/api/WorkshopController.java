package com.truereport.tenancy.api;

import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.tenancy.WorkshopService;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class WorkshopController {

    private final WorkshopService workshopService;
    private final CurrentUserService currentUserService;

    public WorkshopController(WorkshopService workshopService, CurrentUserService currentUserService) {
        this.workshopService = workshopService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/workshops/{workshopId}")
    public WorkshopDto getWorkshop(@PathVariable UUID workshopId, JwtAuthenticationToken authentication) {
        CurrentUser caller = currentUserService.require(authentication);
        return workshopService.getWorkshop(workshopId, caller);
    }
}
