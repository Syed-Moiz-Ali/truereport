package com.truereport.identity;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {
    Optional<RefreshToken> findByTokenHash(byte[] tokenHash);

    List<RefreshToken> findByFamilyId(UUID familyId);

    List<RefreshToken> findByUserId(UUID userId);

    List<RefreshToken> findByUserIdAndRevokedAtIsNull(UUID userId);

    /** Used by ops/tests to force an expiry; goes through Hibernate's UTC binding. */
    @Modifying
    @Transactional
    @Query("update RefreshToken t set t.expiresAt = :expiresAt where t.id = :id")
    int updateExpiresAt(@Param("id") UUID id, @Param("expiresAt") LocalDateTime expiresAt);
}
