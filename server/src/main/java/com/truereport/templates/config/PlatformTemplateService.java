package com.truereport.templates.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.localization.TranslationGate;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.templates.config.PlatformTemplateDtos.ChangeRequestDto;
import com.truereport.templates.config.PlatformTemplateDtos.CreateTemplateRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateCategoryRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateSummaryDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateVersionDto;
import com.truereport.templates.config.PlatformTemplateDtos.UpdateTemplateRequest;
import com.truereport.templates.config.TemplateRepository.VersionRow;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class PlatformTemplateService {

    private final TemplateRepository templates;
    private final FieldAuditService audit;
    private final TranslationGate translationGate;
    private final OutboxService outbox;
    private final ObjectMapper objectMapper;

    public PlatformTemplateService(TemplateRepository templates, FieldAuditService audit,
                                    OutboxService outbox, ObjectMapper objectMapper,
                                    TranslationGate translationGate) {
        this.templates = templates;
        this.audit = audit;
        this.outbox = outbox;
        this.objectMapper = objectMapper;
        this.translationGate = translationGate;
    }

    @Transactional(readOnly = true)
    public List<TemplateSummaryDto> list() {
        return list(false);
    }

    public List<TemplateSummaryDto> list(boolean publishedOnly) {
        return templates.findAll(publishedOnly);
    }

    @Transactional(readOnly = true)
    public TemplateSummaryDto detail(String id) {
        return templates.findById(id).orElseThrow(PlatformTemplateService::notFound);
    }

    @Transactional(readOnly = true)
    public TemplateVersionDto version(String templateId, String versionId) {
        requireVersion(templateId, versionId);
        return templates.findVersion(templateId, versionId)
                .orElseThrow(PlatformTemplateService::notFound);
    }

    @Transactional
    public TemplateSummaryDto create(CurrentUser actor, CreateTemplateRequest request) {
        translationGate.requireNewContentAllowed("Template");
        String code = trimToNull(request.code());
        String nameEn = trimToNull(request.nameEn());
        String nameAr = trimToNull(request.nameAr());
        if (code == null || nameEn == null || nameAr == null) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_INVALID",
                    "error.template.invalid",
                    "Template code, nameEn and nameAr are required");
        }
        if (templates.codeExists(code)) {
            throw new ApiException(HttpStatus.CONFLICT, "TEMPLATE_CODE_EXISTS",
                    "error.template.codeExists", "A template with this code already exists");
        }
        String id = templates.insertTemplate(code, nameEn, nameAr,
                trimToNull(request.descriptionEn()), trimToNull(request.descriptionAr()));
        String versionId = templates.insertVersion(id, 1, "DRAFT");
        audit.record(actor, "TEMPLATE_CREATED", "TEMPLATE", id, null,
                Map.of("code", code, "nameEn", nameEn, "nameAr", nameAr,
                        "draftVersionId", versionId), null, null);
        return detail(id);
    }

    @Transactional
    public TemplateSummaryDto update(CurrentUser actor, String id, UpdateTemplateRequest request) {
        TemplateSummaryDto before = detail(id);
        String nameEn = isBlank(request.nameEn()) ? before.nameEn() : request.nameEn().trim();
        String nameAr = isBlank(request.nameAr()) ? before.nameAr() : request.nameAr().trim();
        String descriptionEn = request.descriptionEn() == null
                ? before.descriptionEn() : trimToNull(request.descriptionEn());
        String descriptionAr = request.descriptionAr() == null
                ? before.descriptionAr() : trimToNull(request.descriptionAr());
        templates.updateTemplate(id, nameEn, nameAr, descriptionEn, descriptionAr);
        TemplateSummaryDto after = detail(id);
        audit.record(actor, "TEMPLATE_UPDATED", "TEMPLATE", id,
                Map.of("nameEn", before.nameEn(), "nameAr", before.nameAr(),
                        "descriptionEn", nullSafe(before.descriptionEn()),
                        "descriptionAr", nullSafe(before.descriptionAr())),
                Map.of("nameEn", after.nameEn(), "nameAr", after.nameAr(),
                        "descriptionEn", nullSafe(after.descriptionEn()),
                        "descriptionAr", nullSafe(after.descriptionAr())),
                null, null);
        return after;
    }

    @Transactional
    public TemplateSummaryDto createDraft(CurrentUser actor, String templateId) {
        detail(templateId);
        Optional<VersionRow> latest = templates.findLatestVersion(templateId);
        if (latest.isPresent() && "DRAFT".equals(latest.get().status())) {
            throw new ApiException(HttpStatus.CONFLICT, "DRAFT_EXISTS",
                    "error.template.draftExists", "A draft version already exists");
        }
        int versionNo = latest.map(VersionRow::versionNo).orElse(0) + 1;
        String versionId = templates.insertVersion(templateId, versionNo, "DRAFT");
        latest.ifPresent(version -> templates.copyItems(version.id(), versionId));
        audit.record(actor, "TEMPLATE_DRAFT_CREATED", "TEMPLATE_VERSION", versionId, null,
                Map.of("templateId", templateId, "versionNo", versionNo), null, null);
        return detail(templateId);
    }

    @Transactional
    public TemplateVersionDto replaceCategories(CurrentUser actor, String templateId, String versionId,
                                                List<TemplateCategoryRequest> categories) {
        VersionRow version = requireVersion(templateId, versionId);
        if (!"DRAFT".equals(version.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "VERSION_IMMUTABLE",
                    "error.template.versionImmutable",
                    "Only draft versions can be edited");
        }
        List<TemplateCategoryRequest> requests = categories == null ? List.of() : categories;
        templates.replaceCategories(versionId, requests);
        audit.record(actor, "TEMPLATE_CATEGORIES_REPLACED", "TEMPLATE_VERSION", versionId, null,
                Map.of("categoryCount", requests.size()), null, null);
        return templates.findVersion(templateId, versionId)
                .orElseThrow(PlatformTemplateService::notFound);
    }

    @Transactional
    public TemplateVersionDto replaceItems(CurrentUser actor, String templateId, String versionId,
                                           List<TemplateItemRequest> items) {
        VersionRow version = requireVersion(templateId, versionId);
        if (!"DRAFT".equals(version.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "VERSION_IMMUTABLE",
                    "error.template.versionImmutable",
                    "Only draft versions can be edited");
        }
        List<TemplateItemRequest> requests = items == null ? List.of() : items;
        templates.replaceItems(versionId, requests);
        audit.record(actor, "TEMPLATE_ITEMS_REPLACED", "TEMPLATE_VERSION", versionId, null,
                Map.of("itemCount", requests.size()), null, null);
        return templates.findVersion(templateId, versionId)
                .orElseThrow(PlatformTemplateService::notFound);
    }

    @Transactional
    public TemplateSummaryDto publish(CurrentUser actor, String templateId, String versionId) {
        TemplateSummaryDto template = detail(templateId);
        VersionRow version = requireVersion(templateId, versionId);
        if (!"DRAFT".equals(version.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "VERSION_IMMUTABLE",
                    "error.template.versionImmutable",
                    "Only draft versions can be published");
        }
        if (templates.countCategories(versionId) <= 0 || templates.countItems(versionId) <= 0) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_ITEMS_REQUIRED",
                    "error.template.itemsRequired",
                    "A template must contain at least one category with one included item before it can be published");
        }
        if (isBlank(template.nameEn()) || isBlank(template.nameAr())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_NAME_REQUIRED",
                    "error.template.nameRequired",
                    "A template must have both an English and an Arabic name before it can be published");
        }
        translationGate.requireOverlaysApproved("TEMPLATE", templateId,
                java.util.List.of("name", "description"));
        if (templates.findPendingChangeRequest("TEMPLATE_VERSION", versionId).isPresent()) {
            throw new ApiException(HttpStatus.CONFLICT, "CHANGE_REQUEST_EXISTS",
                    "error.template.changeRequestExists",
                    "A change request is already pending for this version");
        }
        String actorId = actor.userId().toString();
        String payload = json(Map.of(
                "proposedBy", actorId,
                "templateId", templateId,
                "versionId", versionId,
                "versionNo", version.versionNo()));
        String requestId = templates.createPendingChangeRequest(
                "TEMPLATE_VERSION", versionId, "PUBLISH", payload, actorId);
        templates.updateVersionStatus(versionId, "PENDING_APPROVAL", null);
        audit.record(actor, "TEMPLATE_PUBLISH_REQUESTED", "TEMPLATE_VERSION", versionId,
                Map.of("status", "DRAFT"),
                Map.of("status", "PENDING_APPROVAL", "changeRequestId", requestId), null, null);
        return detail(templateId);
    }

    @Transactional
    public TemplateSummaryDto approve(CurrentUser actor, String templateId, String versionId) {
        TemplateSummaryDto template = detail(templateId);
        VersionRow version = requireVersion(templateId, versionId);
        ChangeRequestDto request = requirePendingPublishRequest(versionId);
        String actorId = actor.userId().toString();
        if (request.proposedBy() != null && request.proposedBy().equals(actorId)) {
            throw new ApiException(HttpStatus.CONFLICT, "MAKER_CHECKER_SELF_APPROVAL",
                    "error.makerChecker.selfApproval",
                    "The proposer of a change cannot approve it");
        }
        translationGate.requireOverlaysApproved("TEMPLATE", templateId,
                java.util.List.of("name", "description"));
        templates.updateVersionStatus(versionId, "PUBLISHED", actorId);
        templates.setCurrentPublishedVersion(templateId, versionId);
        templates.setTemplateStatus(templateId, "ACTIVE");
        templates.approveChangeRequest(request.id(), actorId);
        audit.record(actor, "TEMPLATE_PUBLISHED", "TEMPLATE_VERSION", versionId,
                Map.of("status", "PENDING_APPROVAL"),
                Map.of("status", "PUBLISHED", "templateId", templateId, "versionId", versionId),
                null, null);
        outbox.publish("TEMPLATE", templateId, "TEMPLATE_PUBLISHED", Map.of(
                "templateId", templateId,
                "templateCode", nullSafe(template.code()),
                "versionId", versionId,
                "versionNo", version.versionNo(),
                "publishedBy", actorId));
        return detail(templateId);
    }

    @Transactional
    public TemplateSummaryDto reject(CurrentUser actor, String templateId, String versionId,
                                     String reason) {
        detail(templateId);
        requireVersion(templateId, versionId);
        ChangeRequestDto request = requirePendingPublishRequest(versionId);
        templates.updateVersionStatus(versionId, "DRAFT", null);
        templates.rejectChangeRequest(request.id(), actor.userId().toString(), reason);
        audit.record(actor, "TEMPLATE_PUBLISH_REJECTED", "TEMPLATE_VERSION", versionId,
                Map.of("status", "PENDING_APPROVAL"), Map.of("status", "DRAFT"), reason, null);
        return detail(templateId);
    }

    @Transactional
    public TemplateSummaryDto retire(CurrentUser actor, String templateId) {
        TemplateSummaryDto before = detail(templateId);
        templates.retireTemplate(templateId);
        audit.record(actor, "TEMPLATE_RETIRED", "TEMPLATE", templateId,
                Map.of("status", before.status()), Map.of("status", "RETIRED"), null, null);
        return detail(templateId);
    }

    private ChangeRequestDto requirePendingPublishRequest(String versionId) {
        return templates.findPendingChangeRequest("TEMPLATE_VERSION", versionId)
                .filter(request -> "PUBLISH".equals(request.actionCode()))
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT,
                        "CHANGE_REQUEST_NOT_FOUND", "error.template.changeRequestNotFound",
                        "No pending publish request was found for this version"));
    }

    private VersionRow requireVersion(String templateId, String versionId) {
        VersionRow version = templates.findVersionRow(versionId).orElseThrow(
                PlatformTemplateService::notFound);
        if (!version.templateId().equals(templateId)) {
            throw notFound();
        }
        return version;
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to serialize change request payload", ex);
        }
    }

    private static String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private static String nullSafe(String value) {
        return value == null ? "" : value;
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "TEMPLATE_NOT_FOUND",
                "error.template.notFound", "Template not found");
    }
}
