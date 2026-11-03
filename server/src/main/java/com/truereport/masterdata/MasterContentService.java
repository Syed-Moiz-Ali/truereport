package com.truereport.masterdata;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
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
import com.truereport.masterdata.api.ReasonDto;
import com.truereport.masterdata.api.RulesRequest;
import com.truereport.masterdata.api.TranslationDto;
import com.truereport.masterdata.api.TranslationRequest;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MasterContentService {

    private static final String CATEGORY = "CATEGORY";
    private static final String ITEM_VERSION = "ITEM_VERSION";
    private static final String REASON = "REASON";
    private static final String EQUIPMENT = "EQUIPMENT";
    private static final String DROPDOWN = "DROPDOWN";
    private static final String DROPDOWN_VALUE = "DROPDOWN_VALUE";
    private static final String GUIDE_IMAGE = "GUIDE_IMAGE";
    private static final Set<String> LOCALES = Set.of("en", "ar", "ru", "zh-Hans");
    private static final Set<String> RESULT_OPTIONS = Set.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND",
            "NOT_CHECKED", "NOT_APPLICABLE", "COULD_NOT_VERIFY");
    private static final Set<String> NOTE_REQUIREMENTS = Set.of("NONE", "OPTIONAL", "REQUIRED");
    private static final Set<String> EVIDENCE_REQUIREMENTS = Set.of("NONE", "OPTIONAL", "REQUIRED", "REQUIRED_MIN_N");
    private static final long MAX_GUIDE_IMAGE_BYTES = 5L * 1024 * 1024;

    private final MasterCategoryRepository categories;
    private final MasterInspectionItemRepository items;
    private final MasterItemVersionRepository versions;
    private final LocalizedContentRepository localized;
    private final MasterReasonRepository reasons;
    private final EquipmentRepository equipment;
    private final MasterDropdownRepository dropdowns;
    private final MasterDropdownValueRepository dropdownValues;
    private final GuideImageRepository guideImages;
    private final ObjectStorage objectStorage;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    public MasterContentService(MasterCategoryRepository categories,
                                MasterInspectionItemRepository items,
                                MasterItemVersionRepository versions,
                                LocalizedContentRepository localized,
                                MasterReasonRepository reasons,
                                EquipmentRepository equipment,
                                MasterDropdownRepository dropdowns,
                                MasterDropdownValueRepository dropdownValues,
                                GuideImageRepository guideImages,
                                ObjectStorage objectStorage,
                                AuditService auditService,
                                ObjectMapper objectMapper) {
        this.categories = categories;
        this.items = items;
        this.versions = versions;
        this.localized = localized;
        this.reasons = reasons;
        this.equipment = equipment;
        this.dropdowns = dropdowns;
        this.dropdownValues = dropdownValues;
        this.guideImages = guideImages;
        this.objectStorage = objectStorage;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<CategoryDto> listCategories() {
        return categories.findAllByOrderBySortOrderAsc().stream().map(this::categoryDto).toList();
    }

    @Transactional
    public CategoryDto createCategory(CurrentUser actor, CategoryRequest request) {
        if (categories.findBySlug(request.slug()).isPresent()) {
            throw ApiException.conflict("CATEGORY_EXISTS", "Category slug already exists");
        }
        MasterCategory category = categories.save(new MasterCategory(
                request.slug().trim(), request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(CATEGORY, category.getId(), "en", "label", request.labelEn());
        putText(CATEGORY, category.getId(), "ar", "label", request.labelAr());
        audit(actor, null, "MASTER_CATEGORY_CREATED", "CATEGORY", category.getId(), null,
                Map.of("slug", category.getSlug()));
        return categoryDto(category);
    }

    @Transactional
    public CategoryDto updateCategory(CurrentUser actor, UUID id, CategoryRequest request) {
        MasterCategory category = categories.findById(id).orElseThrow(ApiException::notFound);
        category.setSortOrder(request.sortOrder() == null ? category.getSortOrder() : request.sortOrder());
        if (request.status() != null) {
            if (!Set.of("ACTIVE", "RETIRED").contains(request.status())) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "INVALID_STATUS",
                        "error.status.invalid", "Invalid category status");
            }
            category.setStatus(request.status());
        }
        categories.save(category);
        putText(CATEGORY, category.getId(), "en", "label", request.labelEn());
        putText(CATEGORY, category.getId(), "ar", "label", request.labelAr());
        audit(actor, null, "MASTER_CATEGORY_UPDATED", "CATEGORY", category.getId(), null,
                Map.of("slug", category.getSlug(), "status", category.getStatus()));
        return categoryDto(category);
    }

    @Transactional
    public CategoryDto retireCategory(CurrentUser actor, UUID id) {
        MasterCategory category = categories.findById(id).orElseThrow(ApiException::notFound);
        category.setStatus("RETIRED");
        categories.save(category);
        audit(actor, null, "MASTER_CATEGORY_RETIRED", "CATEGORY", category.getId(), null,
                Map.of("slug", category.getSlug()));
        return categoryDto(category);
    }

    @Transactional(readOnly = true)
    public List<ItemSummaryDto> listItems(String search, UUID categoryId, String status) {
        String query = search == null ? "" : search.trim().toLowerCase();
        return items.findAllByOrderByStableCodeAsc().stream()
                .filter(item -> categoryId == null || item.getCategoryId().equals(categoryId))
                .filter(item -> status == null || status.isBlank() || item.getStatus().equals(status))
                .map(this::summary)
                .filter(item -> query.isEmpty()
                        || contains(item.stableCode(), query)
                        || contains(item.labelEn(), query)
                        || contains(item.labelAr(), query))
                .toList();
    }

    @Transactional(readOnly = true)
    public ItemDetailDto itemDetail(UUID itemId) {
        MasterInspectionItem item = requireItem(itemId);
        List<ItemVersionDto> versionDtos = versions.findByItemIdOrderByVersionNoDesc(itemId).stream()
                .map(this::versionDto).toList();
        return new ItemDetailDto(summary(item), versionDtos);
    }

    @Transactional(readOnly = true)
    public List<ItemVersionDto> listVersions(UUID itemId) {
        requireItem(itemId);
        return versions.findByItemIdOrderByVersionNoDesc(itemId).stream().map(this::versionDto).toList();
    }

    @Transactional
    public ItemDetailDto createItem(CurrentUser actor, ItemCreateRequest request) {
        MasterCategory category = categories.findById(request.categoryId())
                .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "CATEGORY_NOT_FOUND", "error.category.notFound", "Category not found"));
        if (!category.getStatus().equals("ACTIVE")) {
            throw ApiException.conflict("CATEGORY_RETIRED", "Category is retired");
        }
        if (items.findByStableCode(request.stableCode().trim()).isPresent()) {
            throw ApiException.conflict("ITEM_CODE_EXISTS", "Stable code already exists");
        }
        MasterInspectionItem item = items.save(new MasterInspectionItem(
                request.stableCode().trim(), category.getId(), request.sampleData()));
        MasterItemVersion version = versions.save(new MasterItemVersion(item.getId(), 1));
        putText(ITEM_VERSION, version.getId(), "en", "label", request.labelEn());
        putText(ITEM_VERSION, version.getId(), "en", "instruction", request.instructionEn());
        putText(ITEM_VERSION, version.getId(), "ar", "label", request.labelAr());
        putText(ITEM_VERSION, version.getId(), "ar", "instruction", request.instructionAr());
        applyRules(version, new RulesRequest(request.resultOptions(), request.severityPolicy(),
                request.applicability(), request.reasonCodes(), request.noteRequirement(),
                request.evidenceRequirement(), request.minPhotos(), request.equipmentIds(),
                request.guideImageId()));
        versions.save(version);
        audit(actor, category.getId(), "MASTER_ITEM_CREATED", "MASTER_ITEM", item.getId(), null,
                Map.of("stableCode", item.getStableCode(), "sampleData", Boolean.toString(item.isSampleData())));
        return itemDetail(item.getId());
    }

    @Transactional
    public ItemDetailDto createDraft(CurrentUser actor, UUID itemId) {
        MasterInspectionItem item = requireItem(itemId);
        if (item.getStatus().equals("RETIRED")) {
            throw ApiException.conflict("ITEM_RETIRED", "Retired items cannot be edited");
        }
        MasterItemVersion latest = versions.findFirstByItemIdOrderByVersionNoDesc(itemId)
                .orElseThrow(() -> ApiException.conflict("NO_VERSION", "Item has no version"));
        if (latest.getStatus().equals("DRAFT")) {
            throw ApiException.conflict("DRAFT_EXISTS", "A draft already exists; edit it before creating another");
        }
        MasterItemVersion draft = versions.save(new MasterItemVersion(itemId, latest.getVersionNo() + 1));
        copyTranslations(latest.getId(), draft.getId());
        copyRules(latest, draft);
        versions.save(draft);
        audit(actor, item.getCategoryId(), "MASTER_ITEM_DRAFT_CREATED", "MASTER_ITEM", itemId, null,
                Map.of("version", Integer.toString(draft.getVersionNo())));
        return itemDetail(itemId);
    }

    @Transactional
    public ItemVersionDto updateTranslation(CurrentUser actor, UUID itemId, UUID versionId,
                                            String locale, TranslationRequest request) {
        MasterItemVersion version = requireDraft(itemId, versionId);
        if (!LOCALES.contains(locale)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LOCALE_INVALID",
                    "error.locale.invalid", "Unsupported locale");
        }
        putText(ITEM_VERSION, version.getId(), locale, "label", request.label());
        putText(ITEM_VERSION, version.getId(), locale, "instruction", request.instruction());
        audit(actor, requireItem(itemId).getCategoryId(), "MASTER_TRANSLATION_UPDATED",
                "MASTER_ITEM_VERSION", version.getId(), null, Map.of("locale", locale));
        return versionDto(version);
    }

    @Transactional
    public ItemVersionDto updateRules(CurrentUser actor, UUID itemId, UUID versionId, RulesRequest request) {
        MasterItemVersion version = requireDraft(itemId, versionId);
        applyRules(version, request);
        versions.save(version);
        audit(actor, requireItem(itemId).getCategoryId(), "MASTER_ITEM_RULES_UPDATED",
                "MASTER_ITEM_VERSION", version.getId(), null, Map.of());
        return versionDto(version);
    }

    @Transactional
    public ItemVersionDto publish(CurrentUser actor, UUID itemId, UUID versionId) {
        MasterInspectionItem item = requireItem(itemId);
        MasterItemVersion version = requireDraft(itemId, versionId);
        requirePublishedTranslation(version, "en");
        requirePublishedTranslation(version, "ar");
        if (version.getResultOptionsJson() == null || parseStrings(version.getResultOptionsJson()).isEmpty()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RESULT_OPTIONS_REQUIRED",
                    "error.resultOptions.required", "At least one result option is required");
        }
        version.publish(actor.userId(), now());
        versions.save(version);
        item.setCurrentPublishedVersionId(version.getId());
        item.setStatus("PUBLISHED");
        items.save(item);
        audit(actor, item.getCategoryId(), "MASTER_ITEM_PUBLISHED", "MASTER_ITEM", itemId, null,
                Map.of("version", Integer.toString(version.getVersionNo())));
        return versionDto(version);
    }

    @Transactional
    public ItemSummaryDto retireItem(CurrentUser actor, UUID itemId) {
        MasterInspectionItem item = requireItem(itemId);
        item.setStatus("RETIRED");
        items.save(item);
        audit(actor, item.getCategoryId(), "MASTER_ITEM_RETIRED", "MASTER_ITEM", itemId, null,
                Map.of("stableCode", item.getStableCode()));
        return summary(item);
    }

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
        audit(actor, null, "MASTER_REASON_CREATED", "REASON", reason.getId(), null,
                Map.of("code", reason.getCode()));
        return new ReasonDto(reason.getId(), reason.getCode(), reason.getStatus(), reason.getSortOrder(),
                request.labelEn(), request.labelAr());
    }

    @Transactional(readOnly = true)
    public List<EquipmentDto> listEquipment() {
        return equipment.findAllByOrderBySortOrderAsc().stream().map(item -> new EquipmentDto(
                item.getId(), item.getCode(), item.getStatus(), item.getSortOrder(),
                text(EQUIPMENT, item.getId(), "en", "label"),
                text(EQUIPMENT, item.getId(), "ar", "label"))).toList();
    }

    @Transactional
    public EquipmentDto createEquipment(CurrentUser actor, CatalogItemRequest request) {
        Equipment item = equipment.save(new Equipment(request.code().trim(),
                request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(EQUIPMENT, item.getId(), "en", "label", request.labelEn());
        putText(EQUIPMENT, item.getId(), "ar", "label", request.labelAr());
        audit(actor, null, "MASTER_EQUIPMENT_CREATED", "EQUIPMENT", item.getId(), null,
                Map.of("code", item.getCode()));
        return new EquipmentDto(item.getId(), item.getCode(), item.getStatus(), item.getSortOrder(),
                request.labelEn(), request.labelAr());
    }

    @Transactional(readOnly = true)
    public List<DropdownDto> listDropdowns() {
        return dropdowns.findAllByOrderBySortOrderAsc().stream().map(dropdown -> new DropdownDto(
                dropdown.getId(), dropdown.getCode(), dropdown.getStatus(), dropdown.getSortOrder(),
                text(DROPDOWN, dropdown.getId(), "en", "label"),
                text(DROPDOWN, dropdown.getId(), "ar", "label"),
                dropdownValues.findByDropdownIdOrderBySortOrderAsc(dropdown.getId()).stream()
                        .map(value -> new DropdownValueDto(value.getId(), value.getCode(), value.getStatus(),
                                value.getSortOrder(), text(DROPDOWN_VALUE, value.getId(), "en", "label"),
                                text(DROPDOWN_VALUE, value.getId(), "ar", "label")))
                        .toList())).toList();
    }

    @Transactional
    public DropdownDto createDropdown(CurrentUser actor, CatalogItemRequest request) {
        MasterDropdown dropdown = dropdowns.save(new MasterDropdown(request.code().trim(),
                request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(DROPDOWN, dropdown.getId(), "en", "label", request.labelEn());
        putText(DROPDOWN, dropdown.getId(), "ar", "label", request.labelAr());
        audit(actor, null, "MASTER_DROPDOWN_CREATED", "DROPDOWN", dropdown.getId(), null,
                Map.of("code", dropdown.getCode()));
        return new DropdownDto(dropdown.getId(), dropdown.getCode(), dropdown.getStatus(),
                dropdown.getSortOrder(), request.labelEn(), request.labelAr(), List.of());
    }

    @Transactional
    public DropdownValueDto addDropdownValue(CurrentUser actor, UUID dropdownId, CatalogItemRequest request) {
        MasterDropdown dropdown = dropdowns.findById(dropdownId).orElseThrow(ApiException::notFound);
        MasterDropdownValue value = dropdownValues.save(new MasterDropdownValue(dropdown.getId(),
                request.code().trim(), request.sortOrder() == null ? 0 : request.sortOrder()));
        putText(DROPDOWN_VALUE, value.getId(), "en", "label", request.labelEn());
        putText(DROPDOWN_VALUE, value.getId(), "ar", "label", request.labelAr());
        audit(actor, null, "MASTER_DROPDOWN_VALUE_CREATED", "DROPDOWN_VALUE", value.getId(), null,
                Map.of("dropdownCode", dropdown.getCode(), "code", value.getCode()));
        return new DropdownValueDto(value.getId(), value.getCode(), value.getStatus(),
                value.getSortOrder(), request.labelEn(), request.labelAr());
    }

    @Transactional(readOnly = true)
    public List<GuideImageDto> listGuideImages() {
        return guideImages.findAllByOrderByCreatedAtDesc().stream().map(this::guideImageDto).toList();
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
            GuideImage image = guideImages.save(new GuideImage(key, hash, mime, bytes.length,
                    null, null, licenceNote, actor.userId()));
            putText(GUIDE_IMAGE, image.getId(), "en", "alt_text", altEn == null ? "" : altEn);
            putText(GUIDE_IMAGE, image.getId(), "ar", "alt_text", altAr == null ? "" : altAr);
            audit(actor, null, "MASTER_GUIDE_IMAGE_UPLOADED", "GUIDE_IMAGE", image.getId(), null,
                    Map.of("mime", mime, "bytes", Long.toString(image.getBytes())));
            return guideImageDto(image);
        } catch (IOException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Unable to store guide image", e);
        }
    }

    @Transactional
    public GuideImageDto retireGuideImage(CurrentUser actor, UUID id) {
        GuideImage image = guideImages.findById(id).orElseThrow(ApiException::notFound);
        image.retire();
        guideImages.save(image);
        audit(actor, null, "MASTER_GUIDE_IMAGE_RETIRED", "GUIDE_IMAGE", id, null, Map.of());
        return guideImageDto(image);
    }

    @Transactional(readOnly = true)
    public GuideImageContent guideImageContent(UUID id) {
        GuideImage image = guideImages.findById(id).orElseThrow(ApiException::notFound);
        return new GuideImageContent(image.getMime(), objectStorage.get(image.getStorageKey()));
    }

    private void applyRules(MasterItemVersion version, RulesRequest request) {
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
        List<String> reasonCodes = request.reasonCodes() == null ? List.of() : request.reasonCodes();
        for (String code : reasonCodes) {
            if (reasons.findByCode(code).isEmpty()) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "REASON_NOT_FOUND",
                        "error.reason.notFound", "Unknown reason code");
            }
        }
        List<UUID> equipmentIds = request.equipmentIds() == null ? List.of() : request.equipmentIds();
        for (UUID equipmentId : equipmentIds) {
            if (!equipment.existsById(equipmentId)) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "EQUIPMENT_NOT_FOUND",
                        "error.equipment.notFound", "Unknown equipment");
            }
        }
        if (request.guideImageId() != null && !guideImages.existsById(request.guideImageId())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "GUIDE_IMAGE_NOT_FOUND",
                    "error.guideImage.notFound", "Unknown guide image");
        }
        version.setResultOptionsJson(json(resultOptions));
        version.setSeverityPolicyJson(request.severityPolicy() == null ? "{}" : request.severityPolicy());
        version.setApplicabilityJson(request.applicability() == null ? "{}" : request.applicability());
        version.setReasonCodesJson(json(reasonCodes));
        version.setNoteRequirement(note);
        version.setEvidenceRequirement(evidence);
        version.setMinPhotos(request.minPhotos() == null ? 0 : Math.max(0, request.minPhotos()));
        version.setEquipmentIdsJson(json(equipmentIds.stream().map(UUID::toString).toList()));
        version.setGuideImageId(request.guideImageId());
    }

    private void requirePublishedTranslation(MasterItemVersion version, String locale) {
        if (text(ITEM_VERSION, version.getId(), locale, "label").isBlank()
                || text(ITEM_VERSION, version.getId(), locale, "instruction").isBlank()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TRANSLATION_REQUIRED",
                    "error.translation.required", "English and Arabic label and instruction are required");
        }
    }

    private MasterItemVersion requireDraft(UUID itemId, UUID versionId) {
        MasterInspectionItem item = requireItem(itemId);
        MasterItemVersion version = versions.findById(versionId)
                .orElseThrow(ApiException::notFound);
        if (!version.getItemId().equals(item.getId())) {
            throw ApiException.notFound();
        }
        if (!version.getStatus().equals("DRAFT")) {
            throw ApiException.conflict("VERSION_IMMUTABLE", "Published versions cannot be edited");
        }
        return version;
    }

    private MasterInspectionItem requireItem(UUID itemId) {
        return items.findById(itemId).orElseThrow(ApiException::notFound);
    }

    private void copyTranslations(UUID fromVersionId, UUID toVersionId) {
        for (LocalizedContent content : localized.findByEntityTypeAndEntityId(ITEM_VERSION, fromVersionId)) {
            localized.save(new LocalizedContent(ITEM_VERSION, toVersionId, content.getLocale(),
                    content.getFieldKey(), content.getTextValue()));
        }
    }

    private void copyRules(MasterItemVersion from, MasterItemVersion to) {
        to.setResultOptionsJson(from.getResultOptionsJson());
        to.setSeverityPolicyJson(from.getSeverityPolicyJson());
        to.setApplicabilityJson(from.getApplicabilityJson());
        to.setReasonCodesJson(from.getReasonCodesJson());
        to.setNoteRequirement(from.getNoteRequirement());
        to.setEvidenceRequirement(from.getEvidenceRequirement());
        to.setMinPhotos(from.getMinPhotos());
        to.setEquipmentIdsJson(from.getEquipmentIdsJson());
        to.setGuideImageId(from.getGuideImageId());
    }

    private void putText(String entityType, UUID entityId, String locale, String field, String value) {
        String safe = value == null ? "" : value;
        LocalizedContent content = localized.findByEntityTypeAndEntityIdAndLocaleAndFieldKey(
                entityType, entityId, locale, field).orElse(null);
        if (content == null) {
            localized.save(new LocalizedContent(entityType, entityId, locale, field, safe));
        } else {
            content.setTextValue(safe);
            localized.save(content);
        }
    }

    private String text(String entityType, UUID entityId, String locale, String field) {
        return localized.findByEntityTypeAndEntityIdAndLocaleAndFieldKey(entityType, entityId, locale, field)
                .map(LocalizedContent::getTextValue).orElse("");
    }

    private CategoryDto categoryDto(MasterCategory category) {
        return new CategoryDto(category.getId(), category.getSlug(), category.getStatus(),
                category.getSortOrder(), text(CATEGORY, category.getId(), "en", "label"),
                text(CATEGORY, category.getId(), "ar", "label"),
                items.countByCategoryId(category.getId()));
    }

    private ItemSummaryDto summary(MasterInspectionItem item) {
        MasterItemVersion current = item.getCurrentPublishedVersionId() == null
                ? versions.findFirstByItemIdOrderByVersionNoDesc(item.getId()).orElse(null)
                : versions.findById(item.getCurrentPublishedVersionId()).orElse(null);
        MasterCategory category = categories.findById(item.getCategoryId()).orElse(null);
        String labelEn = current == null ? "" : text(ITEM_VERSION, current.getId(), "en", "label");
        String labelAr = current == null ? "" : text(ITEM_VERSION, current.getId(), "ar", "label");
        return new ItemSummaryDto(item.getId(), item.getStableCode(), item.getCategoryId(),
                category == null ? "" : text(CATEGORY, category.getId(), "en", "label"),
                category == null ? "" : text(CATEGORY, category.getId(), "ar", "label"),
                item.getStatus(), current == null ? null : current.getVersionNo(),
                labelEn, labelAr, item.isSampleData(),
                item.getUpdatedAt() == null ? "" : item.getUpdatedAt().toString());
    }

    private ItemVersionDto versionDto(MasterItemVersion version) {
        Map<String, TranslationDto> translations = new LinkedHashMap<>();
        for (LocalizedContent content : localized.findByEntityTypeAndEntityId(ITEM_VERSION, version.getId())) {
            TranslationDto current = translations.getOrDefault(content.getLocale(),
                    new TranslationDto(content.getLocale(), "", ""));
            if (content.getFieldKey().equals("label")) {
                translations.put(content.getLocale(),
                        new TranslationDto(content.getLocale(), content.getTextValue(), current.instruction()));
            } else if (content.getFieldKey().equals("instruction")) {
                translations.put(content.getLocale(),
                        new TranslationDto(content.getLocale(), current.label(), content.getTextValue()));
            }
        }
        return new ItemVersionDto(version.getId(), version.getVersionNo(), version.getStatus(),
                parseStrings(version.getResultOptionsJson()), version.getSeverityPolicyJson(),
                version.getApplicabilityJson(), parseStrings(version.getReasonCodesJson()),
                version.getNoteRequirement(), version.getEvidenceRequirement(), version.getMinPhotos(),
                parseUuids(version.getEquipmentIdsJson()), version.getGuideImageId(),
                version.getPublishedAt() == null ? "" : version.getPublishedAt().toString(), translations);
    }

    private GuideImageDto guideImageDto(GuideImage image) {
        return new GuideImageDto(image.getId(), image.getStatus(), image.getMime(), image.getBytes(),
                image.getLicenceNote(), text(GUIDE_IMAGE, image.getId(), "en", "alt_text"),
                text(GUIDE_IMAGE, image.getId(), "ar", "alt_text"),
                "/api/v1/platform/master/guide-images/" + image.getId() + "/content");
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Unable to serialize master content", e);
        }
    }

    private List<String> parseStrings(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(value, new TypeReference<List<String>>() { });
        } catch (JsonProcessingException e) {
            return List.of();
        }
    }

    private List<UUID> parseUuids(String value) {
        return parseStrings(value).stream().map(UUID::fromString).toList();
    }

    private boolean contains(String value, String query) {
        return value != null && value.toLowerCase().contains(query);
    }

    private String safeFilename(String filename) {
        String name = filename == null ? "image" : filename.replaceAll("[^A-Za-z0-9._-]", "_");
        return name.isBlank() ? "image" : name;
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private void audit(CurrentUser actor, UUID workshopId, String action, String entityType,
                       UUID entityId, String reason, Map<String, String> metadata) {
        auditService.record(workshopId, actor.userId(), actor.role(), action, entityType, entityId,
                reason, json(metadata));
    }

    public record GuideImageContent(String mime, byte[] bytes) {
    }
}
