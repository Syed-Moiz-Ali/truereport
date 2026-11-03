package com.truereport.identity.api;

import java.util.List;

public record MeResponse(UserDto user, List<MembershipDto> memberships) {
}
