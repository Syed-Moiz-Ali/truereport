package com.truereport.shared.uuid;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.UUID;

/**
 * RFC 9562 UUIDv7. Time-ordered, suitable for offline creation and BINARY(16) storage.
 */
public final class UuidV7 {

    private static final SecureRandom RANDOM = new SecureRandom();

    private UuidV7() {
    }

    public static UUID generate() {
        long timestamp = Instant.now().toEpochMilli() & 0xFFFFFFFFFFFFL;
        long randA = RANDOM.nextInt(1 << 12);
        long randB = RANDOM.nextLong();

        long msb = (timestamp << 16) | (0x7000L) | randA;
        long lsb = (randB & 0x3FFFFFFFFFFFFFFFL) | 0x8000000000000000L;
        return new UUID(msb, lsb);
    }
}
