package com.truereport.inspections.api;

import java.util.UUID;

public record EquipmentItemDto(UUID equipmentId, String code, String labelEn, String labelAr,
                               String status, int sortOrder) {
}
