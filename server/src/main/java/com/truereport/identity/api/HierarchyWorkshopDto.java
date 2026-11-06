package com.truereport.identity.api;

import java.util.List;
import java.util.UUID;

public record HierarchyWorkshopDto(
        UUID id,
        String name,
        String branchName,
        String status,
        long memberCount,
        List<PlatformAccountDto> admins,
        List<PlatformAccountDto> technicians
) {
}
