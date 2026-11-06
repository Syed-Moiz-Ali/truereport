package com.truereport.reports.api;

import com.truereport.reports.ReportService;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
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

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workshop/jobs/{jobId}/report")
@PreAuthorize("hasRole('WORKSHOP_ADMIN')")
public class WorkshopReportController {

    private final ReportService service;
    private final CurrentUserService currentUserService;

    public WorkshopReportController(ReportService service, CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public ReportAdminDto get(JwtAuthenticationToken authentication, @PathVariable UUID jobId) {
        return service.adminForJob(currentUserService.require(authentication), jobId);
    }

    @PostMapping("/retry")
    public ReportAdminDto retry(JwtAuthenticationToken authentication, @PathVariable UUID jobId) {
        return service.retry(currentUserService.require(authentication), jobId);
    }

    @PostMapping("/link")
    public ReportLinkResponse activate(JwtAuthenticationToken authentication, @PathVariable UUID jobId) {
        return service.activate(currentUserService.require(authentication), jobId);
    }

    @PostMapping("/link/revoke")
    public ReportLinkResponse revoke(JwtAuthenticationToken authentication, @PathVariable UUID jobId,
                                     @Valid @RequestBody RevokeLinkRequest request) {
        return service.revoke(currentUserService.require(authentication), jobId, request);
    }

    @PutMapping("/pdf-download")
    public ReportLinkResponse pdfDownload(JwtAuthenticationToken authentication, @PathVariable UUID jobId,
                                          @RequestBody PdfDownloadRequest request) {
        return service.setPdfDownload(currentUserService.require(authentication), jobId, request.enabled());
    }

    @GetMapping("/pdf")
    public ResponseEntity<byte[]> pdf(JwtAuthenticationToken authentication, @PathVariable UUID jobId) {
        byte[] bytes = service.pdfForAdmin(currentUserService.require(authentication), jobId);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .cacheControl(CacheControl.noStore())
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename("inspection-report.pdf").build().toString())
                .body(bytes);
    }
}
