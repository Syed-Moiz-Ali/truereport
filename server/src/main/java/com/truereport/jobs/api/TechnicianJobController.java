package com.truereport.jobs.api;

import com.truereport.jobs.WorkshopJobService;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/technician/jobs")
public class TechnicianJobController {

    private final WorkshopJobService service;
    private final CurrentUserService currentUserService;

    public TechnicianJobController(WorkshopJobService service, CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    public ResponseEntity<JobDto> create(JwtAuthenticationToken authentication,
                                         @Valid @RequestBody JobCreateRequest request) {
        return ResponseEntity.status(201).body(
                service.createWalkIn(currentUserService.require(authentication), request));
    }

    @GetMapping
    public List<JobDto> list(JwtAuthenticationToken authentication) {
        return service.technicianJobs(currentUserService.require(authentication));
    }

    @GetMapping("/{id}")
    public JobDto get(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.technicianJob(currentUserService.require(authentication), id);
    }
}
