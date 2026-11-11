package com.truereport.masterdata;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.masterdata.api.CatalogItemRequest;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.CategoryRequest;
import com.truereport.masterdata.api.DropdownDto;
import com.truereport.masterdata.api.DropdownValueDto;
import com.truereport.masterdata.api.EquipmentDto;
import com.truereport.masterdata.api.GuideImageDto;
import com.truereport.masterdata.api.ItemCreateRequest;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.api.ItemSummaryDto;
import com.truereport.masterdata.api.ItemVersionDto;
import com.truereport.masterdata.api.PublishedItemDto;
import com.truereport.masterdata.api.ReasonDto;
import com.truereport.masterdata.api.RulesRequest;
import com.truereport.masterdata.api.TranslationRequest;
import com.truereport.masterdata.config.ItemConfigRepository;
import com.truereport.masterdata.config.PlatformContentStore;
import com.truereport.masterdata.config.PlatformContentStore.CategoryRow;
import com.truereport.masterdata.config.PlatformContentStore.GuideImageRow;
import com.truereport.masterdata.config.PlatformContentStore.ItemRow;
import com.truereport.masterdata.config.PlatformContentStore.VersionRow;
import com.truereport.masterdata.config.PlatformItemService;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class MasterContentService {

    private static final String REASON = "REASON";
    private static final String EQUIPMENT = "EQUIPMENT";
    private static final String DROPDOWN = "DROPDOWN";
    private static final String DROPDOWN_VALUE = "DROPDOWN_VALUE";
    private static final Set<String> LOCALES = Set.of("en", "ar", "ru", "zh-Hans");
    private static final Set<String> RESULT_OPTIONS = Set.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND",
            "NOT_CHECKED", "NOT_APPLICABLE", "COULD_NOT_VERIFY");
    private static final Set<String> NOTE_REQUIREMENTS = Set.of("NONE", "OPTIONAL", "REQUIRED");
    private static final Set<String> EVIDENCE_REQUIREMENTS = Set.of(
            "NONE", "OPTIONAL", "REQUIRED", "REQUIRED_MIN_N");
    private static final long MAX_GUIDE_IMAGE_BYTES = 5L * 1024 * 1024;

    private final PlatformContentStore content;
    private final LocalizedContentRepository localized;
    private final MasterReasonRepository reasons;
    private final EquipmentRepository equipment;
    private final MasterDropdownRepository dropdowns;
    private final MasterDropdownValueRepository dropdownValues;
    private final ObjectStorage objectStorage;
    private final ObjectMapper objectMapper;
    private final ItemConfigRepository itemConfig;
    private final PlatformItemService platformItemService;
    private final FieldAuditService auditService;

    public MasterContentService(PlatformContentStore content,
                                LocalizedContentRepository localized,
                                MasterReasonRepository reasons,
                                EquipmentRepository equipment,
                                MasterDropdownRepository dropdowns,
                                MasterDropdownValueRepository dropdownValues,
                                ObjectStorage objectStorage,
                                ObjectMapper objectMapper,
                                ItemConfigRepository itemConfig,
                                PlatformItemService platformItemService,
                                FieldAuditService auditService) {
        this.content = content;
        this.localized = localized;
        this.reasons = reasons;
        this.equipment = equipment;
        this.dropdowns = dropdowns;
        this.dropdownValues = dropdownValues;
        this.objectStorage = objectStorage;
        this.objectMapper = objectMapper;
        this.itemConfig = itemConfig;
        this.platformItemService = platformItemService;
        this.auditService = auditService;
    }

    // ---------------------------------------------------------- categories

    @Transactional(readOnly = true)
    public List<CategoryDto> listCategories() {
        return content.categories();
    }

    @Transactional
    public CategoryDto createCategory(CurrentUser actor, CategoryRequest request) {
        String code = resolveCode(request);
        String nameEn = resolveLabelEn(request);
        String nameAr = resolveLabelAr(request);
        requireBilingual("label", nameEn, nameAr);
        if (content.categoryByCode(code).isPresent()) {
            throw ApiException.conflict("CATEGORY_EXISTS", "Category slug already exists");
        }
        String status = request.active() == null || request.active() ? "ACTIVE" : "RETIRED";
        if (request.status() != null && request.active() == null) {
            status = request.status();
        }
        CategoryDto created = content.createCategory(code, nameEn, nameAr,
                request.weightPercentage() == null ? BigDecimal.ZERO : request.weightPercentage(),
                request.sortOrder() == null ? 0 : request.sortOrder(), status);
        audit(actor, "MASTER_CATEGORY_CREATED", "CATEGORY", created.id(), Map.of("code", code));
        return created;
    }

    @Transactional
    public CategoryDto updateCategory(CurrentUser actor, UUID id, CategoryRequest request) {
        content.category(id.toString()).orElseThrow(ApiException::notFound);
        String status = request.status();
        if (request.active() != null) {
            status = request.active() ? "ACTIVE" : "RETIRED";
        }
        if (status != null && !Set.of("ACTIVE", "RETIRED").contains(status)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "INVALID_STATUS",
                    "error.status.invalid", "Invalid category status");
        }
        CategoryDto updated = content.updateCategory(id.toString(), resolveLabelEn(request),
                resolveLabelAr(request), request.weightPercentage(), request.sortOrder(), status);
        audit(actor, "MASTER_CATEGORY_UPDATED", "CATEGORY", id,
                Map.of("code", updated.code(), "status", updated.status()));
        return updated;
    }

    @Transactional
    public CategoryDto retireCategory(CurrentUser actor, UUID id) {
        CategoryRow category = content.category(id.toString()).orElseThrow(ApiException::notFound);
        content.retireCategory(id.toString());
        audit(actor, "MASTER_CATEGORY_RETIRED", "CATEGORY", id, Map.of("code", category.code()));
        return content.categoryDto(id.toString());
    }

    @Transactional(readOnly = true)
    public List<CategoryDto> listActiveCategories() {
        return content.activeCategories();
    }

    // --------------------------------------------------------------- items

    @Transactional(readOnly = true)
    public List<ItemSummaryDto> listItems(String search, UUID categoryId, String status) {
        return content.items(search, categoryId, status);
    }

    @Transactional(readOnly = true)
    public List<PublishedItemDto> listPublishedItems(String search, UUID categoryId) {
        return content.publishedItems(search, categoryId);
    }

    @Transactional(readOnly = true)
    public PublishedItemDto publishedItem(UUID versionId) {
        return content.publishedItem(versionId);
    }

    @Transactional(readOnly = true)
    public ItemDetailDto itemDetail(UUID itemId) {
        return content.itemDetail(itemId);
    }

    @Transactional(readOnly = true)
    public List<ItemVersionDto> listVersions(UUID itemId) {
        return content.listVersions(itemId);
    }

    @Transactional
    public ItemDetailDto createItem(CurrentUser actor, ItemCreateRequest request) {
        CategoryRow category = content.category(request.categoryId().toString())
                .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "CATEGORY_NOT_FOUND", "error.category.notFound", "Category not found"));
        if (!"ACTIVE".equals(category.status())) {
            throw ApiException.conflict("CATEGORY_RETIRED", "Category is retired");
        }
        if (content.itemByCode(request.stableCode().trim()).isPresent()) {
            throw ApiException.conflict("ITEM_CODE_EXISTS", "Stable code already exists");
        }
        validateRules(new RulesRequest(request.resultOptions(), request.severityPolicy(),
                request.applicability(), request.reasonCodes(), request.noteRequirement(),
                request.evidenceRequirement(), request.minPhotos(), request.equipmentIds(),
                request.guideImageId()));
        ItemDetailDto detail = content.createItem(request.categoryId(),
                request.stableCode().trim(), request.sampleData(),
                request.sortOrder() == null ? 0 : request.sortOrder(),
                request.labelEn(), request.labelAr(), request.instructionEn(), request.instructionAr(),
                request.measurementUnit(), request.sensorTool(), request.standardSpecEn(),
                request.standardSpecAr(), Boolean.TRUE.equals(request.safetyCritical()),
                Boolean.TRUE.equals(request.multiPoint()), request.maxTyreAgeYears(),
                Boolean.TRUE.equals(request.allowFreeTextNote()), request.resultOptions(),
                request.severityPolicy(), request.applicability(), request.reasonCodes(),
                request.noteRequirement(), request.evidenceRequirement(),
                request.minPhotos() == null ? 0 : request.minPhotos(),
                request.equipmentIds(), request.guideImageId());
        audit(actor, "MASTER_ITEM_CREATED", "MASTER_ITEM", detail.item().id(),
                Map.of("stableCode", detail.item().stableCode(),
                        "sampleData", Boolean.toString(detail.item().sampleData())));
        return detail;
    }

    @Transactional
    public ItemDetailDto createDraft(CurrentUser actor, UUID itemId) {
        ItemDetailDto detail = content.createDraft(itemId);
        VersionRow draft = content.latestVersion(itemId.toString()).orElseThrow();
        itemConfig.copyVersionConfig(
                content.versions(itemId.toString()).stream()
                        .filter(version -> !version.id().equals(draft.id()))
                        .findFirst().map(VersionRow::id).orElse(draft.id()),
                draft.id());
        audit(actor, "MASTER_ITEM_DRAFT_CREATED", "MASTER_ITEM", itemId,
                Map.of("version", Integer.toString(draft.versionNo())));
        return detail;
    }

    @Transactional
    public ItemVersionDto updateTranslation(CurrentUser actor, UUID itemId, UUID versionId,
                                            String locale, TranslationRequest request) {
        content.requireDraft(itemId, versionId);
        if (!LOCALES.contains(locale)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LOCALE_INVALID",
                    "error.locale.invalid", "Unsupported locale");
        }
        content.updateTranslation(itemId, versionId, locale, request.label(), request.instruction());
        audit(actor, "MASTER_TRANSLATION_UPDATED", "MASTER_ITEM_VERSION", versionId,
                Map.of("locale", locale));
        return content.itemVersionDto(versionId.toString());
    }

    @Transactional
    public ItemVersionDto updateRules(CurrentUser actor, UUID itemId, UUID versionId,
                                      RulesRequest request) {
        validateRules(request);
        content.updateRules(itemId, versionId, request.resultOptions(), request.severityPolicy(),
                request.applicability(), request.reasonCodes(), request.noteRequirement(),
                request.evidenceRequirement(), request.minPhotos() == null ? 0 : request.minPhotos(),
                request.equipmentIds(), request.guideImageId());
        audit(actor, "MASTER_ITEM_RULES_UPDATED", "MASTER_ITEM_VERSION", versionId, Map.of());
        return content.itemVersionDto(versionId.toString());
    }

    @Transactional
    public ItemVersionDto publish(CurrentUser actor, UUID itemId, UUID versionId) {
        VersionRow version = content.requireDraft(itemId, versionId);
        requirePublishedTranslation(version, "en");
        requirePublishedTranslation(version, "ar");
        if (version.resultOptionsJson() == null || version.resultOptionsJson().isBlank()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RESULT_OPTIONS_REQUIRED",
                    "error.resultOptions.required", "At least one result option is required");
        }
        platformItemService.assertPublishable(itemId, versionId);
        content.publish(itemId, versionId, actor.userId());
        audit(actor, "MASTER_ITEM_PUBLISHED", "MASTER_ITEM", itemId,
                Map.of("version", Integer.toString(version.versionNo())));
        return content.itemVersionDto(versionId.toString());
    }

    @Transactional
    public ItemSummaryDto retireItem(CurrentUser actor, UUID itemId) {
        ItemRow item = content.item(itemId.toString()).orElseThrow(ApiException::notFound);
        ItemSummaryDto retired = content.retireItem(itemId);
        audit(actor, "MASTER_ITEM_RETIRED", "MASTER_ITEM", itemId,
                Map.of("stableCode", item.stableCode()));
        return retired;
    }

    // ---------------------------------------------------------- catalogues

    @Transactional(readOnly = true)
    public List<ReasonDto> listReasons() {
        return reasons.findAllByOrderBySortOrderAsc().stream().map(reason -> new ReasonDto(
                reason.getId(), reason.getCode(), reason.getStatus(), reason.getSortOrder(),
                text(REASON, reason.getId(), "en", "label"),
                text(REASON, reason.getId(), "ar", "label"))).toList();
    }

    @Transactional
    public ReasonDto createReason(CurrentUser actor, CatalogItemRequest request) {
        if (reasons.findByCode(request.code()).isPresent()) {
            throw ApiException.conflict("REASON_EXISTS", "Reason code already exists");
        }
        MasterReason reason = reasons.save(new MasterReason(request.code().trim(),
                request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(REASON, reason.getId(), "en", "label", request.labelEn());
        putText(REASON, reason.getId(), "ar", "label", request.labelAr());
        audit(actor, "MASTER_REASON_CREATED", "REASON", reason.getId(),
                Map.of("code", reason.getCode()));
        return new ReasonDto(reason.getId(), reason.getCode(), reason.getStatus(),
                reason.getSortOrder(), request.labelEn(), request.labelAr());
    }

    @Transactional(readOnly = true)
    public List<EquipmentDto> listEquipment() {
        return equipment.findAllByOrderBySortOrderAsc().stream().map(this::equipmentDto).toList();
    }

    @Transactional(readOnly = true)
    public List<EquipmentDto> listEquipmentByIds(Collection<UUID> ids) {
        if (ids == null || ids.isEmpty()) {
            return List.of();
        }
        return equipment.findAllById(ids).stream()
                .sorted(Comparator.comparingInt(Equipment::getSortOrder))
                .map(this::equipmentDto)
                .toList();
    }

    @Transactional
    public EquipmentDto createEquipment(CurrentUser actor, CatalogItemRequest request) {
        Equipment item = equipment.save(new Equipment(request.code().trim(),
                request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(EQUIPMENT, item.getId(), "en", "label", request.labelEn());
        putText(EQUIPMENT, item.getId(), "ar", "label", request.labelAr());
        audit(actor, "MASTER_EQUIPMENT_CREATED", "EQUIPMENT", item.getId(),
                Map.of("code", item.getCode()));
        return new EquipmentDto(item.getId(), item.getCode(), item.getStatus(),
                item.getSortOrder(), request.labelEn(), request.labelAr());
    }

    @Transactional(readOnly = true)
    public List<DropdownDto> listDropdowns() {
        return dropdowns.findAllByOrderBySortOrderAsc().stream().map(dropdown -> new DropdownDto(
                dropdown.getId(), dropdown.getCode(), dropdown.getStatus(), dropdown.getSortOrder(),
                text(DROPDOWN, dropdown.getId(), "en", "label"),
                text(DROPDOWN, dropdown.getId(), "ar", "label"),
                dropdownValues.findByDropdownIdOrderBySortOrderAsc(dropdown.getId()).stream()
                        .map(value -> new DropdownValueDto(value.getId(), value.getCode(),
                                value.getStatus(), value.getSortOrder(),
                                text(DROPDOWN_VALUE, value.getId(), "en", "label"),
                                text(DROPDOWN_VALUE, value.getId(), "ar", "label")))
                        .toList())).toList();
    }

    @Transactional
    public DropdownDto createDropdown(CurrentUser actor, CatalogItemRequest request) {
        MasterDropdown dropdown = dropdowns.save(new MasterDropdown(request.code().trim(),
                request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(DROPDOWN, dropdown.getId(), "en", "label", request.labelEn());
        putText(DROPDOWN, dropdown.getId(), "ar", "label", request.labelAr());
        audit(actor, "MASTER_DROPDOWN_CREATED", "DROPDOWN", dropdown.getId(),
                Map.of("code", dropdown.getCode()));
        return new DropdownDto(dropdown.getId(), dropdown.getCode(), dropdown.getStatus(),
                dropdown.getSortOrder(), request.labelEn(), request.labelAr(), List.of());
    }

    @Transactional
    public DropdownValueDto addDropdownValue(CurrentUser actor, UUID dropdownId,
                                             CatalogItemRequest request) {
        MasterDropdown dropdown = dropdowns.findById(dropdownId).orElseThrow(ApiException::notFound);
        MasterDropdownValue value = dropdownValues.save(new MasterDropdownValue(dropdown.getId(),
                request.code().trim(), request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(DROPDOWN_VALUE, value.getId(), "en", "label", request.labelEn());
        putText(DROPDOWN_VALUE, value.getId(), "ar", "label", request.labelAr());
        audit(actor, "MASTER_DROPDOWN_VALUE_CREATED", "DROPDOWN_VALUE", value.getId(),
                Map.of("dropdownCode", dropdown.getCode(), "code", value.getCode()));
        return new DropdownValueDto(value.getId(), value.getCode(), value.getStatus(),
                value.getSortOrder(), request.labelEn(), request.labelAr());
    }

    // -------------------------------------------------------- guide images

    @Transactional(readOnly = true)
    public List<GuideImageDto> listGuideImages() {
        return content.guideImages();
    }

    @Transactional
    public GuideImageDto uploadGuideImage(CurrentUser actor, MultipartFile file, String altEn,
                                          String altAr, String licenceNote) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "FILE_REQUIRED",
                    "error.file.required", "A guide image file is required");
        }
        if (file.getSize() > MAX_GUIDE_IMAGE_BYTES) {
            throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "FILE_TOO_LARGE",
                    "error.file.tooLarge", "Guide image is too large");
        }
        String mime = file.getContentType() == null ? "" : file.getContentType().toLowerCase();
        if (!Set.of("image/png", "image/jpeg", "image/webp").contains(mime)) {
            throw new ApiException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "FILE_TYPE_INVALID",
                    "error.file.type", "Only PNG, JPEG and WebP guide images are allowed");
        }
        try {
            byte[] bytes = file.getBytes();
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(bytes);
            String key = "guide/" + UuidV7.generate() + "/" + safeFilename(file.getOriginalFilename());
            objectStorage.put(key, bytes, mime);
            GuideImageRow image = content.createGuideImage(key, hash, mime, bytes.length,
                    licenceNote, altEn == null ? "" : altEn, altAr == null ? "" : altAr,
                    actor.userId());
            audit(actor, "MASTER_GUIDE_IMAGE_UPLOADED", "GUIDE_IMAGE",
                    UUID.fromString(image.id()), Map.of("mime", mime,
                            "bytes", Long.toString(image.bytes())));
            return content.toGuideDto(image);
        } catch (IOException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Unable to store guide image", e);
        }
    }

    @Transactional
    public GuideImageDto retireGuideImage(CurrentUser actor, UUID id) {
        GuideImageRow image = content.guideImage(id.toString()).orElseThrow(ApiException::notFound);
        content.retireGuideImage(id.toString());
        audit(actor, "MASTER_GUIDE_IMAGE_RETIRED", "GUIDE_IMAGE", id, Map.of());
        return content.toGuideDto(new GuideImageRow(image.id(), image.storageKey(),
                image.contentHash(), image.mime(), image.bytes(), "RETIRED", image.licenceNote(),
                image.altEn(), image.altAr(), image.uploadedBy(), image.createdAt()));
    }

    @Transactional(readOnly = true)
    public GuideImageContent guideImageContent(UUID id) {
        GuideImageRow image = content.guideImage(id.toString()).orElseThrow(ApiException::notFound);
        return new GuideImageContent(image.mime(), objectStorage.get(image.storageKey()));
    }

    // ------------------------------------------------------------ helpers

    private void validateRules(RulesRequest request) {
        List<String> resultOptions = request.resultOptions() == null ? List.of() : request.resultOptions();
        for (String option : resultOptions) {
            if (!RESULT_OPTIONS.contains(option)) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RESULT_OPTION_INVALID",
                        "error.resultOption.invalid", "Invalid result option");
            }
        }
        String note = request.noteRequirement() == null ? "OPTIONAL" : request.noteRequirement();
        String evidence = request.evidenceRequirement() == null ? "NONE" : request.evidenceRequirement();
        if (!NOTE_REQUIREMENTS.contains(note) || !EVIDENCE_REQUIREMENTS.contains(evidence)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RULE_INVALID",
                    "error.rule.invalid", "Invalid note or evidence requirement");
        }
        for (String code : request.reasonCodes() == null ? List.<String>of() : request.reasonCodes()) {
            if (reasons.findByCode(code).isEmpty()) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "REASON_NOT_FOUND",
                        "error.reason.notFound", "Unknown reason code");
            }
        }
        for (UUID equipmentId : request.equipmentIds() == null
                ? List.<UUID>of() : request.equipmentIds()) {
            if (!equipment.existsById(equipmentId)) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "EQUIPMENT_NOT_FOUND",
                        "error.equipment.notFound", "Unknown equipment");
            }
        }
        if (request.guideImageId() != null
                && content.guideImage(request.guideImageId().toString()).isEmpty()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "GUIDE_IMAGE_NOT_FOUND",
                    "error.guideImage.notFound", "Unknown guide image");
        }
    }

    private void requirePublishedTranslation(VersionRow version, String locale) {
        boolean hasLabel = "ar".equals(locale)
                ? notBlank(version.labelAr()) : notBlank(version.labelEn());
        boolean hasInstruction = "ar".equals(locale)
                ? notBlank(version.instructionAr()) : notBlank(version.instructionEn());
        if (!hasLabel || !hasInstruction) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TRANSLATION_REQUIRED",
                    "error.translation.required",
                    "English and Arabic label and instruction are required");
        }
    }

    private static boolean notBlank(String value) {
        return value != null && !value.isBlank();
    }

    private String resolveCode(CategoryRequest request) {
        String value = notBlank(request.code()) ? request.code() : request.slug();
        if (!notBlank(value)) {
            throw ApiException.validation("CATEGORY_CODE_REQUIRED", "Category code is required",
                    List.of(com.truereport.shared.error.FieldIssue.of(
                            "code", "REQUIRED", "error.field.invalid")));
        }
        return value.trim();
    }

    private String resolveLabelEn(CategoryRequest request) {
        String value = notBlank(request.nameEn()) ? request.nameEn() : request.labelEn();
        return value == null ? "" : value.trim();
    }

    private String resolveLabelAr(CategoryRequest request) {
        String value = notBlank(request.nameAr()) ? request.nameAr() : request.labelAr();
        return value == null ? "" : value.trim();
    }

    private void requireBilingual(String field, String en, String ar) {
        List<com.truereport.shared.error.FieldIssue> issues = new java.util.ArrayList<>();
        if (!notBlank(en)) {
            issues.add(com.truereport.shared.error.FieldIssue.of(
                    field + "En", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (!notBlank(ar)) {
            issues.add(com.truereport.shared.error.FieldIssue.of(
                    field + "Ar", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "English and Arabic are required", issues);
        }
    }

    private void putText(String entityType, UUID entityId, String locale, String field, String value) {
        String safe = value == null ? "" : value;
        LocalizedContent existing = localized
                .findByEntityTypeAndEntityIdAndLocaleAndFieldKey(entityType, entityId, locale, field)
                .orElse(null);
        if (existing == null) {
            localized.save(new LocalizedContent(entityType, entityId, locale, field, safe));
        } else {
            existing.setTextValue(safe);
            localized.save(existing);
        }
    }

    private String text(String entityType, UUID entityId, String locale, String field) {
        return localized
                .findByEntityTypeAndEntityIdAndLocaleAndFieldKey(entityType, entityId, locale, field)
                .map(LocalizedContent::getTextValue).orElse("");
    }

    private EquipmentDto equipmentDto(Equipment item) {
        return new EquipmentDto(item.getId(), item.getCode(), item.getStatus(), item.getSortOrder(),
                text(EQUIPMENT, item.getId(), "en", "label"),
                text(EQUIPMENT, item.getId(), "ar", "label"));
    }

    private String safeFilename(String filename) {
        String name = filename == null ? "image" : filename.replaceAll("[^A-Za-z0-9._-]", "_");
        return name.isBlank() ? "image" : name;
    }

    private void audit(CurrentUser actor, String action, String entityType, UUID entityId,
                       Map<String, String> metadata) {
        auditService.record(actor, action, entityType,
                entityId == null ? null : entityId.toString(), null, metadata, null, null);
    }

    public record GuideImageContent(String mime, byte[] bytes) {
    }
}
