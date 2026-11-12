package com.truereport.governance;

import com.truereport.governance.GovernanceDtos.ConfigHealthDto;
import com.truereport.governance.GovernanceDtos.CreateReleaseRequest;
import com.truereport.governance.GovernanceDtos.ImpactDto;
import com.truereport.governance.GovernanceDtos.ReleaseDto;
import com.truereport.governance.GovernanceDtos.TransitionReleaseRequest;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformGovernanceController {

    private final GovernanceService governance;
    private final CurrentUserService currentUserService;

    public PlatformGovernanceController(GovernanceService governance,
                                        CurrentUserService currentUserService) {
        this.governance = governance;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/config-health")
    public ConfigHealthDto configHealth() {
        return governance.configHealth();
    }

    @GetMapping("/config-health/{entityType}")
    public ConfigHealthDto configHealth(@PathVariable String entityType) {
        return governance.configHealth(entityType);
    }

    @GetMapping("/master/{entityType}/{id}/impact")
    public ImpactDto impact(@PathVariable String entityType, @PathVariable String id) {
        return governance.impact(entityType, id);
    }

    @GetMapping("/releases")
    public List<ReleaseDto> releases() {
        return governance.releases();
    }

    @PostMapping("/releases")
    public ResponseEntity<ReleaseDto> createRelease(JwtAuthenticationToken authentication,
                                                    @RequestBody CreateReleaseRequest request) {
        return ResponseEntity.status(201).body(
                governance.createRelease(currentUserService.require(authentication), request));
    }

    @PostMapping("/releases/{id}/submit")
    public ReleaseDto submit(JwtAuthenticationToken authentication, @PathVariable String id) {
        return governance.transition(currentUserService.require(authentication), id, "REVIEW", null);
    }

    @PostMapping("/releases/{id}/approve")
    public ReleaseDto approve(JwtAuthenticationToken authentication, @PathVariable String id,
                              @RequestBody(required = false) TransitionReleaseRequest request) {
        return governance.transition(currentUserService.require(authentication), id, "APPROVED",
                request == null ? null : request.reason());
    }

    @PostMapping("/releases/{id}/publish")
    public ReleaseDto publish(JwtAuthenticationToken authentication, @PathVariable String id) {
        return governance.transition(currentUserService.require(authentication), id, "PUBLISHED", null);
    }

    @PostMapping("/releases/{id}/deprecate")
    public ReleaseDto deprecate(JwtAuthenticationToken authentication, @PathVariable String id,
                                @RequestBody(required = false) TransitionReleaseRequest request) {
        return governance.transition(currentUserService.require(authentication), id, "DEPRECATED",
                request == null ? null : request.reason());
    }
}
