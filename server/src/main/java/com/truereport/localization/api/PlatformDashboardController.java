package com.truereport.localization.api;

import com.truereport.localization.PlatformDashboardService;
import com.truereport.localization.api.PlatformDashboardDtos.PlatformDashboardDto;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/platform/dashboard")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformDashboardController {

    private final PlatformDashboardService dashboard;

    public PlatformDashboardController(PlatformDashboardService dashboard) {
        this.dashboard = dashboard;
    }

    @GetMapping
    public PlatformDashboardDto dashboard(@RequestParam(defaultValue = "14") int days) {
        return dashboard.dashboard(days);
    }
}
