package com.truereport.localization.api;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;


public final class ContentTranslationDtos {

    private ContentTranslationDtos() {
    }

    /**
     * A language that the content review queue can actually be filtered by:
     * declared in the UI manifest and present in {@code content_translation}.
     */
    public record PlatformLanguageDto(String code, String name, String nativeName,
                                      String direction, int sortOrder) {
    }

    public record CoverageItemDto(String entityType, String field, int total, int translated,
                                  int missing, int stale, int pendingReview, int blocked,
                                  boolean safetyCritical) {
    }

    public record TranslationBodyRequest(String body) {
    }

    public record TranslationDto(String entityType, String entityId, String field, String lang,
                                 String body, String origin, String status, String sourceLang,
                                 String sourceHash, String provider) {
    }

    /**
     * One canonical text unit plus the target-language row when it exists.
     * {@code text}, {@code status} and {@code origin} are {@code null} while the
     * language has no usable translation for the unit.
     */
    @JsonInclude(JsonInclude.Include.ALWAYS)
    public record ContentUnitDto(String entityType, String entityId, String field,
                                 String sourceText, String text, String status, String origin,
                                 boolean safetyCritical) {
    }

    public record ContentUnitsPageDto(String lang, int total, int page, int size,
                                      List<ContentUnitDto> items) {
    }
}
