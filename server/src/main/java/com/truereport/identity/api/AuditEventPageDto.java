package com.truereport.identity.api;

import java.util.List;

public record AuditEventPageDto(
        List<AuditEventDto> items,
        long total,
        int page,
        int size) {
}
