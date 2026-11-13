package com.truereport.masterdata.api;

import java.util.Map;
import java.util.UUID;

public record GuideImageDto(UUID id, String status, String mime, long bytes,
                            String licenceNote, String alt, String contentUrl,
                            Map<String, Map<String, String>> translations,
                            String altEn, String altAr) {
}
