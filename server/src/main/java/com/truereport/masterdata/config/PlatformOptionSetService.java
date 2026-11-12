package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueRequest;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueUpdateRequest;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.localization.TranslationGate;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

@Service
public class PlatformOptionSetService {

    private final OptionSetRepository repository;
    private final FieldAuditService audit;
    private final TranslationGate translationGate;

    public PlatformOptionSetService(OptionSetRepository repository, FieldAuditService audit,
                                    TranslationGate translationGate) {
        this.repository = repository;
        this.audit = audit;
        this.translationGate = translationGate;
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
        requireBilingual("name", request.nameEn(), request.nameAr());
        if (repository.findByCode(code).isPresent()) {
            throw ApiException.conflict("OPTION_SET_EXISTS", "Option set code already exists");
        }
        OptionSetDto created = repository.insert(code, request.nameEn().trim(), request.nameAr().trim(),
                request.sortOrder() == null ? 0 : request.sortOrder());
        audit.record(actor, "OPTION_SET_CREATED", "OPTION_SET", created.id(), null, created, null, http);
        return created;
    }

    @Transactional
    public OptionSetDto update(CurrentUser actor, String id, OptionSetRequest request,
                               HttpServletRequest http) {
        OptionSetDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        repository.update(id, request.nameEn(), request.nameAr(), request.sortOrder());
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
        requireBilingual("label", request.labelEn(), request.labelAr());
        if (repository.findValueByCode(setId, code).isPresent()) {
            throw ApiException.conflict("OPTION_VALUE_EXISTS", "Option value code already exists");
        }
        OptionValueDto created = repository.insertValue(setId, code, request.labelEn().trim(),
                request.labelAr().trim(), request.sortOrder() == null ? 0 : request.sortOrder(),
                request.metadataJson());
        audit.record(actor, "OPTION_VALUE_CREATED", "OPTION_VALUE", created.id(), null, created, null, http);
        return created;
    }

    @Transactional
    public OptionValueDto updateValue(CurrentUser actor, String setId, String valueId,
                                      OptionValueUpdateRequest request, HttpServletRequest http) {
        repository.findById(setId).orElseThrow(ApiException::notFound);
        OptionValueDto existing = repository.findValue(valueId).orElseThrow(ApiException::notFound);
        repository.updateValue(valueId, request.labelEn(), request.labelAr(), request.sortOrder(),
                request.metadataJson());
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

    private static String requireCode(String code) {
        if (code == null || code.isBlank()) {
            throw ApiException.validation("CODE_REQUIRED", "Code is required",
                    List.of(FieldIssue.of("code", "REQUIRED", "error.field.invalid")));
        }
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private static void requireBilingual(String field, String en, String ar) {
        List<FieldIssue> issues = new java.util.ArrayList<>();
        if (en == null || en.isBlank()) {
            issues.add(FieldIssue.of(field + "En", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (ar == null || ar.isBlank()) {
            issues.add(FieldIssue.of(field + "Ar", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("TRANSLATION_REQUIRED", "English and Arabic are required", issues);
        }
    }
}
