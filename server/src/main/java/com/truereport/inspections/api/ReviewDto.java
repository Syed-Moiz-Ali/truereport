package com.truereport.inspections.api;

import java.util.List;

public record ReviewDto(
        boolean ready,
        int completed,
        int total,
        List<ReviewIssueDto> blocking,
        List<ReviewIssueDto> warnings
) {
}
