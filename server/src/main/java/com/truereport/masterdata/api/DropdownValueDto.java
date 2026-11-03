package com.truereport.masterdata.api;

import java.util.UUID;

public record DropdownValueDto(UUID id, String code, String status, int sortOrder,
                               String labelEn, String labelAr) {
}
