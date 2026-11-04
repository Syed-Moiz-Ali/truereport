package com.truereport.identity;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface TotpRecoveryCodeRepository extends JpaRepository<TotpRecoveryCode, UUID> {
    Optional<TotpRecoveryCode> findByUserIdAndCodeHashAndUsedAtIsNull(UUID userId, byte[] codeHash);

    long deleteByUserId(UUID userId);
}
