package com.truereport.masterdata.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CategoryRequest(
        @NotBlank @Size(max = 80) String slug,
        @NotBlank @Size(max = 200) String labelEn,
        @NotBlank @Size(max = 200) String labelAr,
        Integer sortOrder,
        String status
) {
}
