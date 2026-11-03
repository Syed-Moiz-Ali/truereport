package com.truereport.jobs.api;

import java.util.UUID;

public record JobDto(
        UUID id,
        String reference,
        String status,
        int version,
        UUID templateVersionId,
        String templateName,
        Integer templateVersionNo,
        UUID assignedTechnicianId,
        String assignedTechnicianName,
        String scheduledAt,
        String customerName,
        String customerPhone,
        String customerEmail,
        String vehicleMake,
        String vehicleModel,
        Integer vehicleYear,
        String vehicleVin,
        String vehiclePlate,
        String vehicleType,
        Integer odometerValue,
        String odometerUnit,
        String scope,
        String startedAt,
        String readyAt,
        String finalizedAt,
        String createdAt,
        String updatedAt
) {
}
