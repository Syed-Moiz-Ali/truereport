package com.truereport.masterdata.api;

import com.truereport.masterdata.MasterContentService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/platform/master")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class MasterContentController {

    private final MasterContentService service;
    private final CurrentUserService currentUserService;

    public MasterContentController(MasterContentService service, CurrentUserService currentUserService) {
        this.service = service;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/categories")
    public List<CategoryDto> categories() {
        return service.listCategories();
    }

    @PostMapping("/categories")
    public ResponseEntity<CategoryDto> createCategory(JwtAuthenticationToken authentication,
                                                      @Valid @RequestBody CategoryRequest request) {
        CurrentUser actor = currentUserService.require(authentication);
        return ResponseEntity.status(201).body(service.createCategory(actor, request));
    }

    @PutMapping("/categories/{id}")
    public CategoryDto updateCategory(JwtAuthenticationToken authentication,
                                      @PathVariable UUID id,
                                      @Valid @RequestBody CategoryRequest request) {
        return service.updateCategory(currentUserService.require(authentication), id, request);
    }

    @PostMapping("/categories/{id}/retire")
    public CategoryDto retireCategory(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.retireCategory(currentUserService.require(authentication), id);
    }

    @GetMapping("/items")
    public List<ItemSummaryDto> items(@RequestParam(required = false) String search,
                                      @RequestParam(required = false) UUID categoryId,
                                      @RequestParam(required = false) String status) {
        return service.listItems(search, categoryId, status);
    }

    @GetMapping("/items/{id}")
    public ItemDetailDto item(@PathVariable UUID id) {
        return service.itemDetail(id);
    }

    @PostMapping("/items")
    public ResponseEntity<ItemDetailDto> createItem(JwtAuthenticationToken authentication,
                                                    @Valid @RequestBody ItemCreateRequest request) {
        return ResponseEntity.status(201).body(
                service.createItem(currentUserService.require(authentication), request));
    }

    @GetMapping("/items/{id}/versions")
    public List<ItemVersionDto> versions(@PathVariable UUID id) {
        return service.listVersions(id);
    }

    @PostMapping("/items/{id}/versions")
    public ItemDetailDto createDraft(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.createDraft(currentUserService.require(authentication), id);
    }

    @PutMapping("/items/{id}/versions/{versionId}/translations/{locale}")
    public ItemVersionDto updateTranslation(JwtAuthenticationToken authentication,
                                            @PathVariable UUID id,
                                            @PathVariable UUID versionId,
                                            @PathVariable String locale,
                                            @Valid @RequestBody TranslationRequest request) {
        return service.updateTranslation(currentUserService.require(authentication),
                id, versionId, locale, request);
    }

    @PutMapping("/items/{id}/versions/{versionId}/rules")
    public ItemVersionDto updateRules(JwtAuthenticationToken authentication,
                                      @PathVariable UUID id,
                                      @PathVariable UUID versionId,
                                      @Valid @RequestBody RulesRequest request) {
        return service.updateRules(currentUserService.require(authentication), id, versionId, request);
    }

    @PostMapping("/items/{id}/versions/{versionId}/publish")
    public ItemVersionDto publish(JwtAuthenticationToken authentication,
                                  @PathVariable UUID id,
                                  @PathVariable UUID versionId) {
        return service.publish(currentUserService.require(authentication), id, versionId);
    }

    @PostMapping("/items/{id}/retire")
    public ItemSummaryDto retire(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.retireItem(currentUserService.require(authentication), id);
    }

    @GetMapping("/reasons")
    public List<ReasonDto> reasons() {
        return service.listReasons();
    }

    @PostMapping("/reasons")
    public ResponseEntity<ReasonDto> createReason(JwtAuthenticationToken authentication,
                                                  @Valid @RequestBody CatalogItemRequest request) {
        return ResponseEntity.status(201).body(
                service.createReason(currentUserService.require(authentication), request));
    }

    @GetMapping("/equipment")
    public List<EquipmentDto> equipment() {
        return service.listEquipment();
    }

    @PostMapping("/equipment")
    public ResponseEntity<EquipmentDto> createEquipment(JwtAuthenticationToken authentication,
                                                        @Valid @RequestBody CatalogItemRequest request) {
        return ResponseEntity.status(201).body(
                service.createEquipment(currentUserService.require(authentication), request));
    }

    @GetMapping("/dropdowns")
    public List<DropdownDto> dropdowns() {
        return service.listDropdowns();
    }

    @PostMapping("/dropdowns")
    public ResponseEntity<DropdownDto> createDropdown(JwtAuthenticationToken authentication,
                                                      @Valid @RequestBody CatalogItemRequest request) {
        return ResponseEntity.status(201).body(
                service.createDropdown(currentUserService.require(authentication), request));
    }

    @PostMapping("/dropdowns/{id}/values")
    public ResponseEntity<DropdownValueDto> addDropdownValue(JwtAuthenticationToken authentication,
                                                             @PathVariable UUID id,
                                                             @Valid @RequestBody CatalogItemRequest request) {
        return ResponseEntity.status(201).body(
                service.addDropdownValue(currentUserService.require(authentication), id, request));
    }

    @GetMapping("/guide-images")
    public List<GuideImageDto> guideImages() {
        return service.listGuideImages();
    }

    @PostMapping("/guide-images")
    public ResponseEntity<GuideImageDto> uploadGuideImage(JwtAuthenticationToken authentication,
                                                          @RequestParam("file") MultipartFile file,
                                                          @RequestParam(required = false) String altEn,
                                                          @RequestParam(required = false) String altAr,
                                                          @RequestParam(required = false) String licenceNote) {
        return ResponseEntity.status(201).body(service.uploadGuideImage(
                currentUserService.require(authentication), file, altEn, altAr, licenceNote));
    }

    @GetMapping("/guide-images/{id}/content")
    public ResponseEntity<byte[]> guideImageContent(@PathVariable UUID id) {
        MasterContentService.GuideImageContent content = service.guideImageContent(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.mime()))
                .cacheControl(CacheControl.noStore())
                .body(content.bytes());
    }

    @PostMapping("/guide-images/{id}/retire")
    public GuideImageDto retireGuideImage(JwtAuthenticationToken authentication, @PathVariable UUID id) {
        return service.retireGuideImage(currentUserService.require(authentication), id);
    }
}
