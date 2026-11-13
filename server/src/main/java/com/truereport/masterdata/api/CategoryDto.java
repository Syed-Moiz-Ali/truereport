package com.truereport.masterdata.api;

import java.util.Map;
import java.util.UUID;

/**
 * Platform content category. The source language is a plain {@code name};
 * other languages are returned in {@code translations.name}.
 * {@code nameEn}/{@code nameAr} are derived compatibility fields for older
 * clients and must not be treated as storage.
 */
public record CategoryDto(UUID id, String slug, String status, int sortOrder,
                          String name, long itemCount, String code, boolean active,
                          Map<String, Map<String, String>> translations,
                          String nameEn, String nameAr) {
}
