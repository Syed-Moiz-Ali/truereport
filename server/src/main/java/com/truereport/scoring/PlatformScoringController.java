package com.truereport.scoring;

import com.truereport.scoring.ScoringDtos.GradeBoundaryDto;
import com.truereport.scoring.ScoringDtos.GradeBoundariesRequest;
import com.truereport.scoring.ScoringDtos.RejectScoringRuleRequest;
import com.truereport.scoring.ScoringDtos.ScoringRuleDetail;
import com.truereport.scoring.ScoringDtos.ScoringRuleDto;
import com.truereport.scoring.ScoringDtos.UpdateScoringRuleRequest;
import com.truereport.shared.security.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform/scoring-rules")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformScoringController {

    private final ScoringService scoringService;
    private final CurrentUserService currentUserService;

    public PlatformScoringController(ScoringService scoringService,
                                     CurrentUserService currentUserService) {
        this.scoringService = scoringService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ScoringRuleDetail active() {
        return scoringService.getActive();
    }

    @GetMapping("/{id}/grade-boundaries")
    public List<GradeBoundaryDto> boundaries(@PathVariable String id) {
        return scoringService.boundaries(id);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ScoringRuleDto> update(JwtAuthenticationToken authentication,
                                                 @PathVariable String id,
                                                 @RequestBody UpdateScoringRuleRequest request,
                                                 HttpServletRequest http) {
        ScoringRuleDto updated = scoringService.updateRule(
                currentUserService.require(authentication), id, request, http);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(updated);
    }

    @PostMapping("/{id}/approve")
    public ScoringRuleDto approve(JwtAuthenticationToken authentication,
                                  @PathVariable String id,
                                  HttpServletRequest http) {
        return scoringService.approveRule(currentUserService.require(authentication), id, http);
    }

    @PostMapping("/{id}/reject")
    public ScoringRuleDto reject(JwtAuthenticationToken authentication,
                                 @PathVariable String id,
                                 @RequestBody(required = false) RejectScoringRuleRequest request,
                                 HttpServletRequest http) {
        String reason = request == null ? null : request.reason();
        return scoringService.rejectRule(currentUserService.require(authentication), id, reason, http);
    }

    @PutMapping("/{id}/grade-boundaries")
    public List<GradeBoundaryDto> replaceBoundaries(JwtAuthenticationToken authentication,
                                                    @PathVariable String id,
                                                    @RequestBody GradeBoundariesRequest request,
                                                    HttpServletRequest http) {
        List<GradeBoundaryDto> boundaries = request == null ? List.of() : request.boundaries();
        return scoringService.replaceBoundaries(currentUserService.require(authentication), id,
                boundaries, http);
    }

    @PostMapping("/{id}/grade-boundaries/approve")
    public List<GradeBoundaryDto> approveBoundaries(JwtAuthenticationToken authentication,
                                                    @PathVariable String id,
                                                    HttpServletRequest http) {
        return scoringService.approveBoundaries(currentUserService.require(authentication), id, http);
    }
}
