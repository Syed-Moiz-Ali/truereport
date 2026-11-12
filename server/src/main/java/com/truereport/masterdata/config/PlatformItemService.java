package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRuleDto;
import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemConfigDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemMetadataDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemMetadataRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.masterdata.config.PlatformContentStore.ItemRow;
import com.truereport.masterdata.config.PlatformContentStore.VersionRow;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class PlatformItemService {

    private final PlatformContentStore content;
    private final ItemConfigRepository itemConfig;
    private final OptionSetRepository optionSets;
    private final FieldAuditService audit;

    public PlatformItemService(PlatformContentStore content,
                               ItemConfigRepository itemConfig,
                               OptionSetRepository optionSets,
                               FieldAuditService audit) {
        this.content = content;
        this.itemConfig = itemConfig;
        this.optionSets = optionSets;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public ItemMetadataDto metadata(UUID itemId) {
        ItemRow item = content.item(itemId.toString()).orElseThrow(ApiException::notFound);
        VersionRow version = content.currentOrLatestVersion(item).orElseThrow(ApiException::notFound);
        return metadataFrom(version, item.sortOrder());
    }

    @Transactional
    public ItemMetadataDto updateMetadata(CurrentUser actor, UUID itemId,
                                          ItemMetadataRequest request, HttpServletRequest http) {
        ItemRow item = content.item(itemId.toString()).orElseThrow(ApiException::notFound);
        VersionRow current = content.latestVersion(itemId.toString())
                .orElseThrow(ApiException::notFound);
        if (!"DRAFT".equals(current.status())) {
            throw ApiException.conflict("VERSION_IMMUTABLE",
                    "Metadata can only be edited on a draft version");
        }
        int sortOrder = request.sortOrder() == null ? item.sortOrder() : request.sortOrder();
        if (request.sortOrder() != null) {
            content.updateItemSortOrder(itemId.toString(), sortOrder);
        }
        VersionRow updated = content.updateMetadata(itemId, UUID.fromString(current.id()),
                first(request.measurementUnit(), current.measurementUnit()),
                first(request.sensorTool(), current.sensorTool()),
                first(request.standardSpecEn(), current.standardSpecEn()),
                first(request.standardSpecAr(), current.standardSpecAr()),
                request.safetyCritical() == null ? current.safetyCritical() : request.safetyCritical(),
                request.multiPoint() == null ? current.multiPoint() : request.multiPoint(),
                request.maxTyreAgeYears() == null ? current.maxTyreAgeYears() : request.maxTyreAgeYears(),
                request.allowFreeTextNote() == null
                        ? current.allowFreeTextNote() : request.allowFreeTextNote(),
                request.guideImageId() == null ? current.guideImageId() : request.guideImageId());
        audit.record(actor, "MASTER_ITEM_METADATA_UPDATED", "MASTER_ITEM_VERSION",
                current.id(), null, updated, null, http);
        return metadataFrom(updated, sortOrder);
    }

    @Transactional(readOnly = true)
    public ItemConfigDto config(UUID itemId, UUID versionId) {
        VersionRow version = requireVersion(itemId, versionId);
        return new ItemConfigDto(
                metadataFrom(version, content.item(itemId.toString())
                        .map(ItemRow::sortOrder).orElse(0)),
                itemConfig.evidenceRules(versionId.toString()),
                itemConfig.issueFields(versionId.toString()),
                itemConfig.measurementBands(versionId.toString()));
    }

    @Transactional
    public List<EvidenceRuleDto> replaceEvidenceRules(CurrentUser actor, UUID itemId,
                                                     UUID versionId, List<EvidenceRuleDto> rules,
                                                     HttpServletRequest http) {
        requireDraft(itemId, versionId);
        for (EvidenceRuleDto rule : rules) {
            if (!ConfigValidators.RESULT_CODES.contains(rule.resultCode())) {
                throw ApiException.unprocessable("EVIDENCE_RULES_INVALID", "Invalid result code");
            }
            if (rule.requiredEvidenceType() != null
                    && !ConfigValidators.EVIDENCE_TYPES.contains(rule.requiredEvidenceType())) {
                throw ApiException.unprocessable("EVIDENCE_RULES_INVALID", "Invalid evidence type");
            }
        }
        itemConfig.replaceEvidenceRules(versionId.toString(), rules);
        audit.record(actor, "MASTER_ITEM_EVIDENCE_RULES_UPDATED", "MASTER_ITEM_VERSION",
                versionId.toString(), null, rules, null, http);
        return itemConfig.evidenceRules(versionId.toString());
    }

    @Transactional
    public List<IssueFieldDto> replaceIssueFields(CurrentUser actor, UUID itemId,
                                                 UUID versionId, List<IssueFieldDto> fields,
                                                 HttpServletRequest http) {
        requireDraft(itemId, versionId);
        ConfigValidators.validateIssueFields(fields, optionSets.optionSetCodes());
        itemConfig.replaceIssueFields(versionId.toString(), fields);
        audit.record(actor, "MASTER_ITEM_ISSUE_FIELDS_UPDATED", "MASTER_ITEM_VERSION",
                versionId.toString(), null, fields, null, http);
        return itemConfig.issueFields(versionId.toString());
    }

    @Transactional
    public List<MeasurementBandDto> replaceMeasurementBands(CurrentUser actor, UUID itemId,
                                                           UUID versionId,
                                                           List<MeasurementBandDto> bands,
                                                           HttpServletRequest http) {
        requireDraft(itemId, versionId);
        ConfigValidators.validateMeasurementBands(bands);
        itemConfig.replaceMeasurementBands(versionId.toString(), bands);
        audit.record(actor, "MASTER_ITEM_MEASUREMENT_BANDS_UPDATED", "MASTER_ITEM_VERSION",
                versionId.toString(), null, bands, null, http);
        return itemConfig.measurementBands(versionId.toString());
    }

    @Transactional
    public void reorderItems(List<String> orderedIds) {
        if (orderedIds != null) {
            content.reorderItems(orderedIds);
        }
    }

    @Transactional(readOnly = true)
    public void assertPublishable(UUID itemId, UUID versionId) {
        VersionRow version = requireVersion(itemId, versionId);
        if (!version.safetyCritical()) {
            return;
        }
        List<EvidenceRuleDto> rules = itemConfig.evidenceRules(versionId.toString());
        boolean failRule = rules.stream().anyMatch(rule ->
                "DEFECT_FOUND".equals(rule.resultCode())
                        && rule.minPhotos() >= 2 && rule.minVideos() >= 1);
        if (!failRule) {
            throw ApiException.unprocessable("SAFETY_EVIDENCE_REQUIRED",
                    "Safety-critical items require FAIL evidence rules (2 photos + 1 video)");
        }
        if (version.measurementUnit() != null && !version.measurementUnit().isBlank()
                && itemConfig.measurementBands(versionId.toString()).isEmpty()) {
            throw ApiException.unprocessable("SAFETY_MEASUREMENT_BANDS_REQUIRED",
                    "Numeric safety-critical items require measurement bands");
        }
    }

    private VersionRow requireVersion(UUID itemId, UUID versionId) {
        VersionRow version = content.version(versionId.toString()).orElseThrow(ApiException::notFound);
        if (!version.itemId().equals(itemId.toString())) {
            throw ApiException.notFound();
        }
        return version;
    }

    private VersionRow requireDraft(UUID itemId, UUID versionId) {
        return content.requireDraft(itemId, versionId);
    }

    private ItemMetadataDto metadataFrom(VersionRow version, int sortOrder) {
        return new ItemMetadataDto(version.itemId(), version.measurementUnit(),
                version.sensorTool(), version.standardSpecEn(), version.standardSpecAr(),
                version.safetyCritical(), version.multiPoint(), version.maxTyreAgeYears(),
                version.allowFreeTextNote(), sortOrder, version.guideImageId());
    }

    private static String first(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    @SuppressWarnings("unused")
    private static Map<String, Object> empty() {
        return Map.of();
    }
}
