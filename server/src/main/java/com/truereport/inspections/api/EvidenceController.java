package com.truereport.inspections.api;

import com.truereport.inspections.EvidenceService;
import com.truereport.masterdata.MasterContentService;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
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
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/technician")
@PreAuthorize("hasRole('TECHNICIAN')")
public class EvidenceController {

    private final EvidenceService service;
    private final CurrentUserService currentUserService;

    public EvidenceController(EvidenceService service, CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/jobs/{jobId}/items/{itemId}/evidence/init")
    public ResponseEntity<EvidenceInitResponse> init(JwtAuthenticationToken authentication,
                                                     @PathVariable UUID jobId,
                                                     @PathVariable UUID itemId,
                                                     @Valid @RequestBody EvidenceInitRequest request) {
        return ResponseEntity.status(201).body(service.init(
                currentUserService.require(authentication), jobId, itemId, request));
    }

    @PutMapping(value = "/evidence/{evidenceId}/upload",
            consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE)
    public ResponseEntity<Void> upload(JwtAuthenticationToken authentication,
                                       @PathVariable UUID evidenceId,
                                       @RequestParam String token,
                                       @RequestBody byte[] bytes) {
        service.upload(currentUserService.require(authentication), evidenceId, token, bytes);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/jobs/{jobId}/items/{itemId}/evidence/{evidenceId}/complete")
    public EvidenceDto complete(JwtAuthenticationToken authentication,
                                @PathVariable UUID jobId,
                                @PathVariable UUID itemId,
                                @PathVariable UUID evidenceId,
                                @Valid @RequestBody EvidenceCompleteRequest request) {
        return service.complete(currentUserService.require(authentication), jobId, itemId,
                evidenceId, request);
    }

    @GetMapping("/jobs/{jobId}/items/{itemId}/evidence")
    public List<EvidenceDto> list(JwtAuthenticationToken authentication,
                                  @PathVariable UUID jobId,
                                  @PathVariable UUID itemId) {
        return service.list(currentUserService.require(authentication), jobId, itemId);
    }

    @DeleteMapping("/jobs/{jobId}/evidence/{evidenceId}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken authentication,
                                       @PathVariable UUID jobId,
                                       @PathVariable UUID evidenceId) {
        service.delete(currentUserService.require(authentication), jobId, evidenceId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/evidence/{evidenceId}/content")
    public ResponseEntity<byte[]> content(JwtAuthenticationToken authentication,
                                          @PathVariable UUID evidenceId) {
        EvidenceService.EvidenceContent content = service.content(
                currentUserService.require(authentication), evidenceId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mime()))
                .cacheControl(CacheControl.noStore())
                .body(content.bytes());
    }

    @GetMapping("/jobs/{jobId}/items/{itemId}/guide-image")
    public ResponseEntity<byte[]> guideImage(JwtAuthenticationToken authentication,
                                              @PathVariable UUID jobId,
                                              @PathVariable UUID itemId) {
        MasterContentService.GuideImageContent content = service.guideImage(
                currentUserService.require(authentication), jobId, itemId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mime()))
                .cacheControl(CacheControl.noStore())
                .body(content.bytes());
    }
}
