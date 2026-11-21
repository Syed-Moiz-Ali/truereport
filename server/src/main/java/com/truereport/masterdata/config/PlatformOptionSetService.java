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
import com.truereport.shared.i18n.OptionLabelKeys;
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
    private final ContentLocalizer localizer;
    private final com.truereport.shared.i18n.RequestLanguageContext languageContext;
    private final com.truereport.shared.i18n.ContentAuthoring authoring;

    public PlatformOptionSetService(OptionSetRepository repository, FieldAuditService audit,
                                    TranslationGate translationGate,
                                    DynamicContentTranslations translations,
                                    ContentLocalizer localizer,
                                    com.truereport.shared.i18n.RequestLanguageContext languageContext,
                                    com.truereport.shared.i18n.ContentAuthoring authoring) {
        this.repository = repository;
        this.audit = audit;
        this.translationGate = translationGate;
        this.translations = translations;
        this.localizer = localizer;
        this.languageContext = languageContext;
        this.authoring = authoring;
    }

    @Transactional(readOnly = true)
    public List<OptionSetDto> list() {
        return localizer.optionSets(repository.findAll(), languageContext.activeLanguage());
    }

    @Transactional(readOnly = true)
    public OptionSetDto get(String id) {
        return localizer.optionSet(repository.findById(id).orElseThrow(ApiException::notFound),
                languageContext.activeLanguage());
    }

    @Transactional(readOnly = true)
    public List<OptionValueDto> values(String id) {
        repository.findById(id).orElseThrow(ApiException::notFound);
        return localizer.optionValues(repository.values(id), languageContext.activeLanguage());
    }

    @Transactional
    public OptionSetDto create(CurrentUser actor, OptionSetRequest request, HttpServletRequest http) {
        // Option sets (including catalogue sets) are backend-defined. The route
        // stays for contract compatibility but never writes a set.
        throw ApiException.unprocessable("OPTION_SET_BACKEND_DEFINED",
                "Option sets are backend-defined and cannot be created by clients");
    }

    @Transactional
    public OptionSetDto update(CurrentUser actor, String id, OptionSetRequest request,
                               HttpServletRequest http) {
        OptionSetDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        String name = request.translations() == null || request.translations().get("name") == null
                ? firstNonBlank(request.name(), request.nameEn()) : source(request.translations(), "name", firstNonBlank(request.name(), request.nameEn()));
        String targetStatus = normalizeStatus(request.status());
        if ("RETIRED".equals(targetStatus)) {
            throw ApiException.unprocessable("OPTION_SET_BACKEND_DEFINED",
                    "Option sets are backend-defined and cannot be retired by clients");
        }
        if (statusChangeToActive(existing.status(), targetStatus)) {
            translationGate.requireOverlaysApproved("OPTION_SET", id);
        }
        repository.update(id, name,
                overlays(request.translations(), "name", request.nameAr()),
                request.sortOrder(), targetStatus);
        OptionSetDto updated = repository.findById(id).orElse(existing);
        authoring.publish("OPTION_SET", id, Map.of("name", name == null ? updated.name() : name));
        audit.record(actor, "OPTION_SET_UPDATED", "OPTION_SET", id, existing, updated, null, http);
        return updated;
    }

    @Transactional
    public OptionSetDto retire(CurrentUser actor, String id, HttpServletRequest http) {
        repository.findById(id).orElseThrow(ApiException::notFound);
        throw ApiException.unprocessable("OPTION_SET_BACKEND_DEFINED",
                "Option sets are backend-defined and cannot be retired by clients");
    }

    @Transactional
    public OptionValueDto addValue(CurrentUser actor, String setId, OptionValueRequest request,
                                   HttpServletRequest http) {
        OptionSetDto set = repository.findById(setId).orElseThrow(ApiException::notFound);
        if (set.codeLocked()) {
            throw codesLocked();
        }
        translationGate.requireNewContentAllowed("Option value");
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
        String labelKey = resolveLabelKey(request.labelKey(), set.code(), code, null);
        OptionValueDto created = repository.insertValue(setId, code, label.trim(), labelKey,
                valueTranslations, request.sortOrder() == null ? 0 : request.sortOrder(),
                request.metadataJson(), allLiveProvided ? "ACTIVE" : "DRAFT");
        OptionValueDto result = repository.findValue(created.id()).orElse(created);
        authoring.publish("OPTION_VALUE", result.id(), Map.of("label", label.trim()));
        audit.record(actor, "OPTION_VALUE_CREATED", "OPTION_VALUE", result.id(), null, result, null, http);
        return result;
    }

    @Transactional
    public OptionValueDto updateValue(CurrentUser actor, String setId, String valueId,
                                      OptionValueUpdateRequest request, HttpServletRequest http) {
        OptionSetDto set = repository.findById(setId).orElseThrow(ApiException::notFound);
        OptionValueDto existing = repository.findValue(valueId).orElseThrow(ApiException::notFound);
        if (set.codeLocked() && request.status() != null && !request.status().isBlank()
                && !request.status().trim().equalsIgnoreCase(existing.status())) {
            throw codesLocked();
        }
        String label = request.translations() == null || request.translations().get("label") == null
                ? firstNonBlank(request.label(), request.labelEn()) : source(request.translations(), "label", firstNonBlank(request.label(), request.labelEn()));
        String targetStatus = normalizeStatus(request.status());
        if (statusChangeToActive(existing.status(), targetStatus)) {
            translationGate.requireOverlaysApproved("OPTION_VALUE", valueId);
        }
        String labelKey = resolveLabelKey(request.labelKey(), set.code(), existing.code(),
                existing.labelKey());
        repository.updateValue(valueId, label, labelKey,
                overlays(request.translations(), "label", request.labelAr()), request.sortOrder(),
                request.metadataJson(), targetStatus);
        OptionValueDto updated = repository.findValue(valueId).orElse(existing);
        authoring.publish("OPTION_VALUE", valueId,
                Map.of("label", label == null ? updated.label() : label));
        audit.record(actor, "OPTION_VALUE_UPDATED", "OPTION_VALUE", valueId, existing, updated, null, http);
        return updated;
    }

    @Transactional
    public OptionValueDto retireValue(CurrentUser actor, String setId, String valueId,
                                      String replacementCode, HttpServletRequest http) {
        OptionSetDto set = repository.findById(setId).orElseThrow(ApiException::notFound);
        if (set.codeLocked()) {
            throw codesLocked();
        }
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

    private static ApiException codesLocked() {
        return ApiException.unprocessable("OPTION_SET_CODES_LOCKED",
                "Codes are backend-defined for this option set");
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

    /**
     * An explicit key wins; otherwise an existing key is kept and a new value
     * gets the deterministic {@code option.<set>.<value>} convention.
     */
    private static String resolveLabelKey(String requested, String setCode, String valueCode,
                                          String current) {
        String explicit = blankToNull(requested);
        if (explicit != null) {
            if (!OptionLabelKeys.isValid(explicit)) {
                throw ApiException.validation("LABEL_KEY_INVALID",
                        "Option label key must be a dotted lowerCamel catalog key",
                        List.of(FieldIssue.of("labelKey", "INVALID",
                                "error.optionValue.labelKeyInvalid")));
            }
            return explicit;
        }
        String existing = blankToNull(current);
        return existing == null ? OptionLabelKeys.generate(setCode, valueCode) : existing;
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

