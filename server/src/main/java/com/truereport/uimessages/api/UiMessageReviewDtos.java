package com.truereport.uimessages.api;

import java.util.List;
import java.util.Map;

public final class UiMessageReviewDtos {

    private UiMessageReviewDtos() {
    }

    public record ReviewEntryDto(
            String key,
            String sourceText,
            String targetText,
            boolean changed,
            boolean missing,
            boolean untranslated,
            boolean placeholderMismatch) {
    }

    public record ReviewResponseDto(
            String language,
            String status,
            String path,
            int totalKeys,
            int changedKeys,
            int missingKeys,
            List<ReviewEntryDto> entries) {
    }

    public record ReviewEntryInput(String key, String targetText) {
    }

    public record SaveReviewRequest(
            List<ReviewEntryInput> entries,
            Map<String, String> translations) {
    }

    public record ApproveReviewResponseDto(
            String language,
            String status,
            String path,
            String hash,
            int totalKeys) {
    }
}
