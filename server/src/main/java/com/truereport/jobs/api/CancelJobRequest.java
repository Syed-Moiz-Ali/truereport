package com.truereport.jobs.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CancelJobRequest(
        @NotBlank @Size(max = 255) String reason
) {
}
