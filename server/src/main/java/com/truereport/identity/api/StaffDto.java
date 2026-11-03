package com.truereport.identity.api;

import java.util.UUID;

public record StaffDto(UUID userId, String displayName, String emailMasked, String role, String status) {
}
