package com.truereport.inspections.api;

import java.util.List;
import java.util.UUID;

public record EquipmentListDto(List<UUID> equipmentIds) {
}
