package com.truereport.templates;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.masterdata.MasterContentService;
import com.truereport.masterdata.api.ItemVersionDto;
import com.truereport.masterdata.api.PublishedItemDto;
import com.truereport.masterdata.api.TranslationDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.templates.api.TemplateCreateRequest;
import com.truereport.templates.api.TemplateDetailDto;
import com.truereport.templates.api.TemplateDraftRequest;
import com.truereport.templates.api.TemplateItemRequest;
import com.truereport.templates.api.TemplateItemViewDto;
import com.truereport.templates.api.TemplateSummaryDto;
import com.truereport.templates.api.TemplateVersionOptionDto;
import com.truereport.templates.api.TemplateVersionSummaryDto;
import com.truereport.templates.api.TemplateVersionViewDto;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class WorkshopTemplateService {

    private final WorkshopTemplateRepository templates;
    private final TemplateVersionRepository versions;
    private final TemplateItemRepository items;
    private final MasterContentService masterContent;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    public WorkshopTemplateService(WorkshopTemplateRepository templates,
                                   TemplateVersionRepository versions,
                                   TemplateItemRepository items,
                                   MasterContentService masterContent,
                                   AuditService auditService,
                                   ObjectMapper objectMapper) {
        this.templates = templates;
        this.versions = versions;
        this.items = items;
        this.masterContent = masterContent;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<TemplateSummaryDto> list(CurrentUser caller) {
        UUID workshopId = requireWorkshopAdmin(caller);
        return templates.findByWorkshopIdOrderByUpdatedAtDesc(workshopId).stream()
                .map(template -> {
                    TemplateVersion current = template.getCurrentPublishedVersionId() == null
                            ? null
                            : versions.findById(template.getCurrentPublishedVersionId()).orElse(null);
                    long itemCount = current == null ? 0 : items.countByTemplateVersionId(current.getId());
                    return new TemplateSummaryDto(template.getId(), template.getName(),
                            template.getServiceType(), template.getVehicleType(), template.getStatus(),
                            current == null ? null : current.getVersionNo(), itemCount,
                            template.getUpdatedAt() == null ? "" : template.getUpdatedAt().toString());
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public TemplateDetailDto detail(CurrentUser caller, UUID templateId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        WorkshopTemplate template = requireTemplate(workshopId, templateId);
        List<TemplateVersion> versionList = versions.findByTemplateIdOrderByVersionNoDesc(templateId);
        TemplateVersion draft = versionList.stream()
                .filter(version -> version.getStatus().equals("DRAFT"))
                .findFirst().orElse(null);
        return new TemplateDetailDto(template.getId(), template.getName(), template.getDescription(),
                template.getServiceType(), template.getVehicleType(), template.getStatus(),
                template.getCurrentPublishedVersionId(),
                versionList.stream().map(this::summary).toList(),
                draft == null ? null : view(draft));
    }

    @Transactional
    public TemplateDetailDto create(CurrentUser caller, TemplateCreateRequest request) {
        UUID workshopId = requireWorkshopAdmin(caller);
        String name = request.name().trim();
        if (templates.findByWorkshopIdAndName(workshopId, name).isPresent()) {
            throw ApiException.conflict("TEMPLATE_NAME_EXISTS", "Template name already exists");
        }
        WorkshopTemplate template = templates.save(new WorkshopTemplate(
                workshopId, name, trimToNull(request.description()), request.serviceType().trim(),
                trimToNull(request.vehicleType()), caller.userId()));
        versions.save(new TemplateVersion(template.getId(), workshopId, 1));
        audit(caller, workshopId, "TEMPLATE_CREATED", template.getId(),
                Map.of("name", template.getName()));
        return detail(caller, template.getId());
    }

    @Transactional
    public TemplateDetailDto createDraft(CurrentUser caller, UUID templateId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        WorkshopTemplate template = requireTemplate(workshopId, templateId);
        if (template.getStatus().equals("RETIRED")) {
            throw ApiException.conflict("TEMPLATE_RETIRED", "Retired templates cannot be edited");
        }
        TemplateVersion latest = versions.findFirstByTemplateIdOrderByVersionNoDesc(templateId)
                .orElseThrow(() -> ApiException.conflict("TEMPLATE_NO_VERSION", "Template has no version"));
        if (latest.getStatus().equals("DRAFT")) {
            throw ApiException.conflict("TEMPLATE_DRAFT_EXISTS", "A draft already exists");
        }
        TemplateVersion draft = versions.save(new TemplateVersion(
                templateId, workshopId, latest.getVersionNo() + 1));
        for (TemplateItem item : items.findByTemplateVersionIdOrderBySortOrderAsc(latest.getId())) {
            items.save(new TemplateItem(draft.getId(), workshopId, item.getMasterItemVersionId(),
                    item.getSortOrder(), item.isIncluded(), item.getOverridesJson(),
                    item.getEffectiveRulesJson()));
        }
        audit(caller, workshopId, "TEMPLATE_DRAFT_CREATED", draft.getId(),
                Map.of("templateId", templateId.toString(),
                        "version", Integer.toString(draft.getVersionNo())));
        return detail(caller, templateId);
    }

    @Transactional
    public TemplateDetailDto saveDraft(CurrentUser caller, UUID templateId, TemplateDraftRequest request) {
        UUID workshopId = requireWorkshopAdmin(caller);
        WorkshopTemplate template = requireTemplate(workshopId, templateId);
        if (template.getStatus().equals("RETIRED")) {
            throw ApiException.conflict("TEMPLATE_RETIRED", "Retired templates cannot be edited");
        }
        TemplateVersion draft = versions.findByTemplateIdOrderByVersionNoDesc(templateId).stream()
                .filter(version -> version.getStatus().equals("DRAFT"))
                .findFirst()
                .orElseThrow(() -> ApiException.conflict("TEMPLATE_DRAFT_REQUIRED",
                        "Create a draft before saving template changes"));
        String name = request.name().trim();
        templates.findByWorkshopIdAndName(workshopId, name)
                .filter(existing -> !existing.getId().equals(templateId))
                .ifPresent(existing -> {
                    throw ApiException.conflict("TEMPLATE_NAME_EXISTS", "Template name already exists");
                });
        template.setName(name);
        template.setDescription(trimToNull(request.description()));
        template.setServiceType(request.serviceType().trim());
        template.setVehicleType(trimToNull(request.vehicleType()));
        templates.save(template);

        List<TemplateItemRequest> requests = request.items() == null ? List.of() : request.items();
        Set<UUID> seen = new HashSet<>();
        List<PreparedItem> prepared = new ArrayList<>();
        int index = 0;
        for (TemplateItemRequest itemRequest : requests) {
            if (!seen.add(itemRequest.masterItemVersionId())) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "DUPLICATE_TEMPLATE_ITEM",
                        "error.template.duplicateItem", "A master item version can only appear once");
            }
            if (itemRequest.overrides() != null && !itemRequest.overrides().isEmpty()) {
                throw weakens();
            }
            if (itemRequest.noteRequirement() != null
                    || itemRequest.evidenceRequirement() != null
                    || itemRequest.minPhotos() != null) {
                throw weakens();
            }
            PublishedItemDto published;
            try {
                published = masterContent.publishedItem(itemRequest.masterItemVersionId());
            } catch (ApiException exception) {
                if (exception.status() == HttpStatus.NOT_FOUND) {
                    throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "MASTER_ITEM_NOT_AVAILABLE",
                            "error.masterItem.notAvailable",
                            "Only approved, published master item versions can be added");
                }
                throw exception;
            }
            int sortOrder = itemRequest.sortOrder() == null ? index : itemRequest.sortOrder();
            prepared.add(new PreparedItem(published, sortOrder));
            index++;
        }
        prepared.sort(Comparator.comparingInt(PreparedItem::sortOrder));
        items.deleteByTemplateVersionId(draft.getId());
        for (PreparedItem preparedItem : prepared) {
            items.save(new TemplateItem(draft.getId(), workshopId,
                    preparedItem.published().versionId(), preparedItem.sortOrder(), true, "{}",
                    snapshot(preparedItem.published())));
        }
        audit(caller, workshopId, "TEMPLATE_DRAFT_SAVED", draft.getId(),
                Map.of("templateId", templateId.toString(),
                        "itemCount", Integer.toString(prepared.size())));
        return detail(caller, templateId);
    }

    @Transactional
    public TemplateDetailDto publish(CurrentUser caller, UUID templateId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        WorkshopTemplate template = requireTemplate(workshopId, templateId);
        if (template.getStatus().equals("RETIRED")) {
            throw ApiException.conflict("TEMPLATE_RETIRED", "Retired templates cannot be published");
        }
        TemplateVersion draft = versions.findByTemplateIdOrderByVersionNoDesc(templateId).stream()
                .filter(version -> version.getStatus().equals("DRAFT"))
                .findFirst()
                .orElseThrow(() -> ApiException.conflict("TEMPLATE_DRAFT_REQUIRED",
                        "There is no draft to publish"));
        List<TemplateItem> templateItems = items.findByTemplateVersionIdOrderBySortOrderAsc(draft.getId());
        if (templateItems.isEmpty()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_EMPTY",
                    "error.template.empty", "A template must contain at least one item");
        }
        for (TemplateItem item : templateItems) {
            try {
                masterContent.publishedItem(item.getMasterItemVersionId());
            } catch (ApiException exception) {
                if (exception.status() == HttpStatus.NOT_FOUND) {
                    throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "MASTER_ITEM_NOT_AVAILABLE",
                            "error.masterItem.notAvailable",
                            "A master item in this draft is no longer available");
                }
                throw exception;
            }
        }
        draft.publish(caller.userId(), now());
        versions.save(draft);
        template.setStatus("PUBLISHED");
        template.setCurrentPublishedVersionId(draft.getId());
        templates.save(template);
        audit(caller, workshopId, "TEMPLATE_PUBLISHED", draft.getId(),
                Map.of("templateId", templateId.toString(),
                        "version", Integer.toString(draft.getVersionNo()),
                        "itemCount", Integer.toString(templateItems.size())));
        return detail(caller, templateId);
    }

    @Transactional
    public TemplateDetailDto retire(CurrentUser caller, UUID templateId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        WorkshopTemplate template = requireTemplate(workshopId, templateId);
        template.setStatus("RETIRED");
        templates.save(template);
        audit(caller, workshopId, "TEMPLATE_RETIRED", templateId,
                Map.of("name", template.getName()));
        return detail(caller, templateId);
    }

    @Transactional(readOnly = true)
    public TemplateVersionViewDto pinnedVersion(UUID workshopId, UUID versionId) {
        TemplateVersion version = versions.findByIdAndWorkshopId(versionId, workshopId)
                .orElseThrow(ApiException::notFound);
        return view(version);
    }

    public TemplateVersionInfo requirePublishedVersionInfo(UUID workshopId, UUID versionId) {
        TemplateVersion version = versions.findByIdAndWorkshopId(versionId, workshopId)
                .filter(found -> found.getStatus().equals("PUBLISHED"))
                .orElseThrow(ApiException::notFound);
        WorkshopTemplate template = templates.findById(version.getTemplateId())
                .orElseThrow(ApiException::notFound);
        if (template.getStatus().equals("RETIRED")) {
            throw ApiException.notFound();
        }
        return new TemplateVersionInfo(version.getId(), template.getId(), template.getName(),
                version.getVersionNo(), template.getServiceType(), template.getVehicleType());
    }

    @Transactional(readOnly = true)
    public List<TemplateVersionOptionDto> publishedVersionsForWorkshop(UUID workshopId) {
        return versions.findByWorkshopIdAndStatusOrderByPublishedAtDesc(workshopId, "PUBLISHED").stream()
                .map(version -> Map.entry(version, templates.findById(version.getTemplateId()).orElse(null)))
                .filter(entry -> entry.getValue() != null && !entry.getValue().getStatus().equals("RETIRED"))
                .map(entry -> new TemplateVersionOptionDto(entry.getKey().getId(), entry.getKey().getTemplateId(),
                        entry.getValue().getName(), entry.getKey().getVersionNo(),
                        entry.getValue().getServiceType(), entry.getValue().getVehicleType()))
                .toList();
    }

    @Transactional(readOnly = true)
    public TemplateVersionViewDto versionView(CurrentUser caller, UUID templateId, UUID versionId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        requireTemplate(workshopId, templateId);
        TemplateVersion version = versions.findByIdAndWorkshopId(versionId, workshopId)
                .filter(found -> found.getTemplateId().equals(templateId))
                .orElseThrow(ApiException::notFound);
        return view(version);
    }

    @Transactional(readOnly = true)
    public TemplateVersionViewDto preview(CurrentUser caller, UUID templateId, UUID versionId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        WorkshopTemplate template = requireTemplate(workshopId, templateId);
        TemplateVersion version;
        if (versionId != null) {
            version = versions.findByIdAndWorkshopId(versionId, workshopId)
                    .filter(found -> found.getTemplateId().equals(templateId))
                    .orElseThrow(ApiException::notFound);
        } else {
            version = versions.findByTemplateIdOrderByVersionNoDesc(templateId).stream()
                    .filter(found -> found.getStatus().equals("DRAFT"))
                    .findFirst()
                    .orElseGet(() -> template.getCurrentPublishedVersionId() == null
                            ? null
                            : versions.findById(template.getCurrentPublishedVersionId()).orElse(null));
            if (version == null) {
                throw ApiException.notFound();
            }
        }
        return view(version);
    }

    @Transactional(readOnly = true)
    public List<TemplateVersionOptionDto> publishedVersions(CurrentUser caller) {
        return publishedVersionsForWorkshop(requireWorkshopAdmin(caller));
    }

    @Transactional(readOnly = true)
    public TemplateVersionInfo versionInfo(UUID workshopId, UUID versionId) {
        TemplateVersion version = versions.findByIdAndWorkshopId(versionId, workshopId)
                .filter(found -> found.getStatus().equals("PUBLISHED"))
                .orElseThrow(ApiException::notFound);
        WorkshopTemplate template = templates.findById(version.getTemplateId())
                .orElseThrow(ApiException::notFound);
        return new TemplateVersionInfo(version.getId(), template.getId(), template.getName(),
                version.getVersionNo(), template.getServiceType(), template.getVehicleType());
    }

    public void requirePublishedVersion(UUID workshopId, UUID versionId) {
        TemplateVersion version = versions.findByIdAndWorkshopId(versionId, workshopId)
                .filter(found -> found.getStatus().equals("PUBLISHED"))
                .orElseThrow(ApiException::notFound);
        WorkshopTemplate template = templates.findById(version.getTemplateId())
                .orElseThrow(ApiException::notFound);
        if (template.getStatus().equals("RETIRED")) {
            throw ApiException.notFound();
        }
    }

    private WorkshopTemplate requireTemplate(UUID workshopId, UUID templateId) {
        return templates.findByIdAndWorkshopId(templateId, workshopId)
                .orElseThrow(ApiException::notFound);
    }

    private UUID requireWorkshopAdmin(CurrentUser caller) {
        if (!caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        return caller.workshopId();
    }

    private TemplateVersionSummaryDto summary(TemplateVersion version) {
        return new TemplateVersionSummaryDto(version.getId(), version.getVersionNo(), version.getStatus(),
                version.getPublishedAt() == null ? "" : version.getPublishedAt().toString(),
                items.countByTemplateVersionId(version.getId()));
    }

    private TemplateVersionViewDto view(TemplateVersion version) {
        return new TemplateVersionViewDto(version.getId(), version.getVersionNo(), version.getStatus(),
                version.getPublishedAt() == null ? "" : version.getPublishedAt().toString(),
                items.findByTemplateVersionIdOrderBySortOrderAsc(version.getId()).stream()
                        .map(this::view).toList());
    }

    private TemplateItemViewDto view(TemplateItem item) {
        JsonNode node = parse(item.getEffectiveRulesJson());
        return new TemplateItemViewDto(
                item.getMasterItemVersionId(),
                item.getSortOrder(),
                text(node, "stableCode"),
                text(node, "categoryLabelEn"),
                text(node, "categoryLabelAr"),
                text(node, "labelEn"),
                text(node, "labelAr"),
                text(node, "instructionEn"),
                text(node, "instructionAr"),
                node.path("versionNo").asInt(0),
                strings(node, "resultOptions"),
                text(node, "severityPolicy"),
                text(node, "applicability"),
                strings(node, "reasonCodes"),
                text(node, "noteRequirement"),
                text(node, "evidenceRequirement"),
                node.path("minPhotos").asInt(0),
                uuids(node, "equipmentIds"),
                text(node, "guideImageId").isBlank() ? null : UUID.fromString(text(node, "guideImageId")),
                node.path("sampleData").asBoolean(false));
    }

    private String snapshot(PublishedItemDto item) {
        ItemVersionDto version = item.version();
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("itemId", item.itemId().toString());
        snapshot.put("masterItemVersionId", item.versionId().toString());
        snapshot.put("versionNo", version.versionNo());
        snapshot.put("stableCode", item.stableCode());
        snapshot.put("categoryId", item.categoryId().toString());
        snapshot.put("categoryLabelEn", item.categoryLabelEn());
        snapshot.put("categoryLabelAr", item.categoryLabelAr());
        snapshot.put("labelEn", version.labelEn());
        snapshot.put("labelAr", version.labelAr());
        snapshot.put("instructionEn", version.instructionEn());
        snapshot.put("instructionAr", version.instructionAr());
        snapshot.put("resultOptions", version.resultOptions());
        snapshot.put("severityPolicy", version.severityPolicy());
        snapshot.put("applicability", version.applicability());
        snapshot.put("reasonCodes", version.reasonCodes());
        snapshot.put("noteRequirement", version.noteRequirement());
        snapshot.put("evidenceRequirement", version.evidenceRequirement());
        snapshot.put("minPhotos", version.minPhotos());
        snapshot.put("equipmentIds", version.equipmentIds().stream().map(UUID::toString).toList());
        snapshot.put("guideImageId", version.guideImageId() == null ? "" : version.guideImageId().toString());
        snapshot.put("sampleData", item.sampleData());
        return json(snapshot);
    }

    private JsonNode parse(String value) {
        try {
            return objectMapper.readTree(value == null || value.isBlank() ? "{}" : value);
        } catch (JsonProcessingException exception) {
            return objectMapper.createObjectNode();
        }
    }

    private String text(JsonNode node, String field) {
        return node.path(field).asText("");
    }

    private List<String> strings(JsonNode node, String field) {
        List<String> result = new ArrayList<>();
        JsonNode array = node.path(field);
        if (array.isArray()) {
            array.forEach(value -> result.add(value.asText()));
        }
        return result;
    }

    private List<UUID> uuids(JsonNode node, String field) {
        return strings(node, field).stream().filter(value -> !value.isBlank()).map(UUID::fromString).toList();
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize template snapshot", exception);
        }
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private ApiException weakens() {
        return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_WEAKENS_SAFETY_RULE",
                "error.template.weakensSafetyRule",
                "Workshop overrides cannot change or weaken a master safety rule");
    }

    private void audit(CurrentUser actor, UUID workshopId, String action, UUID entityId,
                       Map<String, String> metadata) {
        auditService.record(workshopId, actor.userId(), actor.role(), action, "TEMPLATE", entityId,
                null, json(metadata));
    }

    private record PreparedItem(PublishedItemDto published, int sortOrder) {
    }
}

