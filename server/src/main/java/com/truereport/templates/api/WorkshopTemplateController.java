package com.truereport.templates.api;

import com.truereport.shared.security.CurrentUserService;
import com.truereport.templates.WorkshopTemplateService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workshop/templates")
public class WorkshopTemplateController {

    private final WorkshopTemplateService service;
    private final CurrentUserService currentUserService;

    public WorkshopTemplateController(WorkshopTemplateService service,
                                      CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public List<TemplateSummaryDto> list(JwtAuthenticationToken authentication) {
        return service.list(currentUserService.require(authentication));
    }

    @GetMapping("/versions")
    public List<TemplateVersionOptionDto> publishedVersions(JwtAuthenticationToken authentication) {
        return service.publishedVersions(currentUserService.require(authentication));
    }

    @PostMapping
    public ResponseEntity<TemplateDetailDto> create(JwtAuthenticationToken authentication,
                                                    @Valid @RequestBody TemplateCreateRequest request) {
        return ResponseEntity.status(201).body(
                service.create(currentUserService.require(authentication), request));
    }

    @GetMapping("/{id}")
    public TemplateDetailDto detail(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.detail(currentUserService.require(authentication), id);
    }

    @PostMapping("/{id}/draft")
    public TemplateDetailDto createDraft(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.createDraft(currentUserService.require(authentication), id);
    }

    @PutMapping("/{id}/draft")
    public TemplateDetailDto saveDraft(JwtAuthenticationToken authentication,
                                       @PathVariable UUID id,
                                       @Valid @RequestBody TemplateDraftRequest request) {
        return service.saveDraft(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/{id}/publish")
    public TemplateDetailDto publish(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.publish(currentUserService.require(authentication), id);
    }

    @PostMapping("/{id}/retire")
    public TemplateDetailDto retire(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.retire(currentUserService.require(authentication), id);
    }

    @GetMapping("/{id}/versions")
    public TemplateDetailDto versions(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.detail(currentUserService.require(authentication), id);
    }

    @GetMapping("/{id}/versions/{versionId}")
    public TemplateVersionViewDto version(JwtAuthenticationToken authentication,
                                          @PathVariable UUID id,
                                          @PathVariable UUID versionId) {
        return service.versionView(currentUserService.require(authentication), id, versionId);
    }

    @GetMapping("/{id}/preview")
    public TemplateVersionViewDto preview(JwtAuthenticationToken authentication,
                                          @PathVariable UUID id,
                                          @RequestParam(required = false) UUID versionId) {
        return service.preview(currentUserService.require(authentication), id, versionId);
    }
}
