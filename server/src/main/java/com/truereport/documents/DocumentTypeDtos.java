package com.truereport.documents;

import java.util.List;
import java.util.Map;

public final class DocumentTypeDtos {

    private DocumentTypeDtos() {
    }

    public record DocumentTypeDto(
            String id,
            String code,
            String name,
            String status,
            boolean required,
            int sortOrder,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr
    ) {
    }

    public record CreateDocumentTypeRequest(
            String code,
            String name,
            Boolean required,
            Integer sortOrder,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr
    ) {
    }

    public record UpdateDocumentTypeRequest(
            String name,
            Boolean required,
            Integer sortOrder,
            Boolean active,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr
    ) {
    }

    public record ReorderDocumentTypesRequest(List<String> orderedIds) {
    }
}
