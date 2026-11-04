package com.truereport.jobs;

public record InspectionFinalizedEvent(
        InspectionJob job,
        String finalSnapshotJson,
        byte[] finalSnapshotHash
) {
}
