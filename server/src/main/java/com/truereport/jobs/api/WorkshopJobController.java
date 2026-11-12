package com.truereport.jobs.api;

import com.truereport.jobs.WorkshopJobService;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
@RequestMapping("/api/v1/workshop/legacy/jobs")
@PreAuthorize("hasRole('WORKSHOP_ADMIN')")
public class WorkshopJobController {

    private final WorkshopJobService service;
    private final CurrentUserService currentUserService;

    public WorkshopJobController(WorkshopJobService service, CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/counts")
    @PreAuthorize("hasRole('WORKSHOP_ADMIN')")
    public JobCountsDto counts(JwtAuthenticationToken authentication) {
        return service.counts(currentUserService.require(authentication));
    }

    @GetMapping
    public List<JobDto> list(JwtAuthenticationToken authentication,
                             @RequestParam(required = false) String search,
                             @RequestParam(required = false) String status) {
        return service.list(currentUserService.require(authentication), search, status);
    }

    @PostMapping
    public ResponseEntity<JobDto> create(JwtAuthenticationToken authentication,
                                         @Valid @RequestBody JobCreateRequest request) {
        return ResponseEntity.status(201).body(
                service.create(currentUserService.require(authentication), request));
    }

    @PostMapping("/{id}/assign")
    public JobDto assign(JwtAuthenticationToken authentication, @PathVariable UUID id,
                         @Valid @RequestBody AssignJobRequest request) {
        return service.assign(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/{id}/cancel")
    public JobDto cancel(JwtAuthenticationToken authentication, @PathVariable UUID id,
                         @Valid @RequestBody CancelJobRequest request) {
        return service.cancel(currentUserService.require(authentication), id, request);
    }

    @GetMapping("/{id}/assignments")
    public List<JobAssignmentDto> assignments(JwtAuthenticationToken authentication,
                                               @PathVariable UUID id) {
        return service.assignmentHistory(currentUserService.require(authentication), id);
    }
}
