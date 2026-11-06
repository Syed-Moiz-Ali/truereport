package com.truereport.identity.api;

import com.truereport.identity.HierarchyService;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.truereport.identity.StaffService;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workshop")
public class StaffController {

    private final StaffService staffService;
    private final HierarchyService hierarchyService;
    private final CurrentUserService currentUserService;

    public StaffController(StaffService staffService,
                           HierarchyService hierarchyService,
                           CurrentUserService currentUserService) {
        this.staffService = staffService;
        this.hierarchyService = hierarchyService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/staff")
    @PreAuthorize("hasRole('WORKSHOP_ADMIN')")
    public List<StaffDto> staff(JwtAuthenticationToken authentication) {
        return staffService.staff(currentUserService.require(authentication));
    }

    @PostMapping("/technicians")
    @PreAuthorize("hasRole('WORKSHOP_ADMIN')")
    public PlatformAccountDto createTechnician(JwtAuthenticationToken authentication,
                                               @RequestHeader("Idempotency-Key") String idempotencyKey,
                                               @Valid @RequestBody CreateTechnicianRequest request) {
        return hierarchyService.createTechnician(currentUserService.require(authentication),
                request.email(), request.displayName(), request.initialPassword(), idempotencyKey);
    }

    @PostMapping("/technicians/{userId}/password-reset")
    @PreAuthorize("hasRole('WORKSHOP_ADMIN')")
    public ResponseEntity<PlatformAccountDto> resetTechnicianPassword(JwtAuthenticationToken authentication,
                                                                     @PathVariable UUID userId,
                                                                     @RequestHeader("Idempotency-Key") String idempotencyKey,
                                                                     @Valid @RequestBody PasswordResetRequest request) {
        PlatformAccountDto result = hierarchyService.resetPasswordByWorkshopAdmin(
                currentUserService.require(authentication), userId, request.newPassword(), idempotencyKey);
        return ResponseEntity.ok()
                .header("Cache-Control", "no-store")
                .body(result);
    }
}
