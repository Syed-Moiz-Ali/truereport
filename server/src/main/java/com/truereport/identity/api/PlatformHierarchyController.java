package com.truereport.identity.api;

import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.identity.HierarchyService;
import com.truereport.identity.PlatformAuditService;
import jakarta.servlet.http.HttpServletRequest;
import com.truereport.identity.api.AccountActionRequest;
import com.truereport.identity.api.AuditEventDto;
import com.truereport.identity.api.CreateUserRequest;
import com.truereport.identity.api.HierarchyResponse;
import com.truereport.identity.api.HierarchyWorkshopDto;
import com.truereport.identity.api.PasswordResetRequest;
import com.truereport.identity.api.PlatformAccountDto;
import com.truereport.identity.api.TransferRequest;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/platform")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformHierarchyController {

    private final HierarchyService hierarchyService;
    private final PlatformAuditService platformAuditService;
    private final FieldAuditService fieldAuditService;
    private final CurrentUserService currentUserService;

    public PlatformHierarchyController(HierarchyService hierarchyService,
                                       PlatformAuditService platformAuditService,
                                       FieldAuditService fieldAuditService,
                                       CurrentUserService currentUserService) {
        this.hierarchyService = hierarchyService;
        this.platformAuditService = platformAuditService;
        this.fieldAuditService = fieldAuditService;
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
                                         @RequestHeader("Idempotency-Key") String idempotencyKey,
                                         @Valid @RequestBody CreateUserRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        return hierarchyService.createUser(actor, request.email(), request.displayName(),
                request.temporaryPassword(), request.role(), request.workshopId(), idempotencyKey);
    }

    @PostMapping("/users/{userId}/password-reset")
    public ResponseEntity<PlatformAccountDto> resetPassword(JwtAuthenticationToken authentication,
                                                           @PathVariable UUID userId,
                                                           @RequestHeader("Idempotency-Key") String idempotencyKey,
                                                           @Valid @RequestBody PasswordResetRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        PlatformAccountDto result = hierarchyService.resetPasswordByPlatform(
                actor, userId, request.newPassword(), idempotencyKey);
        return ResponseEntity.ok()
                .header("Cache-Control", "no-store")
                .body(result);
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
    public Object auditEvents(
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) String actor,
            @RequestParam(required = false) String dateFrom,
            @RequestParam(required = false) String dateTo,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sort,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) Integer limit) {
        if (page != null || size != null) {
            return platformAuditService.page(action, entityType, actor, dateFrom,
                    dateTo, search, sort, page == null ? 0 : page,
                    size == null ? 25 : size);
        }
        List<AuditEventDto> events = platformAuditService.query(action,
                entityType, actor, dateFrom, dateTo, search, sort);
        int bounded = limit == null ? events.size() : Math.max(1, Math.min(limit, 500));
        return events.stream().limit(bounded).toList();
    }

    @GetMapping("/audit-events/export")
    public org.springframework.http.ResponseEntity<byte[]> exportAuditEvents(
            JwtAuthenticationToken authentication,
            @RequestParam(defaultValue = "csv") String format,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) String actor,
            @RequestParam(required = false) String dateFrom,
            @RequestParam(required = false) String dateTo,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sort,
            HttpServletRequest http) {
        String normalized = "json".equalsIgnoreCase(format) ? "json" : "csv";
        byte[] body = platformAuditService.export(normalized, action, entityType,
                actor, dateFrom, dateTo, search, sort);
        CurrentUser user = currentUserService.require(authentication);
        fieldAuditService.record(user, "AUDIT_EVENTS_EXPORTED", "AUDIT_EVENT",
                "export", null,
                java.util.Map.of("format", normalized, "bytes", body.length),
                null, http);
        String contentType = "json".equals(normalized)
                ? "application/json" : "text/csv";
        return org.springframework.http.ResponseEntity.ok()
                .header(org.springframework.http.HttpHeaders.CONTENT_TYPE,
                        contentType + "; charset=utf-8")
                .header(org.springframework.http.HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"audit-events." + normalized + "\"")
                .body(body);
    }
}
