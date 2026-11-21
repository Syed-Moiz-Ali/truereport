package com.truereport.localization.api;

import java.util.List;
import java.util.Map;

public final class LanguageDtos {

    private LanguageDtos() {
    }

    public record LanguageDto(
            String code,
            String nativeName,
            String direction,
            boolean active,
            boolean isDefault,
            int sortOrder,
            String status
    ) {
        /**
         * Display name rule: native name first, then the code. Arabic is not
         * special; every manifest language follows the same rule.
         */
        public String displayName() {
            return nativeName == null || nativeName.isBlank() ? code : nativeName;
        }
    }

    public record SetLanguageRequest(String language) {
    }

    /**
     * Platform Admin language creation. {@code code} is normalized to lower
     * case; {@code direction} defaults to {@code ltr}.
     */
    public record CreateLanguageRequest(String code, String nativeName, String direction) {
    }

    public record UpsertTranslationRequest(
            String entityType,
            String entityId,
            String field,
            String language,
            String text,
            String status
    ) {
    }

    public record TranslationItemDto(
            String entityType,
            String entityId,
            String entityCode,
            String field,
            String defaultText,
            @com.fasterxml.jackson.annotation.JsonInclude(
                    com.fasterxml.jackson.annotation.JsonInclude.Include.ALWAYS)
            String text,
            String status,
            String contentStatus
    ) {
    }

    public record BacklogGroupDto(
            String entityType,
            int total,
            int approved,
            java.util.List<TranslationItemDto> items
    ) {
    }

    public record LanguageBacklogDto(
            LanguageRefDto language,
            int totalRequired,
            int approvedCount,
            int coveragePercent,
            java.util.List<BacklogGroupDto> groups
    ) {
    }

    public record LanguageRefDto(String code, String status) {
    }

    public record EntityCoverageDto(int total, int approved) {
    }

    public record LanguageCoverageDto(
            String language,
            int totalRequired,
            int approvedCount,
            int coveragePercent,
            java.util.Map<String, EntityCoverageDto> byEntity
    ) {
    }

    public record MeLanguageDto(String language, String direction, String fallback) {
    }

    public record CoverageNamespace(int total, List<String> missing) {
    }

    public record TranslationCoverageDto(List<String> languages,
                                         Map<String, CoverageNamespace> namespaces) {
    }

    public record UiMessageCoverageDto(
            int total,
            int approved,
            int missing,
            int changed,
            String path,
            String generationStatus
    ) {
    }

    public record ReadinessBlockerDto(String code, String tab, int count, String message) {
    }

    public record LanguageReadinessDto(
            String language,
            String status,
            String nativeName,
            String direction,
            boolean isDefault,
            String uiMessagesPath,
            int readinessPercent,
            UiMessageCoverageDto uiMessages,
            Map<String, EntityCoverageDto> content,
            List<ReadinessBlockerDto> blockers
    ) {
    }
}
