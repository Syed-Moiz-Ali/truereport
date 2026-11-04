package com.truereport.shared.security;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Application-level envelope encryption for PII. The stored value carries its key
 * ID so retired keys can decrypt older rows during rotation.
 */
public final class PiiCrypto {

    private static final int IV_BYTES = 12;
    private static final int TAG_BITS = 128;
    private static final Pattern KEY_ID = Pattern.compile("^[A-Za-z0-9_-]{1,32}$");
    private final SecureRandom random = new SecureRandom();
    private final String activeKeyId;
    private final Map<String, SecretKeySpec> keys;

    public PiiCrypto(String activeKeyId, Map<String, String> base64Keys) {
        if (activeKeyId == null || !KEY_ID.matcher(activeKeyId).matches()) {
            throw new IllegalArgumentException("PII active key ID is invalid");
        }
        if (base64Keys == null || base64Keys.isEmpty()) {
            throw new IllegalArgumentException("At least one PII key is required");
        }
        Map<String, SecretKeySpec> parsed = new LinkedHashMap<>();
        base64Keys.forEach((id, value) -> {
            if (id == null || !KEY_ID.matcher(id).matches() || value == null || value.isBlank()) {
                throw new IllegalArgumentException("PII key entry is invalid");
            }
            byte[] bytes = Base64.getDecoder().decode(value.trim());
            if (bytes.length != 32) {
                throw new IllegalArgumentException("PII keys must be base64-encoded 32-byte keys");
            }
            parsed.put(id, new SecretKeySpec(bytes, "AES"));
        });
        if (!parsed.containsKey(activeKeyId)) {
            throw new IllegalArgumentException("PII active key ID is not present in the key ring");
        }
        this.activeKeyId = activeKeyId;
        this.keys = Map.copyOf(parsed);
    }

    public static PiiCrypto fromEnvironment() {
        String ring = propertyOrEnv("APP_PII_KEYS");
        String fallback = propertyOrEnv("APP_ENCRYPTION_KEY");
        String active = propertyOrEnv("APP_PII_ACTIVE_KEY_ID");
        return fromStrings(ring, fallback, active == null || active.isBlank() ? "v1" : active);
    }

    private static String propertyOrEnv(String name) {
        String property = System.getProperty(name);
        return property != null && !property.isBlank() ? property : System.getenv(name);
    }

    public static PiiCrypto fromStrings(String ring, String fallback, String active) {
        Map<String, String> parsed = new LinkedHashMap<>();
        if (ring != null && !ring.isBlank()) {
            for (String entry : ring.split(",")) {
                String[] parts = entry.trim().split(":", 2);
                if (parts.length != 2 || parts[0].isBlank() || parts[1].isBlank()) {
                    throw new IllegalArgumentException("APP_PII_KEYS must be id:base64 pairs");
                }
                parsed.put(parts[0].trim(), parts[1].trim());
            }
        } else if (fallback != null && !fallback.isBlank()) {
            parsed.put(active == null || active.isBlank() ? "v1" : active, fallback.trim());
        }
        if (parsed.isEmpty()) {
            return null;
        }
        return new PiiCrypto(active == null || active.isBlank() ? "v1" : active, parsed);
    }

    public String encrypt(String plaintext) {
        if (plaintext == null || plaintext.isEmpty()) {
            return plaintext;
        }
        try {
            byte[] iv = new byte[IV_BYTES];
            random.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, keys.get(activeKeyId),
                    new GCMParameterSpec(TAG_BITS, iv));
            byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            byte[] payload = ByteBuffer.allocate(iv.length + ciphertext.length)
                    .put(iv).put(ciphertext).array();
            return activeKeyId + ":" + Base64.getEncoder().encodeToString(payload);
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Unable to encrypt PII", exception);
        }
    }

    public String decrypt(String stored) {
        if (stored == null || stored.isEmpty()) {
            return stored;
        }
        int separator = stored.indexOf(':');
        if (separator <= 0) {
            return stored;
        }
        String keyId = stored.substring(0, separator);
        SecretKeySpec key = keys.get(keyId);
        if (key == null) {
            throw new IllegalStateException("No PII key is available for key ID " + keyId);
        }
        try {
            byte[] payload = Base64.getDecoder().decode(stored.substring(separator + 1));
            if (payload.length <= IV_BYTES) {
                throw new IllegalArgumentException("Invalid encrypted PII");
            }
            ByteBuffer buffer = ByteBuffer.wrap(payload);
            byte[] iv = new byte[IV_BYTES];
            buffer.get(iv);
            byte[] ciphertext = new byte[buffer.remaining()];
            buffer.get(ciphertext);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, iv));
            return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
        } catch (GeneralSecurityException | IllegalArgumentException exception) {
            throw new IllegalStateException("Unable to decrypt PII", exception);
        }
    }

    public boolean isEncrypted(String value) {
        if (value == null) {
            return false;
        }
        int separator = value.indexOf(':');
        if (separator <= 0) {
            return false;
        }
        String keyId = value.substring(0, separator);
        return keys.containsKey(keyId) || keyId.matches("v[0-9]{1,3}");
    }

    public String activeKeyId() {
        return activeKeyId;
    }
}
