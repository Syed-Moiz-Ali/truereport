package com.truereport.identity;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

/**
 * Idempotency records for account create/reset endpoints.
 *
 * <p>Stores only SHA-256 hashes of the client-supplied {@code Idempotency-Key}
 * and of the canonical request payload. Plaintext passwords are never stored.
 */
@Entity
@Table(name = "account_idempotency_keys")
public class AccountIdempotencyKey extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "key_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] keyHash;

    @Column(name = "actor_user_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID actorUserId;

    @Column(name = "endpoint", nullable = false, length = 128)
    private String endpoint;

    @Column(name = "request_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] requestHash;

    @Column(name = "user_id", columnDefinition = "BINARY(16)")
    private UUID userId;

    protected AccountIdempotencyKey() {
    }

    public AccountIdempotencyKey(byte[] keyHash, UUID actorUserId, String endpoint,
                                 byte[] requestHash, UUID userId) {
        this.keyHash = keyHash;
        this.actorUserId = actorUserId;
        this.endpoint = endpoint;
        this.requestHash = requestHash;
        this.userId = userId;
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

    public byte[] getKeyHash() {
        return keyHash;
    }

    public UUID getActorUserId() {
        return actorUserId;
    }

    public String getEndpoint() {
        return endpoint;
    }

    public byte[] getRequestHash() {
        return requestHash;
    }

    public UUID getUserId() {
        return userId;
    }
}
