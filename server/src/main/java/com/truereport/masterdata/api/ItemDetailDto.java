package com.truereport.masterdata.api;

import java.util.List;

public record ItemDetailDto(ItemSummaryDto item, List<ItemVersionDto> versions) {
}
