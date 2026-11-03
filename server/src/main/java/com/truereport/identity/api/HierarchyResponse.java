package com.truereport.identity.api;

import java.util.List;

public record HierarchyResponse(
        List<HierarchyWorkshopDto> workshops,
        int totalWorkshops,
        int totalAccounts
) {
}
