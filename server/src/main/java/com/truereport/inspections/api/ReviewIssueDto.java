package com.truereport.inspections.api;

import java.util.List;
import java.util.UUID;

public record ReviewIssueDto(
        String code,
        UUID inspectionItemId,
        String label,
        String detail
) {
}
