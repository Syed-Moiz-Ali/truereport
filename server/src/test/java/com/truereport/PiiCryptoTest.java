package com.truereport;

import com.truereport.shared.security.PiiCrypto;
import org.junit.jupiter.api.Test;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PiiCryptoTest {

    @Test
    void roundTripUsesKeyIdAndSupportsRotation() {
        String oldKey = key();
        String newKey = key();
        PiiCrypto oldRing = new PiiCrypto("v1", Map.of("v1", oldKey));
        String encrypted = oldRing.encrypt("Customer 123");
        assertThat(encrypted).startsWith("v1:");
        assertThat(encrypted).doesNotContain("Customer 123");

        PiiCrypto rotated = new PiiCrypto("v2", Map.of("v1", oldKey, "v2", newKey));
        assertThat(rotated.decrypt(encrypted)).isEqualTo("Customer 123");
        String newValue = rotated.encrypt("+971500009900");
        assertThat(newValue).startsWith("v2:");
        assertThat(rotated.decrypt(newValue)).isEqualTo("+971500009900");
    }

    @Test
    void legacyPlaintextAndUnknownKeysFailClosed() {
        PiiCrypto crypto = new PiiCrypto("v1", Map.of("v1", key()));
        assertThat(crypto.decrypt("legacy plaintext")).isEqualTo("legacy plaintext");
        assertThatThrownBy(() -> crypto.decrypt("v9:AAAA"))
                .isInstanceOf(IllegalStateException.class);
    }

    private String key() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getEncoder().encodeToString(bytes);
    }
}
