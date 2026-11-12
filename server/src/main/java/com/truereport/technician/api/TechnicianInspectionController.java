package com.truereport.technician.api;

import com.truereport.shared.security.CurrentUserService;
import com.truereport.technician.TechnicianInspectionService;
import com.truereport.technician.api.TechnicianDtos.AssessmentDto;
import com.truereport.technician.api.TechnicianDtos.AssessmentRequest;
import com.truereport.technician.api.TechnicianDtos.ChecklistDto;
import com.truereport.technician.api.TechnicianDtos.CompleteDto;
import com.truereport.technician.api.TechnicianDtos.CompleteRequest;
import com.truereport.technician.api.TechnicianDtos.EvidenceCompleteRequest;
import com.truereport.technician.api.TechnicianDtos.EvidenceDto;
import com.truereport.technician.api.TechnicianDtos.EvidenceInitRequest;
import com.truereport.technician.api.TechnicianDtos.JobPageDto;
import com.truereport.technician.api.TechnicianDtos.JobSummaryDto;
import com.truereport.technician.api.TechnicianDtos.ReviewDto;
import com.truereport.technician.api.TechnicianDtos.SignatureDto;
import com.truereport.technician.api.TechnicianDtos.SignatureRequest;
import com.truereport.technician.api.TechnicianDtos.SummaryDto;
import com.truereport.technician.api.TechnicianDtos.SyncRequest;
import com.truereport.technician.api.TechnicianDtos.SyncResult;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController("platformTechnicianInspectionController")
@RequestMapping("/api/v1/technician")
@PreAuthorize("hasRole('TECHNICIAN')")
public class TechnicianInspectionController {

    private final TechnicianInspectionService service;
    private final CurrentUserService currentUserService;

    public TechnicianInspectionController(TechnicianInspectionService service,
                                          CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/jobs")
    public JobPageDto jobs(JwtAuthenticationToken authentication,
                           @RequestParam(defaultValue = "0") int page,
                           @RequestParam(defaultValue = "20") int size,
                           @RequestParam(required = false) String status) {
        return service.listJobs(currentUserService.require(authentication), page, size, status);
    }

    @GetMapping("/jobs/{id}")
    public JobSummaryDto job(JwtAuthenticationToken authentication, @PathVariable String id) {
        return service.job(currentUserService.require(authentication), id);
    }

    @GetMapping("/jobs/{id}/checklist")
    public ChecklistDto checklist(JwtAuthenticationToken authentication,
                                  @PathVariable String id) {
        return service.checklist(currentUserService.require(authentication), id);
    }

    @PutMapping("/jobs/{id}/items/{itemCode}")
    public AssessmentDto assess(JwtAuthenticationToken authentication, @PathVariable String id,
                                @PathVariable String itemCode,
                                @RequestBody AssessmentRequest request,
                                @RequestHeader(value = "Idempotency-Key", required = false)
                                String idempotencyKey) {
        return service.saveAssessment(currentUserService.require(authentication), id, itemCode,
                request, idempotencyKey);
    }

    @GetMapping("/jobs/{id}/summary")
    public SummaryDto summary(JwtAuthenticationToken authentication, @PathVariable String id) {
        return service.summary(currentUserService.require(authentication), id);
    }

    @GetMapping("/jobs/{id}/review")
    public ReviewDto review(JwtAuthenticationToken authentication, @PathVariable String id) {
        return service.review(currentUserService.require(authentication), id);
    }

    @PostMapping("/jobs/{id}/signature")
    public SignatureDto signature(JwtAuthenticationToken authentication, @PathVariable String id,
                                  @RequestBody SignatureRequest request) {
        return service.signature(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/jobs/{id}/complete")
    public CompleteDto complete(JwtAuthenticationToken authentication, @PathVariable String id,
                                @RequestBody(required = false) CompleteRequest request,
                                @RequestHeader(value = "Idempotency-Key", required = false)
                                String idempotencyKey) {
        return service.complete(currentUserService.require(authentication), id, request,
                idempotencyKey);
    }

    @PostMapping("/jobs/{id}/sync")
    public SyncResult sync(JwtAuthenticationToken authentication, @PathVariable String id,
                           @RequestBody SyncRequest request) {
        return service.sync(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/jobs/{id}/items/{itemCode}/evidence/init")
    public ResponseEntity<EvidenceDto> initEvidence(JwtAuthenticationToken authentication,
                                                    @PathVariable String id,
                                                    @PathVariable String itemCode,
                                                    @RequestBody EvidenceInitRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.initEvidence(
                currentUserService.require(authentication), id, itemCode, request));
    }

    @PutMapping(value = "/jobs/{id}/items/{itemCode}/evidence/{evidenceId}/content",
            consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE)
    public EvidenceDto uploadEvidence(JwtAuthenticationToken authentication,
                                      @PathVariable String id,
                                      @PathVariable String itemCode,
                                      @PathVariable String evidenceId,
                                      @RequestBody byte[] content) {
        return service.uploadEvidence(currentUserService.require(authentication), id, itemCode,
                evidenceId, content);
    }

    @PostMapping("/jobs/{id}/items/{itemCode}/evidence/{evidenceId}/complete")
    public EvidenceDto completeEvidence(JwtAuthenticationToken authentication,
                                        @PathVariable String id,
                                        @PathVariable String itemCode,
                                        @PathVariable String evidenceId,
                                        @RequestBody(required = false)
                                        EvidenceCompleteRequest request) {
        return service.completeEvidence(currentUserService.require(authentication), id, itemCode,
                evidenceId, request);
    }

    @GetMapping("/jobs/{id}/items/{itemCode}/evidence")
    public List<EvidenceDto> evidence(JwtAuthenticationToken authentication,
                                      @PathVariable String id,
                                      @PathVariable String itemCode) {
        return service.listEvidence(currentUserService.require(authentication), id, itemCode);
    }

    @GetMapping("/jobs/{id}/items/{itemCode}/evidence/{evidenceId}/content")
    public ResponseEntity<byte[]> evidenceContent(JwtAuthenticationToken authentication,
                                                  @PathVariable String id,
                                                  @PathVariable String itemCode,
                                                  @PathVariable String evidenceId) {
        TechnicianInspectionService.EvidenceContent content = service.evidenceContent(
                currentUserService.require(authentication), id, itemCode, evidenceId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mime()))
                .cacheControl(CacheControl.noStore())
                .body(content.bytes());
    }

    @DeleteMapping("/jobs/{id}/items/{itemCode}/evidence/{evidenceId}")
    public ResponseEntity<Void> deleteEvidence(JwtAuthenticationToken authentication,
                                               @PathVariable String id,
                                               @PathVariable String itemCode,
                                               @PathVariable String evidenceId) {
        service.deleteEvidence(currentUserService.require(authentication), id, itemCode,
                evidenceId);
        return ResponseEntity.noContent().build();
    }
}
