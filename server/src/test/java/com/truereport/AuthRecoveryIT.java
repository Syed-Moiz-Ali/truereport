package com.truereport;

import com.truereport.identity.AuthService;
import com.truereport.identity.TotpService;
import com.truereport.identity.api.AuthResponse;
import com.truereport.identity.api.RecoveryCodesResponse;
import com.truereport.identity.api.TotpEnrollmentResponse;
import com.truereport.shared.error.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.TestPropertySource;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@TestPropertySource(properties = "truereport.auth.admin-totp.required=true")
class AuthRecoveryIT extends IntegrationTestBase {

    @Autowired
    AuthService authService;

    @Autowired
    TotpService totpService;

    @Test
    void totpRecoveryCodesAreOneTimeAndRegenerate() {
        var admin = fixture.adminA();
        TotpEnrollmentResponse enrollment = authService.enrollTotp(admin.getId());
        String totpCode = totpService.currentCode(enrollment.secret(), Instant.now());
        RecoveryCodesResponse codes = authService.confirmTotp(admin.getId(), totpCode);
        assertThat(codes.recoveryCodes()).hasSize(10);
        assertThat(codes.recoveryCodes()).doesNotContainNull();

        AuthResponse challenge = authService.login("admin.a@test.local", TestDataFactory.PASSWORD);
        assertThat(challenge.requiresTwoFactor()).isTrue();
        AuthResponse recovered = authService.verifyTwoFactor(
                challenge.challengeToken(), codes.recoveryCodes().get(0).toLowerCase());
        assertThat(recovered.accessToken()).isNotBlank();

        AuthResponse secondChallenge = authService.login("admin.a@test.local", TestDataFactory.PASSWORD);
        assertThatThrownBy(() -> authService.verifyTwoFactor(
                secondChallenge.challengeToken(), codes.recoveryCodes().get(0)))
                .isInstanceOf(ApiException.class);

        RecoveryCodesResponse regenerated = authService.regenerateRecoveryCodes(admin.getId());
        assertThat(regenerated.recoveryCodes()).hasSize(10)
                .doesNotContain(codes.recoveryCodes().get(1));
    }

    @Test
    void repeatedPasswordFailuresLockTheAccount() {
        for (int i = 0; i < 5; i++) {
            assertThatThrownBy(() -> authService.login("tech.a@test.local", "wrong-password"))
                    .isInstanceOf(ApiException.class);
        }
        assertThatThrownBy(() -> authService.login("tech.a@test.local", TestDataFactory.PASSWORD))
                .isInstanceOf(ApiException.class);
    }
}
