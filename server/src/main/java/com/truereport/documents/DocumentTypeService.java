package com.truereport.documents;

import com.truereport.documents.DocumentTypeDtos.CreateDocumentTypeRequest;
import com.truereport.documents.DocumentTypeDtos.DocumentTypeDto;
import com.truereport.documents.DocumentTypeDtos.UpdateDocumentTypeRequest;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.localization.TranslationGate;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class DocumentTypeService {

    private final DocumentTypeRepository repository;
    private final FieldAuditService audit;
    private final TranslationGate translationGate;

    public DocumentTypeService(DocumentTypeRepository repository, FieldAuditService audit,
                               TranslationGate translationGate) {
        this.repository = repository;
        this.audit = audit;
        this.translationGate = translationGate;
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
        requireBilingual(request.nameEn(), request.nameAr());
        if (repository.findByCode(code).isPresent()) {
            throw duplicateCode();
        }
        DocumentTypeDto created = repository.insert(code, request.nameEn().trim(),
                request.nameAr().trim(), Boolean.TRUE.equals(request.required()),
                request.sortOrder() == null ? 0 : request.sortOrder());
        audit.record(actor, "DOCUMENT_TYPE_CREATED", "DOCUMENT_TYPE", created.id(),
                null, created, null, http);
        return created;
    }

    @Transactional
    public DocumentTypeDto update(CurrentUser actor, String id, UpdateDocumentTypeRequest request,
                                  HttpServletRequest http) {
        DocumentTypeDto existing = repository.findById(id).orElseThrow(ApiException::notFound);
        String nameEn = request == null || request.nameEn() == null
                ? existing.nameEn()
                : request.nameEn().trim();
        String nameAr = request == null || request.nameAr() == null
                ? existing.nameAr()
                : request.nameAr().trim();
        requireBilingual(nameEn, nameAr);

        Boolean required = request == null ? null : request.required();
        Integer sortOrder = request == null ? null : request.sortOrder();
        String status = request == null || request.active() == null
                ? null
                : (request.active() ? "ACTIVE" : "RETIRED");

        repository.update(id, nameEn, nameAr, required, sortOrder, status);
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

    private static String requireCode(String code) {
        if (code == null || code.isBlank()) {
            throw ApiException.validation("CODE_REQUIRED", "Code is required",
                    List.of(FieldIssue.of("code", "REQUIRED", "error.field.invalid")));
        }
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private static void requireBilingual(String nameEn, String nameAr) {
        List<FieldIssue> issues = new ArrayList<>();
        if (nameEn == null || nameEn.isBlank()) {
            issues.add(FieldIssue.of("nameEn", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (nameAr == null || nameAr.isBlank()) {
            issues.add(FieldIssue.of("nameAr", "TRANSLATION_REQUIRED", "error.translation.required"));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "English and Arabic are required", issues);
        }
    }

    private static ApiException duplicateCode() {
        return new ApiException(HttpStatus.CONFLICT, "DOCUMENT_TYPE_EXISTS",
                "error.documentType.code", "Document type code already exists.");
    }
}
