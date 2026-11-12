package com.truereport.seed;

import com.truereport.seed.DefaultChecklistSeeder.SeedResult;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/platform/seed")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformSeedController {

    private final DefaultChecklistSeeder seeder;

    public PlatformSeedController(DefaultChecklistSeeder seeder) {
        this.seeder = seeder;
    }

    @PostMapping("/default-checklist")
    public SeedResult seedDefaultChecklist() {
        return seeder.seedDefaultChecklist();
    }
}
