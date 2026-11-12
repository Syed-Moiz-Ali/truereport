package com.truereport.localization.api;

import com.truereport.localization.PlatformWorkshopService;
import com.truereport.localization.PlatformWorkshopService.WorkshopReasonRequest;
import com.truereport.localization.PlatformWorkshopService.WorkshopUpdateRequest;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.localization.api.WorkshopDtos.WorkshopDto;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/platform/workshops")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformWorkshopController {

    private final PlatformWorkshopService workshops;
    private final CurrentUserService currentUserService;

    public PlatformWorkshopController(PlatformWorkshopService workshops,
                                      CurrentUserService currentUserService) {
        this.workshops = workshops;
        this.currentUserService = currentUserService;
    }

    @PutMapping("/{id}")
    public WorkshopDto update(JwtAuthenticationToken authentication,
                              @PathVariable("id") UUID workshopId,
                              @RequestBody(required = false) WorkshopUpdateRequest request,
                              HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return workshops.update(actor, workshopId, request, http);
    }

    @PostMapping("/{id}/deactivate")
    public WorkshopDto deactivate(JwtAuthenticationToken authentication,
                                  @PathVariable("id") UUID workshopId,
                                  @RequestBody(required = false) WorkshopReasonRequest request,
                                  HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return workshops.deactivate(actor, workshopId, request, http);
    }

    @PostMapping("/{id}/reactivate")
    public WorkshopDto reactivate(JwtAuthenticationToken authentication,
                                  @PathVariable("id") UUID workshopId,
                                  @RequestBody(required = false) WorkshopReasonRequest request,
                                  HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return workshops.reactivate(actor, workshopId, request, http);
    }
}
