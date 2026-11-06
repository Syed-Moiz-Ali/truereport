package com.truereport.identity.api;

import com.truereport.identity.AuthService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.security.CurrentUserService;
import jakarta.validation.Valid;
import jakarta.annotation.security.PermitAll;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final CurrentUserService currentUserService;

    public AuthController(AuthService authService, CurrentUserService currentUserService) {
        this.authService = authService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/login")
    @PermitAll
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request.email(), request.password()));
    }

    @PostMapping("/refresh")
    @PermitAll
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request.refreshToken()));
    }

    @PostMapping("/2fa/verify")
    @PermitAll
    public ResponseEntity<AuthResponse> verifyTwoFactor(@Valid @RequestBody TwoFactorVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyTwoFactor(request.challengeToken(), request.code()));
    }

    @PostMapping("/2fa/enroll")
    @PreAuthorize("hasAnyRole('WORKSHOP_ADMIN','PLATFORM_ADMIN')")
    public ResponseEntity<TotpEnrollmentResponse> enroll(JwtAuthenticationToken authentication) {
        CurrentUser user = currentUserService.require(authentication);
        return ResponseEntity.ok(authService.enrollTotp(user.userId()));
    }

    @PostMapping("/2fa/confirm")
    @PreAuthorize("hasAnyRole('WORKSHOP_ADMIN','PLATFORM_ADMIN')")
    public ResponseEntity<RecoveryCodesResponse> confirm(JwtAuthenticationToken authentication,
                                                         @Valid @RequestBody TwoFactorConfirmRequest request) {
        CurrentUser user = currentUserService.require(authentication);
        return ResponseEntity.ok(authService.confirmTotp(user.userId(), request.code()));
    }

    @PostMapping("/2fa/recovery-codes")
    @PreAuthorize("hasAnyRole('WORKSHOP_ADMIN','PLATFORM_ADMIN')")
    public ResponseEntity<RecoveryCodesResponse> recoveryCodes(JwtAuthenticationToken authentication) {
        CurrentUser user = currentUserService.require(authentication);
        return ResponseEntity.ok(authService.regenerateRecoveryCodes(user.userId()));
    }

    @PostMapping("/logout")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> logout(JwtAuthenticationToken authentication) {
        CurrentUser user = currentUserService.require(authentication);
        authService.logout(user.userId(), user.sessionId());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/logout-all")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> logoutAll(JwtAuthenticationToken authentication) {
        CurrentUser user = currentUserService.require(authentication);
        authService.logoutAll(user.userId());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MeResponse> me(JwtAuthenticationToken authentication) {
        CurrentUser user = currentUserService.require(authentication);
        return ResponseEntity.ok(new MeResponse(
                authService.me(user.userId()),
                authService.memberships(user.userId())
        ));
    }
}
