package com.truereport.masterdata.api;

import java.util.List;
import java.util.UUID;

public record DropdownDto(UUID id, String code, String status, int sortOrder,
                          String labelEn, String labelAr, List<DropdownValueDto> values) {
}
