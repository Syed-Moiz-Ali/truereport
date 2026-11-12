package com.truereport.masterdata.api;

import jakarta.validation.constraints.Size;

public record CategoryRequest(
        @Size(max = 80) String slug,
        @Size(max = 200) String labelEn,
        @Size(max = 200) String labelAr,
        Integer sortOrder,
        String status,
        @Size(max = 80) String code,
        @Size(max = 200) String nameEn,
        @Size(max = 200) String nameAr,
        Boolean active
) {
    public CategoryRequest(String slug, String labelEn, String labelAr, Integer sortOrder,
                           String status) {
        this(slug, labelEn, labelAr, sortOrder, status, null, null, null, null);
    }
}
