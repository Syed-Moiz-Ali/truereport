package com.truereport.masterdata.api;

import java.util.List;
import java.util.Map;

public record ItemDetailDto(ItemSummaryDto item, List<ItemVersionDto> versions,
                            Map<String, String> translationFields) {
}
