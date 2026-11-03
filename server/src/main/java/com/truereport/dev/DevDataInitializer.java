package com.truereport.dev;

import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.identity.UserStatus;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.tenancy.WorkshopRole;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@Profile("dev")
public class DevDataInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevDataInitializer.class);

    private final boolean enabled;
    private final String seedPassword;
    private final WorkshopRepository workshops;
    private final UserRepository users;
    private final WorkshopMembershipRepository memberships;
    private final PasswordEncoder passwordEncoder;

    public DevDataInitializer(@Value("${truereport.dev.seed-enabled:false}") boolean enabled,
                              @Value("${truereport.dev.seed-password:}") String seedPassword,
                              WorkshopRepository workshops,
                              UserRepository users,
                              WorkshopMembershipRepository memberships,
                              PasswordEncoder passwordEncoder) {
        this.enabled = enabled;
        this.seedPassword = seedPassword;
        this.workshops = workshops;
        this.users = users;
        this.memberships = memberships;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }
        if (seedPassword == null || seedPassword.isBlank()) {
            log.warn("DEV_SEED_ENABLED is true but DEV_SEED_PASSWORD is empty; no development users were created.");
            return;
        }
        if (users.findByEmailNormalized("admin.a@truereport.test").isPresent()) {
            return;
        }

        Workshop workshopA = workshops.save(new Workshop("Workshop A"));
        Workshop workshopB = workshops.save(new Workshop("Workshop B"));

        User adminA = createUser("admin.a@truereport.test", "Workshop Admin A");
        User techA = createUser("tech.a@truereport.test", "Technician A");
        User adminB = createUser("admin.b@truereport.test", "Workshop Admin B");
        User platform = createUser("platform@truereport.test", "Platform Admin");
        platform.setPlatformAdmin(true);
        users.save(platform);

        memberships.save(new WorkshopMembership(workshopA.getId(), adminA.getId(), WorkshopRole.WORKSHOP_ADMIN, true));
        memberships.save(new WorkshopMembership(workshopA.getId(), techA.getId(), WorkshopRole.TECHNICIAN, true));
        memberships.save(new WorkshopMembership(workshopB.getId(), adminB.getId(), WorkshopRole.WORKSHOP_ADMIN, true));

        log.info("Development seed created: admin.a@truereport.test, tech.a@truereport.test, admin.b@truereport.test, platform@truereport.test");
        log.info("Development seed password was read from DEV_SEED_PASSWORD and is not logged.");
    }

    private User createUser(String email, String displayName) {
        User user = new User(email, passwordEncoder.encode(seedPassword), displayName);
        user.setStatus(UserStatus.ACTIVE);
        return users.save(user);
    }
}
