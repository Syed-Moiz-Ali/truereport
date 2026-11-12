package com.truereport.jobs.api;

import com.truereport.jobs.WorkshopJobAdminService;
import com.truereport.jobs.WorkshopJobAdminService.DocumentContent;
import com.truereport.jobs.api.WorkshopJobDtos.ApproveJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.AssignTechnicianRequest;
import com.truereport.jobs.api.WorkshopJobDtos.AssignmentDto;
import com.truereport.jobs.api.WorkshopJobDtos.AvailableTemplateDto;
import com.truereport.jobs.api.WorkshopJobDtos.CancelJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.CreateJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.JobDto;
import com.truereport.jobs.api.WorkshopJobDtos.JobPageDto;
import com.truereport.jobs.api.WorkshopJobDtos.JobStatusCountsDto;
import com.truereport.jobs.api.WorkshopJobDtos.NotificationDto;
import com.truereport.jobs.api.WorkshopJobDtos.PublishChecklistDto;
import com.truereport.jobs.api.WorkshopJobDtos.PublishJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.PublicLinkDto;
import com.truereport.jobs.api.WorkshopJobDtos.ReasonRequest;
import com.truereport.jobs.api.WorkshopJobDtos.RejectJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.ReportDocumentDto;
import com.truereport.jobs.api.WorkshopJobDtos.ReviewDto;
import com.truereport.jobs.api.WorkshopJobDtos.TemplateVersionDetailDto;
import com.truereport.jobs.api.WorkshopJobDtos.UpdateJobRequest;
import com.truereport.shared.security.CurrentUserService;
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
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/v1/workshop")
@PreAuthorize("hasRole('WORKSHOP_ADMIN')")
public class WorkshopJobAdminController {

    private final WorkshopJobAdminService service;
    private final CurrentUserService currentUserService;

