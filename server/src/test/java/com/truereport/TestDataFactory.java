package com.truereport;

import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.identity.UserStatus;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.tenancy.WorkshopRole;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class TestDataFactory {

    public static final String PASSWORD = "Password123!";

    private final WorkshopRepository workshops;
    private final UserRepository users;
    private final WorkshopMembershipRepository memberships;
    private final PasswordEncoder passwordEncoder;

    public TestDataFactory(WorkshopRepository workshops,
                           UserRepository users,
                           WorkshopMembershipRepository memberships,
                           PasswordEncoder passwordEncoder) {
        this.workshops = workshops;
        this.users = users;
        this.memberships = memberships;
        this.passwordEncoder = passwordEncoder;
    }

    public Fixture createTwoWorkshops() {
        Workshop a = workshops.save(new Workshop("Workshop A"));
        Workshop b = workshops.save(new Workshop("Workshop B"));

        User adminA = user("admin.a@test.local", "Admin A", false);
        User techA = user("tech.a@test.local", "Technician A", false);
        User adminB = user("admin.b@test.local", "Admin B", false);
        User platform = user("platform@test.local", "Platform Admin", true);

        memberships.save(new WorkshopMembership(a.getId(), adminA.getId(), WorkshopRole.WORKSHOP_ADMIN, true));
        memberships.save(new WorkshopMembership(a.getId(), techA.getId(), WorkshopRole.TECHNICIAN, true));
        memberships.save(new WorkshopMembership(b.getId(), adminB.getId(), WorkshopRole.WORKSHOP_ADMIN, true));

        return new Fixture(a, b, adminA, techA, adminB, platform);
    }

    private User user(String email, String displayName, boolean platformAdmin) {
        User user = new User(email, passwordEncoder.encode(PASSWORD), displayName);
        user.setStatus(UserStatus.ACTIVE);
        user.setPlatformAdmin(platformAdmin);
        return users.save(user);
    }

    public record Fixture(Workshop workshopA,
                          Workshop workshopB,
                          User adminA,
                          User techA,
                          User adminB,
                          User platform) {
    }
}
