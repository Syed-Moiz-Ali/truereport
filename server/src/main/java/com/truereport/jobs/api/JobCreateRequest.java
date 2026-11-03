package com.truereport.jobs.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record JobCreateRequest(
        @NotNull UUID templateVersionId,
        String scheduledAt,
        @NotBlank @Size(max = 200) String customerName,
        @Size(max = 40) String customerPhone,
        @Email @Size(max = 320) String customerEmail,
        @NotBlank @Size(max = 100) String vehicleMake,
        @NotBlank @Size(max = 100) String vehicleModel,
        Integer vehicleYear,
        @Size(max = 40) String vehicleVin,
        @Size(max = 40) String vehiclePlate,
        @NotBlank @Size(max = 500) String scope
) {
}
