package com.truereport.reports.api;

import com.truereport.reports.ReportService;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/technician/legacy/jobs/{jobId}/report")
@PreAuthorize("hasRole('TECHNICIAN')")
public class TechnicianReportController {

    private final ReportService service;
    private final CurrentUserService currentUserService;

    public TechnicianReportController(ReportService service, CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ReportStatusDto status(JwtAuthenticationToken authentication, @PathVariable UUID jobId) {
        return service.technicianStatus(currentUserService.require(authentication), jobId);
    }
}
