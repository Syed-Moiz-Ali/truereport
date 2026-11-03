package com.truereport.identity.api;

import com.truereport.identity.StaffService;
import com.truereport.shared.security.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/workshop")
public class StaffController {

    private final StaffService staffService;
    private final CurrentUserService currentUserService;

    public StaffController(StaffService staffService, CurrentUserService currentUserService) {
        this.staffService = staffService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/staff")
    @PreAuthorize("hasRole('WORKSHOP_ADMIN')")
    public List<StaffDto> staff(JwtAuthenticationToken authentication) {
        return staffService.staff(currentUserService.require(authentication));
    }
}
