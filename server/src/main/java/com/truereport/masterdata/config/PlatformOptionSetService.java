package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueUpdateRequest;
import com.truereport.localization.DynamicContentTranslations;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.localization.TranslationGate;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class PlatformOptionSetService {

    private final OptionSetRepository repository;
    private final FieldAuditService audit;
    private final TranslationGate translationGate;
    private final DynamicContentTranslations translations;

    public PlatformOptionSetService(OptionSetRepository repository, FieldAuditService audit,
                                    TranslationGate translationGate,
                                    DynamicContentTranslations translations) {
        this.repository = repository;
        this.audit = audit;
        this.translationGate = translationGate;
        this.translations = translations;
    }

    @Transactional(readOnly = true)
    public List<OptionSetDto> list() {
        return repository.findAll();
    }

    @Transactional(readOnly = true)
    public OptionSetDto get(String id) {
        return repository.findById(id).orElseThrow(ApiException::notFound);
    }

    @Transactional
    public OptionSetDto create(CurrentUser actor, OptionSetRequest request, HttpServletRequest http) {
        translationGate.requireNewContentAllowed("Option set");
        String code = requireCode(request.code());
        String name = firstNonBlank(request.name(), source(request.translations(), "name", request.nameEn()));
        translations.requireEnglishSource("name", name);
        if (repository.findByCode(code).isPresent()) {
            throw ApiException.conflict("OPTION_SET_EXISTS", "Option set code already exists");
        }
        Map<String, Map<String, String>> setTranslations =
                overlays(request.translations(), "name", request.nameAr());
        boolean allLiveProvided = translationGate.translationProvidedForLive(
                setTranslations, "name");
        OptionSetDto created = repository.insert(code, name.trim(), setTranslations,
                request.sortOrder() == null ? 0 : request.sortOrder(),
                allLiveProvided ? "ACTIVE" : "DRAFT");
        OptionSetDto result = repository.findById(created.id()).orElse(created);
        audit.record(actor, "OPTION_SET_CREATED", "OPTION_SET", result.id(), null, result, null, http);
        return result;
    }

    @Transactional
    public OptionSetDto update(CurrentUser actor, String id, OptionSetRequest request,
                               HttpServletRequest http) {
        OptionSetDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        String name = request.translations() == null || request.translations().get("name") == null
                ? firstNonBlank(request.name(), request.nameEn()) : source(request.translations(), "name", firstNonBlank(request.name(), request.nameEn()));
        String targetStatus = normalizeStatus(request.status());
        if (statusChangeToActive(existing.status(), targetStatus)) {
            translationGate.requireOverlaysApproved("OPTION_SET", id);
        }
        repository.update(id, name,
                overlays(request.translations(), "name", request.nameAr()),
                request.sortOrder(), targetStatus);
        OptionSetDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "OPTION_SET_UPDATED", "OPTION_SET", id, existing, updated, null, http);
        return updated;
    }

    @Transactional
    public OptionSetDto retire(CurrentUser actor, String id, HttpServletRequest http) {
        OptionSetDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        if (repository.optionSetInUse(id)) {
            throw ApiException.conflict("OPTION_SET_IN_USE",
                    "Option sets referenced by active items cannot be retired");
        }
        repository.retire(id);
        OptionSetDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "OPTION_SET_RETIRED", "OPTION_SET", id, existing, updated, null, http);
        return updated;
    }

    @Transactional
    public OptionValueDto addValue(CurrentUser actor, String setId, OptionValueRequest request,
                                   HttpServletRequest http) {
        translationGate.requireNewContentAllowed("Option value");
        OptionSetDto set = repository.findById(setId).orElseThrow(ApiException::notFound);
        String code = requireCode(request.code());
        String label = firstNonBlank(request.label(), source(request.translations(), "label", request.labelEn()));
        translations.requireEnglishSource("label", label);
        if (repository.findValueByCode(setId, code).isPresent()) {
            throw ApiException.conflict("OPTION_VALUE_EXISTS", "Option value code already exists");
        }
        Map<String, Map<String, String>> valueTranslations =
                overlays(request.translations(), "label", request.labelAr());
        boolean allLiveProvided = translationGate.translationProvidedForLive(
                valueTranslations, "label");
        OptionValueDto created = repository.insertValue(setId, code, label.trim(),
                valueTranslations, request.sortOrder() == null ? 0 : request.sortOrder(),
                request.metadataJson(), allLiveProvided ? "ACTIVE" : "DRAFT");
        OptionValueDto result = repository.findValue(created.id()).orElse(created);
        audit.record(actor, "OPTION_VALUE_CREATED", "OPTION_VALUE", result.id(), null, result, null, http);
        return result;
    }

    @Transactional
    public OptionValueDto updateValue(CurrentUser actor, String setId, String valueId,
                                      OptionValueUpdateRequest request, HttpServletRequest http) {
        repository.findById(setId).orElseThrow(ApiException::notFound);
        OptionValueDto existing = repository.findValue(valueId).orElseThrow(ApiException::notFound);
        String label = request.translations() == null || request.translations().get("label") == null
                ? firstNonBlank(request.label(), request.labelEn()) : source(request.translations(), "label", firstNonBlank(request.label(), request.labelEn()));
        String targetStatus = normalizeStatus(request.status());
        if (statusChangeToActive(existing.status(), targetStatus)) {
            translationGate.requireOverlaysApproved("OPTION_VALUE", valueId);
        }
        repository.updateValue(valueId, label,
                overlays(request.translations(), "label", request.labelAr()), request.sortOrder(),
                request.metadataJson(), targetStatus);
        OptionValueDto updated = repository.findValue(valueId).orElse(existing);
        audit.record(actor, "OPTION_VALUE_UPDATED", "OPTION_VALUE", valueId, existing, updated, null, http);
        return updated;
    }

    @Transactional
    public OptionValueDto retireValue(CurrentUser actor, String setId, String valueId,
                                      String replacementCode, HttpServletRequest http) {
        repository.findById(setId).orElseThrow(ApiException::notFound);
        OptionValueDto existing = repository.findValue(valueId).orElseThrow(ApiException::notFound);
        if (repository.valueInUse(valueId)) {
            if (replacementCode == null || replacementCode.isBlank()) {
                throw ApiException.conflict("OPTION_IN_USE",
                        "Option value is in use; provide a replacement code before retiring");
            }
            OptionValueDto replacement = repository.findValueByCode(setId, replacementCode)
                    .orElseThrow(() -> ApiException.unprocessable("OPTION_REPLACEMENT_NOT_FOUND",
                            "Replacement option value was not found"));
            repository.replaceInUse(valueId, replacement.id());
        }
        repository.retireValue(valueId);
        OptionValueDto updated = repository.findValue(valueId).orElse(existing);
        audit.record(actor, "OPTION_VALUE_RETIRED", "OPTION_VALUE", valueId, existing, updated, null, http);
        return updated;
    }

    @Transactional
    public List<OptionValueDto> reorderValues(String setId, List<String> orderedIds) {
        repository.findById(setId).orElseThrow(ApiException::notFound);
        if (orderedIds != null && !orderedIds.isEmpty()) {
            repository.reorderValues(setId, orderedIds);
        }
        return repository.values(setId);
    }

    private static String normalizeStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        String normalized = status.trim().toUpperCase(Locale.ROOT);
        if (!List.of("ACTIVE", "DRAFT", "RETIRED").contains(normalized)) {
            throw ApiException.unprocessable("INVALID_STATUS", "Invalid status");
        }
        return normalized;
    }

    private static boolean statusChangeToActive(String current, String target) {
        return "ACTIVE".equals(target) && !"ACTIVE".equals(current);
    }

    private static String requireCode(String code) {
        if (code == null || code.isBlank()) {
            throw ApiException.validation("CODE_REQUIRED", "Code is required",
                    List.of(FieldIssue.of("code", "REQUIRED", "error.field.invalid")));
        }
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private String source(Map<String, Map<String, String>> provided, String field, String legacyEn) {
        String translated = translations.source(provided, field, null);
        return translated == null || translated.isBlank() ? blankToNull(legacyEn) : translated;
    }

    private Map<String, Map<String, String>> overlays(Map<String, Map<String, String>> provided,
                                                      String field, String legacyAr) {
        Map<String, String> legacy = new LinkedHashMap<>();
        String value = blankToNull(legacyAr);
        if (value != null) {
            legacy.put("ar", value);
        }
        return translations.mergeLegacy(provided, legacy);
    }

    private static String firstNonBlank(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return blankToNull(fallback);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}

