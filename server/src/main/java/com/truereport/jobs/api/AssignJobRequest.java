package com.truereport.jobs.api;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record AssignJobRequest(
        @NotNull UUID technicianId,
        @Size(max = 255) String reason
) {
}
