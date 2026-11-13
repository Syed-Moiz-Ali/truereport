package com.truereport.localization.api;

import java.util.List;

public final class ContentGenerationDtos {

    private ContentGenerationDtos() {
    }

    public record GenerateContentRequest(List<String> entityTypes, Boolean force) {
    }

    public record ContentGenerationDto(
            String language,
            String jobId,
            String jobStatus,
            List<String> entityTypes,
            int totalKeys,
            int translatedKeys,
            List<String> failedKeys,
            String status,
            String error,
            String startedAt,
            String finishedAt) {
    }
}
