package com.truereport.identity;

import com.truereport.identity.api.StaffDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.tenancy.WorkshopMembershipRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

@Service
public class StaffService {

    private final WorkshopMembershipRepository memberships;
    private final UserRepository users;

    public StaffService(WorkshopMembershipRepository memberships, UserRepository users) {
        this.memberships = memberships;
        this.users = users;
    }

    @Transactional(readOnly = true)
    public List<StaffDto> staff(CurrentUser caller) {
        if (!caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.forbidden();
        }
        return memberships.findByWorkshopIdAndStatusOrderByRoleAsc(caller.workshopId(), "ACTIVE").stream()
                .map(membership -> {
                    User user = users.findById(membership.getUserId()).orElse(null);
                    if (user == null) {
                        return null;
                    }
                    return new StaffDto(user.getId(), user.getDisplayName(), maskEmail(user.getEmail()),
                            membership.getRole().name(), membership.getStatus());
                })
                .filter(Objects::nonNull)
                .toList();
    }

    static String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return "***" + (at >= 0 ? email.substring(at) : "");
        }
        return email.charAt(0) + "***" + email.substring(at);
    }
}
