package com.truereport.documents;

import com.truereport.documents.DocumentTypeDtos.CreateDocumentTypeRequest;
import com.truereport.documents.DocumentTypeDtos.DocumentTypeDto;
import com.truereport.documents.DocumentTypeDtos.UpdateDocumentTypeRequest;
import com.truereport.localization.DynamicContentTranslations;
import com.truereport.localization.TranslationGate;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class DocumentTypeService {

    private final DocumentTypeRepository repository;
    private final FieldAuditService audit;
    private final TranslationGate translationGate;
    private final DynamicContentTranslations translations;

    public DocumentTypeService(DocumentTypeRepository repository, FieldAuditService audit,
                               TranslationGate translationGate,
                               DynamicContentTranslations translations) {
        this.repository = repository;
        this.audit = audit;
        this.translationGate = translationGate;
        this.translations = translations;
    }

    @Transactional(readOnly = true)
    public List<DocumentTypeDto> list() {
        return repository.findAllOrdered();
    }

    @Transactional
    public DocumentTypeDto create(CurrentUser actor, CreateDocumentTypeRequest request,
                                  HttpServletRequest http) {
        translationGate.requireNewContentAllowed("Document type");
        if (request == null) {
            throw ApiException.validation("CODE_REQUIRED", "Code is required",
                    List.of(FieldIssue.of("code", "REQUIRED", "error.field.invalid")));
        }
        String code = requireCode(request.code());
        String name = translations.source(request.translations(), "name", request.name());
        if (name.isBlank() && request.nameEn() != null) {
            name = request.nameEn().trim();
        }
        translations.requireEnglishSource("name", name);
        if (repository.findByCode(code).isPresent()) {
            throw duplicateCode();
        }
        Map<String, Map<String, String>> fields = translations.mergeLegacy(
                request.translations(), legacy(request.nameAr()));
        boolean allLiveProvided = translationGate.translationProvidedForLive(fields, "name");
        DocumentTypeDto created = repository.insert(code, name.trim(), fields,
                Boolean.TRUE.equals(request.required()),
                request.sortOrder() == null ? 0 : request.sortOrder(),
                allLiveProvided ? "ACTIVE" : "DRAFT");
        DocumentTypeDto result = repository.findById(created.id()).orElse(created);
        audit.record(actor, "DOCUMENT_TYPE_CREATED", "DOCUMENT_TYPE", result.id(),
                null, result, null, http);
        return result;
    }

    @Transactional
    public DocumentTypeDto update(CurrentUser actor, String id, UpdateDocumentTypeRequest request,
                                  HttpServletRequest http) {
        DocumentTypeDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        String name = request == null ? null : translations.source(
                request.translations(), "name",
                request.name() == null || request.name().isBlank()
                        ? request.nameEn() : request.name());
        if (name != null && !name.isBlank()) {
            translations.requireEnglishSource("name", name);
        }
        Map<String, Map<String, String>> fields = request == null ? Map.of()
                : translations.mergeLegacy(request.translations(), legacy(request.nameAr()));
        Boolean required = request == null ? null : request.required();
        Integer sortOrder = request == null ? null : request.sortOrder();
        String status = request == null || request.active() == null
                ? null
                : (request.active() ? "ACTIVE" : "RETIRED");
        if ("ACTIVE".equals(status) && !"ACTIVE".equals(existing.status())) {
            translationGate.requireOverlaysApproved("DOCUMENT_TYPE", id,
                    com.truereport.localization.TranslationFieldRegistry.fieldsFor("DOCUMENT_TYPE"));
        }
        repository.update(id, name, fields, required, sortOrder, status);
        DocumentTypeDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "DOCUMENT_TYPE_UPDATED", "DOCUMENT_TYPE", id,
                existing, updated, null, http);
        return updated;
    }

    @Transactional
    public DocumentTypeDto retire(CurrentUser actor, String id, HttpServletRequest http) {
        DocumentTypeDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        repository.retire(id);
        DocumentTypeDto updated = repository.findById(id).orElse(existing);
        audit.record(actor, "DOCUMENT_TYPE_RETIRED", "DOCUMENT_TYPE", id,
                existing, updated, null, http);
        return updated;
    }

    @Transactional
    public List<DocumentTypeDto> reorder(List<String> orderedIds) {
        return reorder(null, orderedIds, null);
    }

    @Transactional
    public List<DocumentTypeDto> reorder(CurrentUser actor, List<String> orderedIds,
                                         HttpServletRequest http) {
        repository.reorder(orderedIds == null ? List.of() : orderedIds);
        List<DocumentTypeDto> updated = repository.findAllOrdered();
        audit.record(actor, "DOCUMENT_TYPE_REORDERED", "DOCUMENT_TYPE", null,
                null, updated, null, http);
        return updated;
    }

    private static Map<String, String> legacy(String nameAr) {
        return nameAr == null || nameAr.isBlank() ? Map.of() : Map.of("name", nameAr);
    }

    private static String requireCode(String code) {
        if (code == null || code.isBlank()) {
            throw ApiException.validation("CODE_REQUIRED", "Code is required",
                    List.of(FieldIssue.of("code", "REQUIRED", "error.field.invalid")));
        }
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private static ApiException duplicateCode() {
        return new ApiException(HttpStatus.CONFLICT, "DOCUMENT_TYPE_EXISTS",
                "error.documentType.code", "Document type code already exists.");
    }
}
