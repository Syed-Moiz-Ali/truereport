package com.truereport.masterdata.api;

import java.math.BigDecimal;
import java.util.UUID;

public record CategoryDto(UUID id, String slug, String status, int sortOrder,
                          String labelEn, String labelAr, long itemCount,
                          String code, BigDecimal weightPercentage, boolean active) {
}
