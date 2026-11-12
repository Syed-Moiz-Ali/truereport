package com.truereport.localization.api;

import com.truereport.localization.PlatformOverviewService;
import com.truereport.localization.api.OverviewDtos.OverviewDto;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/platform/overview")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformOverviewController {

    private final PlatformOverviewService overview;

    public PlatformOverviewController(PlatformOverviewService overview) {
        this.overview = overview;
    }

    @GetMapping
    public OverviewDto overview() {
        return overview.overview();
    }
}
