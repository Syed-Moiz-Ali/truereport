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
            @com.fasterxml.jackson.annotation.JsonInclude(
                    com.fasterxml.jackson.annotation.JsonInclude.Include.ALWAYS)
            String errorMessage,
            String startedAt,
            String finishedAt) {
    }
}
