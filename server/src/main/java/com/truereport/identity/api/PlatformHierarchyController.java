package com.truereport.identity.api;

import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.identity.HierarchyService;
import com.truereport.identity.api.AccountActionRequest;
import com.truereport.identity.api.AuditEventDto;
import com.truereport.identity.api.CreateUserRequest;
import com.truereport.identity.api.HierarchyResponse;
import com.truereport.identity.api.HierarchyWorkshopDto;
import com.truereport.identity.api.InvitationResponse;
import com.truereport.identity.api.InviteRequest;
import com.truereport.identity.api.PlatformAccountDto;
import com.truereport.identity.api.TransferRequest;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/platform")
public class PlatformHierarchyController {

    private final HierarchyService hierarchyService;
    private final CurrentUserService currentUserService;

    public PlatformHierarchyController(HierarchyService hierarchyService,
                                       CurrentUserService currentUserService) {
        this.hierarchyService = hierarchyService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/hierarchy")
    public HierarchyResponse hierarchy(@RequestParam(required = false) String search,
                                       @RequestParam(required = false) String status) {
        return hierarchyService.hierarchy(search, status);
    }

    @GetMapping("/workshops/{workshopId}/hierarchy")
    public HierarchyWorkshopDto workshopDetail(@PathVariable UUID workshopId) {
        return hierarchyService.workshopDetail(workshopId);
    }

    @PostMapping("/users")
    public PlatformAccountDto createUser(JwtAuthenticationToken authentication,
                                         @Valid @RequestBody CreateUserRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        return hierarchyService.createUser(actor, request.email(), request.displayName(),
                request.temporaryPassword(), request.role(), request.workshopId());
    }

    @PostMapping("/invitations")
    public ResponseEntity<InvitationResponse> invite(JwtAuthenticationToken authentication,
                                                     @Valid @RequestBody InviteRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        InvitationResponse response = hierarchyService.invite(actor, request.email(),
                request.displayName(), request.role(), request.workshopId());
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(response);
    }

    @PostMapping("/users/{userId}/disable")
    public PlatformAccountDto disable(JwtAuthenticationToken authentication,
                                      @PathVariable UUID userId,
                                      @Valid @RequestBody AccountActionRequest request) {
        return hierarchyService.disableUser(currentUserService.require(authentication),
                userId, request.reason());
    }

    @PostMapping("/users/{userId}/reactivate")
    public PlatformAccountDto reactivate(JwtAuthenticationToken authentication,
                                         @PathVariable UUID userId,
                                         @Valid @RequestBody AccountActionRequest request) {
        return hierarchyService.reactivateUser(currentUserService.require(authentication),
                userId, request.reason());
    }

    @PostMapping("/users/{userId}/transfer")
    public PlatformAccountDto transfer(JwtAuthenticationToken authentication,
                                       @PathVariable UUID userId,
                                       @Valid @RequestBody TransferRequest request) {
        return hierarchyService.transferUser(currentUserService.require(authentication),
                userId, request.workshopId(), request.reason());
    }

    @GetMapping("/audit-events")
    public List<AuditEventDto> auditEvents(@RequestParam(defaultValue = "100") int limit) {
        return hierarchyService.auditEvents(limit);
    }
}
