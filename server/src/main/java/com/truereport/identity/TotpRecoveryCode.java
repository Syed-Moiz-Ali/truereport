package com.truereport.identity;

import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "totp_recovery_codes")
public class TotpRecoveryCode {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "user_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID userId;

    @Column(name = "code_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] codeHash;

    @Column(name = "used_at")
    private LocalDateTime usedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    protected TotpRecoveryCode() {
    }

    public TotpRecoveryCode(UUID userId, byte[] codeHash, LocalDateTime createdAt) {
        this.userId = userId;
        this.codeHash = codeHash;
        this.createdAt = createdAt;
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public void markUsed(LocalDateTime at) {
        this.usedAt = at;
    }

    public byte[] getCodeHash() {
        return codeHash;
    }
}
