package com.truereport.reports.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RevokeLinkRequest(
        @NotBlank @Size(max = 60) String reasonCode,
        @Size(max = 500) String note
) {
}