    public WorkshopJobAdminController(WorkshopJobAdminService service,
                                         CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    // ------------------------------------------------------------- templates

    @GetMapping("/template-versions/available")
    public List<AvailableTemplateDto> availableTemplates(JwtAuthenticationToken authentication) {
        return service.availableTemplates(currentUserService.require(authentication));
    }

    @GetMapping("/template-versions/{versionId}")
    public TemplateVersionDetailDto templateVersion(JwtAuthenticationToken authentication,
                                                     @PathVariable String versionId) {
        return service.templateVersion(currentUserService.require(authentication), versionId);
    }

    // ------------------------------------------------------------------ jobs

    @GetMapping("/jobs")
    public JobPageDto list(JwtAuthenticationToken authentication,
                           @RequestParam(defaultValue = "0") int page,
                           @RequestParam(defaultValue = "20") int size,
                           @RequestParam(required = false) String status,
                           @RequestParam(required = false) String search,
                           @RequestParam(required = false) String from,
                           @RequestParam(required = false) String to) {
        return service.listJobs(currentUserService.require(authentication), page, size,
                status, search, from, to);
    }

    @GetMapping("/jobs/counts")
    public JobStatusCountsDto counts(JwtAuthenticationToken authentication) {
        return service.counts(currentUserService.require(authentication));
    }

    @GetMapping("/jobs/{id}")
    public JobDto job(JwtAuthenticationToken authentication, @PathVariable String id) {
        return service.job(currentUserService.require(authentication), id);
    }

    @PostMapping("/jobs")
    public ResponseEntity<JobDto> create(JwtAuthenticationToken authentication,
                                         @RequestHeader(value = "Idempotency-Key", required = false)
                                         String idempotencyKey,
                                         @RequestBody CreateJobRequest request) {
        return ResponseEntity.status(201).body(service.create(
                currentUserService.require(authentication), request, idempotencyKey));
    }

    @PutMapping("/jobs/{id}")
    public JobDto update(JwtAuthenticationToken authentication, @PathVariable String id,
                         @RequestBody UpdateJobRequest request) {
        return service.update(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/jobs/{id}/assign")
    public JobDto assign(JwtAuthenticationToken authentication, @PathVariable String id,
                         @RequestBody AssignTechnicianRequest request) {
        return service.assign(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/jobs/{id}/cancel")
    public JobDto cancel(JwtAuthenticationToken authentication, @PathVariable String id,
                         @RequestBody CancelJobRequest request) {
        return service.cancel(currentUserService.require(authentication), id, request);
    }

    @GetMapping("/jobs/{id}/assignments")
    public List<AssignmentDto> assignments(JwtAuthenticationToken authentication,
                                           @PathVariable String id) {
        return service.assignments(currentUserService.require(authentication), id);
    }

    // --------------------------------------------------------- review/approve

    @GetMapping("/jobs/{id}/review")
    public ReviewDto review(JwtAuthenticationToken authentication, @PathVariable String id) {
        return service.review(currentUserService.require(authentication), id);
    }

    @GetMapping("/jobs/{id}/publish-checklist")
    public PublishChecklistDto checklist(JwtAuthenticationToken authentication,
                                         @PathVariable String id) {
        return service.checklist(currentUserService.require(authentication), id);
    }

    @PostMapping("/jobs/{id}/approve")
    public JobDto approve(JwtAuthenticationToken authentication, @PathVariable String id,
                          @RequestHeader(value = "Idempotency-Key", required = false)
                          String idempotencyKey,
                          @RequestBody(required = false) ApproveJobRequest request) {
        return service.approve(currentUserService.require(authentication), id, request,
                idempotencyKey);
    }

    @PostMapping("/jobs/{id}/reject")
    public JobDto reject(JwtAuthenticationToken authentication, @PathVariable String id,
                         @RequestBody RejectJobRequest request) {
        return service.reject(currentUserService.require(authentication), id, request);
    }

    // --------------------------------------------------------------- publish

    @PostMapping("/jobs/{id}/publish")
    public PublicLinkDto publish(JwtAuthenticationToken authentication, @PathVariable String id,
                                 @RequestHeader(value = "Idempotency-Key", required = false)
                                 String idempotencyKey,
                                 @RequestBody(required = false) PublishJobRequest request) {
        return service.publish(currentUserService.require(authentication), id, request,
                idempotencyKey);
    }

    @PostMapping("/jobs/{id}/unpublish")
    public PublicLinkDto unpublish(JwtAuthenticationToken authentication, @PathVariable String id,
                                   @RequestBody ReasonRequest request) {
        return service.unpublish(currentUserService.require(authentication), id,
                request == null ? null : request.reason());
    }

    @PostMapping("/jobs/{id}/rotate-token")
    public PublicLinkDto rotateToken(JwtAuthenticationToken authentication,
                                     @PathVariable String id) {
        return service.rotateToken(currentUserService.require(authentication), id);
    }

    @PostMapping("/jobs/{id}/revoke")
    public PublicLinkDto revoke(JwtAuthenticationToken authentication, @PathVariable String id,
                                @RequestBody ReasonRequest request) {
        return service.revoke(currentUserService.require(authentication), id,
                request == null ? null : request.reason());
    }

    @GetMapping("/jobs/{id}/public-link")
    public PublicLinkDto publicLink(JwtAuthenticationToken authentication,
                                    @PathVariable String id) {
        return service.publicLink(currentUserService.require(authentication), id);
    }

    @GetMapping(value = "/jobs/{id}/qr", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> qr(JwtAuthenticationToken authentication,
                                     @PathVariable String id) {
        byte[] bytes = service.qr(currentUserService.require(authentication), id);
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_PNG)
                .cacheControl(CacheControl.noStore())
                .body(bytes);
    }

    // ------------------------------------------------------------- documents

    @GetMapping("/jobs/{id}/documents")
    public List<ReportDocumentDto> documents(JwtAuthenticationToken authentication,
                                             @PathVariable String id) {
        return service.documents(currentUserService.require(authentication), id);
    }

    @PostMapping("/jobs/{id}/documents/{type}/retry")
    public List<ReportDocumentDto> retryDocument(JwtAuthenticationToken authentication,
                                                 @PathVariable String id,
                                                 @PathVariable String type) {
        return service.retryDocument(currentUserService.require(authentication), id, type);
    }

    @GetMapping("/jobs/{id}/documents/{documentId}/content")
    public ResponseEntity<byte[]> documentContent(JwtAuthenticationToken authentication,
                                                  @PathVariable String id,
                                                  @PathVariable String documentId) {
        DocumentContent content = service.documentContent(
                currentUserService.require(authentication), id, documentId);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .cacheControl(CacheControl.noStore())
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(content.filename(), StandardCharsets.UTF_8)
                                .build().toString())
                .body(content.bytes());
    }

    // --------------------------------------------------------- notifications

    @GetMapping("/notifications")
    public List<NotificationDto> notifications(JwtAuthenticationToken authentication,
                                               @RequestParam(defaultValue = "false")
                                               boolean unreadOnly) {
        return service.notifications(currentUserService.require(authentication), unreadOnly);
    }

    @PostMapping("/notifications/{id}/read")
    public NotificationDto markRead(JwtAuthenticationToken authentication,
                                    @PathVariable String id) {
        return service.markNotificationRead(currentUserService.require(authentication), id);
    }
}
