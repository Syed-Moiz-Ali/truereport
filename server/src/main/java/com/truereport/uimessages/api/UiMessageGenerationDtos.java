package com.truereport.uimessages.api;

import java.util.List;

public final class UiMessageGenerationDtos {

    private UiMessageGenerationDtos() {
    }

    public record GenerateUiMessagesRequest(Boolean force, String reviewStatus) {
    }

    public record UiMessageGenerationDto(
            String language,
            String jobId,
            String jobStatus,
            String status,
            String path,
            int keysTranslated,
            List<String> failedKeys,
            int totalKeys,
            int completedKeys,
            String error,
            String startedAt,
            String finishedAt) {
    }
}
