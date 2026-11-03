package com.truereport.inspections.api;

import java.util.List;

public record FinalizeResponse(
        String jobId,
        String status,
        String finalizedAt,
        String snapshotHash,
        int itemCount,
        List<String> warnings
) {
}
