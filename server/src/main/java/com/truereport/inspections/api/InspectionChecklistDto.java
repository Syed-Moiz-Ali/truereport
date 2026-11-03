package com.truereport.inspections.api;

import com.truereport.jobs.api.JobDto;

import java.util.List;

public record InspectionChecklistDto(
        JobDto job,
        List<InspectionItemDto> items,
        int completed,
        int total
) {
}
