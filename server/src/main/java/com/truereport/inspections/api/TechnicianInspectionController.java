package com.truereport.inspections.api;

import com.truereport.inspections.InspectionService;
import com.truereport.jobs.api.JobDto;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/technician/legacy/jobs")
@PreAuthorize("hasRole('TECHNICIAN')")
public class TechnicianInspectionController {

    private final InspectionService service;
    private final CurrentUserService currentUserService;

    public TechnicianInspectionController(InspectionService service,
                                          CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/{id}/start")
    public InspectionChecklistDto start(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.start(currentUserService.require(authentication), id);
    }

    @GetMapping("/{id}/checklist")
    public InspectionChecklistDto checklist(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.checklist(currentUserService.require(authentication), id);
    }

    @GetMapping("/{id}/equipment")
    public EquipmentListDto equipment(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.equipment(currentUserService.require(authentication), id);
    }

    @PutMapping("/{id}/customer")
    public JobDto customer(JwtAuthenticationToken authentication, @PathVariable UUID id,
                           @Valid @RequestBody CustomerUpdateRequest request) {
        return service.updateCustomer(currentUserService.require(authentication), id, request);
    }

    @PutMapping("/{id}/vehicle")
    public JobDto vehicle(JwtAuthenticationToken authentication, @PathVariable UUID id,
                          @Valid @RequestBody VehicleUpdateRequest request) {
        return service.updateVehicle(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/{id}/consent")
    public ResponseEntity<Void> consent(JwtAuthenticationToken authentication, @PathVariable UUID id,
                                        @Valid @RequestBody ConsentRequest request) {
        service.recordConsent(currentUserService.require(authentication), id, request);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/items/{itemId}/assessment")
    public InspectionItemDto assess(JwtAuthenticationToken authentication, @PathVariable UUID id,
                                    @PathVariable UUID itemId,
                                    @Valid @RequestBody AssessmentRequest request) {
        return service.assess(currentUserService.require(authentication), id, itemId, request);
    }

    @GetMapping("/{id}/review")
    public ReviewDto review(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.review(currentUserService.require(authentication), id);
    }

    @PostMapping("/{id}/ready")
    public InspectionChecklistDto ready(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.markReady(currentUserService.require(authentication), id);
    }

    @PostMapping("/{id}/finalize")
    public FinalizeResponse finalizeInspection(
            JwtAuthenticationToken authentication,
            @PathVariable UUID id,
            @RequestHeader("Idempotency-Key") String idempotencyKey) {
        return service.finalizeInspection(currentUserService.require(authentication), id, idempotencyKey);
    }
}
