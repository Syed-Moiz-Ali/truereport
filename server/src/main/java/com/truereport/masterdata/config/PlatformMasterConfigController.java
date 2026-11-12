package com.truereport.masterdata.config;

import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRuleDto;
import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRulesRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldsRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemConfigDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemMetadataDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemMetadataRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandsRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.ReorderIdsRequest;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
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
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/platform/master")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformMasterConfigController {

    private final PlatformItemService itemService;
    private final MasterContentService masterContentService;
    private final CurrentUserService currentUserService;

    public PlatformMasterConfigController(PlatformItemService itemService,
                                          MasterContentService masterContentService,
                                          CurrentUserService currentUserService) {
        this.itemService = itemService;
        this.masterContentService = masterContentService;
        this.currentUserService = currentUserService;
    }

    @PutMapping("/categories/reorder")
    public List<CategoryDto> reorderCategories(JwtAuthenticationToken authentication,
                                               @RequestBody ReorderIdsRequest request) {
        return masterContentService.reorderCategories(
                currentUserService.require(authentication),
                request == null ? List.of() : request.orderedIds());
    }

    @PutMapping("/items/reorder")
    public void reorderItems(@RequestBody ReorderIdsRequest request) {
        itemService.reorderItems(request == null ? List.of() : request.orderedIds());
    }

    @PostMapping("/items/{id}/draft")
    public ItemDetailDto createDraft(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return masterContentService.createDraft(currentUserService.require(authentication), id);
    }

    @GetMapping("/items/{id}/metadata")
    public ItemMetadataDto metadata(@PathVariable UUID id) {
        return itemService.metadata(id);
    }

    @PutMapping("/items/{id}/metadata")
    public ItemMetadataDto updateMetadata(JwtAuthenticationToken authentication,
                                          @PathVariable UUID id,
                                          @RequestBody ItemMetadataRequest request,
                                          HttpServletRequest http) {
        CurrentUser actor = currentUserService.require(authentication);
        return itemService.updateMetadata(actor, id, request, http);
    }

    @GetMapping("/items/{id}/versions/{versionId}/config")
    public ItemConfigDto config(@PathVariable UUID id, @PathVariable UUID versionId) {
        return itemService.config(id, versionId);
    }

    @GetMapping("/items/{id}/versions/{versionId}/evidence-rules")
    public List<EvidenceRuleDto> evidenceRules(@PathVariable UUID id, @PathVariable UUID versionId) {
        return itemService.config(id, versionId).evidenceRules();
    }

    @PutMapping("/items/{id}/versions/{versionId}/evidence-rules")
    public List<EvidenceRuleDto> replaceEvidenceRules(JwtAuthenticationToken authentication,
                                                      @PathVariable UUID id,
                                                      @PathVariable UUID versionId,
                                                      @RequestBody EvidenceRulesRequest request,
                                                      HttpServletRequest http) {
        return itemService.replaceEvidenceRules(currentUserService.require(authentication), id,
                versionId, request == null ? List.of() : request.rules(), http);
    }

    @GetMapping("/items/{id}/versions/{versionId}/issue-fields")
    public List<IssueFieldDto> issueFields(@PathVariable UUID id, @PathVariable UUID versionId) {
        return itemService.config(id, versionId).issueFields();
    }

    @PutMapping("/items/{id}/versions/{versionId}/issue-fields")
    public List<IssueFieldDto> replaceIssueFields(JwtAuthenticationToken authentication,
                                                  @PathVariable UUID id,
                                                  @PathVariable UUID versionId,
                                                  @RequestBody IssueFieldsRequest request,
                                                  HttpServletRequest http) {
        return itemService.replaceIssueFields(currentUserService.require(authentication), id,
                versionId, request == null ? List.of() : request.fields(), http);
    }

    @GetMapping("/items/{id}/versions/{versionId}/measurement-bands")
    public List<MeasurementBandDto> measurementBands(@PathVariable UUID id, @PathVariable UUID versionId) {
        return itemService.config(id, versionId).measurementBands();
    }

    @PutMapping("/items/{id}/versions/{versionId}/measurement-bands")
    public List<MeasurementBandDto> replaceMeasurementBands(JwtAuthenticationToken authentication,
                                                            @PathVariable UUID id,
                                                            @PathVariable UUID versionId,
                                                            @RequestBody MeasurementBandsRequest request,
                                                            HttpServletRequest http) {
        return itemService.replaceMeasurementBands(currentUserService.require(authentication), id,
                versionId, request == null ? List.of() : request.bands(), http);
    }
}
