package com.truereport.templates.config;

import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import com.truereport.templates.config.PlatformTemplateDtos.CreateTemplateRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateCategoriesRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateCategoryRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemsRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateSummaryDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateVersionDto;
import com.truereport.templates.config.PlatformTemplateDtos.UpdateTemplateRequest;
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
@RequestMapping("/api/v1/platform/master/templates")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformTemplateController {

    private final PlatformTemplateService service;
    private final CurrentUserService currentUserService;

    public PlatformTemplateController(PlatformTemplateService service,
                                      CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public List<TemplateSummaryDto> list() {
        return service.list();
    }

    @GetMapping("/{id}")
    public TemplateSummaryDto detail(@PathVariable String id) {
        return service.detail(id);
    }

    @GetMapping("/{id}/versions/{versionId}")
    public TemplateVersionDto version(@PathVariable String id,
                                      @PathVariable String versionId) {
        return service.version(id, versionId);
    }

    @PostMapping
    public ResponseEntity<TemplateSummaryDto> create(JwtAuthenticationToken authentication,
                                                     @RequestBody CreateTemplateRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        return ResponseEntity.status(201).body(service.create(actor, request));
    }

    @PutMapping("/{id}")
    public TemplateSummaryDto update(JwtAuthenticationToken authentication,
                                     @PathVariable String id,
                                     @RequestBody UpdateTemplateRequest request) {
        return service.update(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/{id}/versions")
    public TemplateSummaryDto createDraft(JwtAuthenticationToken authentication,
                                          @PathVariable String id) {
        return service.createDraft(currentUserService.require(authentication), id);
    }

    @PutMapping("/{id}/versions/{versionId}/categories")
    public TemplateVersionDto replaceCategories(JwtAuthenticationToken authentication,
                                                @PathVariable String id,
                                                @PathVariable String versionId,
                                                @RequestBody TemplateCategoriesRequest request) {
        List<TemplateCategoryRequest> categories =
                request == null ? List.of() : request.categories();
        return service.replaceCategories(
                currentUserService.require(authentication), id, versionId, categories);
    }

    @PutMapping("/{id}/versions/{versionId}/items")
    public TemplateSummaryDto replaceItems(JwtAuthenticationToken authentication,
                                           @PathVariable String id,
                                           @PathVariable String versionId,
                                           @RequestBody TemplateItemsRequest request) {
        List<TemplateItemRequest> items = request == null ? List.of() : request.items();
        service.replaceItems(currentUserService.require(authentication), id, versionId, items);
        return service.detail(id);
    }

    @PostMapping("/{id}/versions/{versionId}/publish")
    public TemplateSummaryDto publish(JwtAuthenticationToken authentication,
                                      @PathVariable String id,
                                      @PathVariable String versionId) {
        return service.publish(currentUserService.require(authentication), id, versionId);
    }

    @PostMapping("/{id}/versions/{versionId}/approve")
    public TemplateSummaryDto approve(JwtAuthenticationToken authentication,
                                      @PathVariable String id,
                                      @PathVariable String versionId) {
        return service.approve(currentUserService.require(authentication), id, versionId);
    }

    @PostMapping("/{id}/versions/{versionId}/reject")
    public TemplateSummaryDto reject(JwtAuthenticationToken authentication,
                                     @PathVariable String id,
                                     @PathVariable String versionId,
                                     @RequestBody(required = false) RejectRequest request) {
        String reason = request == null ? null : request.reason();
        return service.reject(currentUserService.require(authentication), id, versionId, reason);
    }

    @PostMapping("/{id}/retire")
    public TemplateSummaryDto retire(JwtAuthenticationToken authentication,
                                     @PathVariable String id) {
        return service.retire(currentUserService.require(authentication), id);
    }

    public record RejectRequest(String reason) {
    }
}
