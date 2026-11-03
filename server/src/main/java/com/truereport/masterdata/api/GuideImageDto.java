package com.truereport.masterdata.api;

import java.util.UUID;

public record GuideImageDto(UUID id, String status, String mime, long bytes,
                            String licenceNote, String altEn, String altAr, String contentUrl) {
}
