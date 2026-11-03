package com.truereport.tenancy.api;

import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.tenancy.WorkshopService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/platform")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformController {

    private final WorkshopService workshopService;
    private final CurrentUserService currentUserService;

    public PlatformController(WorkshopService workshopService, CurrentUserService currentUserService) {
        this.workshopService = workshopService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/workshops")
    public List<WorkshopDto> workshops(JwtAuthenticationToken authentication) {
        return workshopService.listForPlatform(currentUserService.require(authentication));
    }

    @GetMapping("/workshops/{workshopId}")
    public WorkshopDto workshop(@PathVariable UUID workshopId, JwtAuthenticationToken authentication) {
        CurrentUser caller = currentUserService.require(authentication);
        return workshopService.getWorkshop(workshopId, caller);
    }
}
