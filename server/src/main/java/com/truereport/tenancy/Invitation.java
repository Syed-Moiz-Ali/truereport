package com.truereport.tenancy;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "invitations")
public class Invitation extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "user_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID userId;

    @Column(name = "email_normalized", nullable = false, length = 320)
    private String emailNormalized;

    @Enumerated(EnumType.STRING)
    @Column(name = "member_role", nullable = false, length = 32)
    private WorkshopRole role;

    @Column(name = "token_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] tokenHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private InvitationStatus status = InvitationStatus.PENDING;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "created_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID createdBy;

    protected Invitation() {
    }

    public Invitation(UUID workshopId, UUID userId, String emailNormalized, WorkshopRole role,
                      byte[] tokenHash, LocalDateTime expiresAt, UUID createdBy) {
        this.workshopId = workshopId;
        this.userId = userId;
        this.emailNormalized = emailNormalized;
        this.role = role;
        this.tokenHash = tokenHash;
        this.expiresAt = expiresAt;
        this.createdBy = createdBy;
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public UUID getId() {
        return id;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getEmailNormalized() {
        return emailNormalized;
    }

    public WorkshopRole getRole() {
        return role;
    }

    public byte[] getTokenHash() {
        return tokenHash;
    }

    public InvitationStatus getStatus() {
        return status;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public LocalDateTime getAcceptedAt() {
        return acceptedAt;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public void accept(LocalDateTime at) {
        this.status = InvitationStatus.ACCEPTED;
        this.acceptedAt = at;
    }

    public void revoke() {
        this.status = InvitationStatus.REVOKED;
    }

    public boolean isPending(LocalDateTime now) {
        return status == InvitationStatus.PENDING && expiresAt.isAfter(now);
    }
}
