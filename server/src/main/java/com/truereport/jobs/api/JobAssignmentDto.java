package com.truereport.jobs.api;

import java.util.UUID;

public record JobAssignmentDto(
        UUID id,
        UUID technicianId,
        UUID assignedBy,
        String assignedAt,
        String unassignedAt,
        String reason
) {
}
