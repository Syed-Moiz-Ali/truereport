package com.truereport.masterdata.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CatalogItemRequest(
        @NotBlank @Size(max = 60) String code,
        @NotBlank @Size(max = 200) String labelEn,
        @NotBlank @Size(max = 200) String labelAr,
        Integer sortOrder
) {
}
