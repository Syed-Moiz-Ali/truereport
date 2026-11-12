package com.truereport.documents;

import com.truereport.documents.DocumentTypeDtos.CreateDocumentTypeRequest;
import com.truereport.documents.DocumentTypeDtos.DocumentTypeDto;
import com.truereport.documents.DocumentTypeDtos.ReorderDocumentTypesRequest;
import com.truereport.documents.DocumentTypeDtos.UpdateDocumentTypeRequest;
import com.truereport.shared.security.CurrentUserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/platform/document-types")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformDocumentTypeController {

    private final DocumentTypeService documentTypeService;
    private final CurrentUserService currentUserService;

    public PlatformDocumentTypeController(DocumentTypeService documentTypeService,
                                          CurrentUserService currentUserService) {
        this.documentTypeService = documentTypeService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public List<DocumentTypeDto> list() {
        return documentTypeService.list();
    }

    @PostMapping
    public ResponseEntity<DocumentTypeDto> create(JwtAuthenticationToken authentication,
                                                  @RequestBody CreateDocumentTypeRequest request,
                                                  HttpServletRequest http) {
        DocumentTypeDto created = documentTypeService.create(
                currentUserService.require(authentication), request, http);
        return ResponseEntity.status(201).body(created);
    }

    @PutMapping("/{id}")
    public DocumentTypeDto update(JwtAuthenticationToken authentication,
                                  @PathVariable String id,
                                  @RequestBody UpdateDocumentTypeRequest request,
                                  HttpServletRequest http) {
        return documentTypeService.update(currentUserService.require(authentication), id, request, http);
    }

    @PostMapping("/{id}/retire")
    public DocumentTypeDto retire(JwtAuthenticationToken authentication,
                                  @PathVariable String id,
                                  HttpServletRequest http) {
        return documentTypeService.retire(currentUserService.require(authentication), id, http);
    }

    @PutMapping("/reorder")
    public List<DocumentTypeDto> reorder(JwtAuthenticationToken authentication,
                                         @RequestBody(required = false) ReorderDocumentTypesRequest request,
                                         HttpServletRequest http) {
        List<String> orderedIds = request == null ? List.of() : request.orderedIds();
        return documentTypeService.reorder(currentUserService.require(authentication), orderedIds, http);
    }
}
