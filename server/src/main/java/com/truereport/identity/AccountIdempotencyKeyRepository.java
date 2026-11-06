package com.truereport.identity;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface AccountIdempotencyKeyRepository extends JpaRepository<AccountIdempotencyKey, UUID> {
    Optional<AccountIdempotencyKey> findByKeyHashAndActorUserIdAndEndpoint(
            byte[] keyHash, UUID actorUserId, String endpoint);
}
