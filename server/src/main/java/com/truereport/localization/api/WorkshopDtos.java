package com.truereport.localization.api;

import java.util.UUID;

/**
 * Platform workshop JSON shape. Field-for-field identical to the workshop
 * DTO served by the tenancy module; duplicated here because Spring Modulith
 * does not expose the tenancy API package to other modules.
 */
public final class WorkshopDtos {

    private WorkshopDtos() {
    }

    public record WorkshopDto(UUID id, String name, String status, long memberCount) {
    }
}
