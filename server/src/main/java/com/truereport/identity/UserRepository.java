package com.truereport.identity;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmailNormalized(String emailNormalized);

    long countByPlatformAdminTrueAndStatus(UserStatus status);
}
