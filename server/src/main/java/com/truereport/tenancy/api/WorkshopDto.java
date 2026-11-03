package com.truereport.tenancy.api;

import java.util.UUID;

public record WorkshopDto(UUID id, String name, String status, long memberCount) {
}
