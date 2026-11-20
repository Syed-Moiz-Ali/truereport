package com.truereport.dev;

import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.jobs.WorkshopJobAdminService;
import com.truereport.jobs.api.WorkshopJobDtos.CreateJobRequest;
import com.truereport.seed.DefaultChecklistSeeder;
import com.truereport.shared.security.CurrentUser;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Development-only demo data: the approved 30-point checklist plus a few jobs
 * with different lifecycle states so the Workshop/Technician screens have
 * realistic content on a fresh database. Disabled unless the dev seed flag is
 * on, and idempotent: it only runs when the workshop has no jobs.
 */
@Component
@Profile("dev")
public class DemoDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoDataSeeder.class);

    private final boolean enabled;
    private final DefaultChecklistSeeder checklist;
    private final WorkshopJobAdminService jobs;
    private final UserRepository users;
    private final WorkshopMembershipRepository memberships;
    private final JdbcTemplate jdbc;

    public DemoDataSeeder(
            @Value("${truereport.dev.seed-enabled:false}") boolean enabled,
            DefaultChecklistSeeder checklist,
            WorkshopJobAdminService jobs,
            UserRepository users,
            WorkshopMembershipRepository memberships,
            JdbcTemplate jdbc) {
        this.enabled = enabled;
        this.checklist = checklist;
        this.jobs = jobs;
        this.users = users;
        this.memberships = memberships;
        this.jdbc = jdbc;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }
        User admin = users.findByEmailNormalized("admin.a@truereport.test").orElse(null);
        if (admin == null) {
            return;
        }
        WorkshopMembership membership = memberships
                .findFirstByUserIdAndStatusAndPrimaryTrue(admin.getId(), "ACTIVE")
                .orElse(null);
        if (membership == null) {
            return;
        }
        String workshopId = membership.getWorkshopId().toString();
        Integer existing = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_jobs WHERE workshop_id = ?", Integer.class, workshopId);
        if (existing != null && existing > 0) {
            return;
        }

        checklist.seedDefaultChecklist();
        CurrentUser actor = new CurrentUser(admin.getId(), admin.getEmail(), "WORKSHOP_ADMIN",
                membership.getWorkshopId(), null);
        var templates = jobs.availableTemplates(actor);
        if (templates.isEmpty()) {
            log.warn("Demo data skipped: no published template is available");
            return;
        }
        String templateId = templates.get(0).versionId();
        String technicianId = memberships
                .findByWorkshopIdAndStatusOrderByRoleAsc(membership.getWorkshopId(), "ACTIVE")
                .stream()
                .filter(member -> member.getRole() == com.truereport.tenancy.WorkshopRole.TECHNICIAN)
                .map(member -> member.getUserId().toString())
                .findFirst().orElse(null);

        create(actor, templateId, technicianId, "Demo — Ahmed Al Mansouri",
                "+971501000001", "P7-2024-0001", "Toyota", "Land Cruiser",
                2023, "DXB-1001", 42850, null);
        create(actor, templateId, null, "Demo — Sara Al Hashimi",
                "+971501000002", "P7-2024-0002", "Nissan", "Patrol",
                2022, "DXB-1002", 76500, "2030-01-15T09:00:00");
        create(actor, templateId, null, "Demo — Omar Al Suwaidi",
                "+971501000003", "P7-2024-0003", "Ford", "Explorer",
                2021, "DXB-1003", 103200, null);
        log.info("Development demo data created: 3 jobs for Workshop A");
    }

    private void create(CurrentUser actor, String templateId, String technicianId, String name,
                        String phone, String vin, String make, String model, Integer year,
                        String plate, Integer odometer, String scheduledAt) {
        try {
            jobs.create(actor, new CreateJobRequest(
                    templateId, name, phone, null, vin, make, model, year, plate,
                    odometer, "KM", "AUTOMATIC", "PETROL", "en", scheduledAt,
                    technicianId, true), "demo-" + vin);
        } catch (RuntimeException exception) {
            log.warn("Demo job {} skipped: {}", vin, exception.getMessage());
        }
    }
}
