package com.truereport.jobs;

import com.truereport.shared.security.SecretCipher;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

/**
 * Public-link token helper for the clean Workshop Admin tables. Only the hash is
 * used for lookup; the token is encrypted at rest so the Workshop Admin can
 * re-display the link and QR without storing plaintext.
 */
@Service
public class PlatformJobTokenService {

    private static final int TOKEN_BYTES = 32;

    private final SecureRandom random = new SecureRandom();
    private final SecretCipher cipher;

    public PlatformJobTokenService(SecretCipher cipher) {
        this.cipher = cipher;
    }

    public String newToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String hash(String token) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public String encrypt(String token) {
        return Base64.getEncoder().encodeToString(cipher.encrypt(token));
    }

    public String decrypt(String encrypted) {
        if (encrypted == null || encrypted.isBlank()) {
            return null;
        }
        return cipher.decrypt(Base64.getDecoder().decode(encrypted));
    }
}
