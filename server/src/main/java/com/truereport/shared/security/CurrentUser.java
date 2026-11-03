package com.truereport.shared.security;

import java.util.UUID;

public record CurrentUser(UUID userId, String email, String role, UUID workshopId, UUID sessionId) {

    public boolean isPlatformAdmin() {
        return "PLATFORM_ADMIN".equals(role);
    }

    public boolean isWorkshopAdmin() {
        return "WORKSHOP_ADMIN".equals(role);
    }

    public boolean isTechnician() {
        return "TECHNICIAN".equals(role);
    }
}
