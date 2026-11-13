package com.truereport.masterdata.api;

import jakarta.validation.constraints.Size;

import java.util.Map;

public record CategoryRequest(
        @Size(max = 80) String slug,
        @Size(max = 200) String name,
        @Size(max = 200) String labelEn,
        @Size(max = 200) String labelAr,
        Integer sortOrder,
        String status,
        @Size(max = 80) String code,
        @Size(max = 200) String nameEn,
        @Size(max = 200) String nameAr,
        Boolean active,
        Map<String, Map<String, String>> translations
) {
    public CategoryRequest(String slug, String labelEn, String labelAr, Integer sortOrder,
                           String status) {
        this(slug, null, labelEn, labelAr, sortOrder, status, null, null, null, null, null);
    }
}
