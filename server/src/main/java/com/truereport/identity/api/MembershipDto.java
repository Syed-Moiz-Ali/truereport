package com.truereport.identity.api;

import java.util.UUID;

public record MembershipDto(UUID workshopId, String workshopName, String role) {
}
