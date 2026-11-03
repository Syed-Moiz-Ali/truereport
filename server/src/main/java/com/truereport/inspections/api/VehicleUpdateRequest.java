package com.truereport.inspections.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record VehicleUpdateRequest(
        @NotBlank @Size(max = 100) String vehicleMake,
        @NotBlank @Size(max = 100) String vehicleModel,
        Integer vehicleYear,
        @Size(max = 40) String vehicleVin,
        @Size(max = 40) String vehiclePlate,
        Integer odometerValue,
        String odometerUnit
) {
}
