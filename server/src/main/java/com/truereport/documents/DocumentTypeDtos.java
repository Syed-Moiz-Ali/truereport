package com.truereport.documents;

import java.util.List;

public final class DocumentTypeDtos {

    private DocumentTypeDtos() {
    }

    public record DocumentTypeDto(
            String id,
            String code,
            String nameEn,
            String nameAr,
            String status,
            boolean required,
            int sortOrder
    ) {
    }

    public record CreateDocumentTypeRequest(
            String code,
            String nameEn,
            String nameAr,
            Boolean required,
            Integer sortOrder
    ) {
    }

    public record UpdateDocumentTypeRequest(
            String nameEn,
            String nameAr,
            Boolean required,
            Integer sortOrder,
            Boolean active
    ) {
    }

    public record ReorderDocumentTypesRequest(List<String> orderedIds) {
    }
}
