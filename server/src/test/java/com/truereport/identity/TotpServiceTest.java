package com.truereport.identity;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class TotpServiceTest {

    private final TotpService totp = new TotpService();

    @Test
    void matchesRfc6238Sha1Vector() {
        String secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        Instant at59 = Instant.ofEpochSecond(59);
        assertThat(totp.code(secret, at59, 8)).isEqualTo("94287082");
        assertThat(totp.currentCode(secret, at59)).isEqualTo("287082");
    }

    @Test
    void verifyAcceptsWindowAndRejectsReplay() {
        String secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        Instant at59 = Instant.ofEpochSecond(59);
        String code = totp.currentCode(secret, at59);
        long step = totp.verify(secret, code, at59, null);
        assertThat(step).isPositive();
        assertThat(totp.verify(secret, code, at59, step)).isEqualTo(-1);
        assertThat(totp.verify(secret, "000000", at59, null)).isEqualTo(-1);
    }
}
