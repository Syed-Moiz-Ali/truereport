package com.truereport.identity;

import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Locale;

@Service
public class TotpService {

    private static final String BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    private static final int SECRET_BYTES = 20;
    private static final int DIGITS = 6;
    private static final int WINDOW = 1;
    private static final long STEP_SECONDS = 30;

    private final SecureRandom random = new SecureRandom();

    public String generateSecret() {
        byte[] bytes = new byte[SECRET_BYTES];
        random.nextBytes(bytes);
        return base32Encode(bytes);
    }

    public String currentCode(String secret, Instant instant) {
        return code(secret, instant, DIGITS);
    }

    /**
     * Verifies a 6-digit code with a +/-1 step window. Returns the accepted step, or -1.
     * The caller must reject a step that is not greater than the last accepted step.
     */
    public long verify(String secret, String code, Instant instant, Long lastAcceptedStep) {
        if (code == null || !code.matches("\\d{6}")) {
            return -1;
        }
        long currentStep = instant.getEpochSecond() / STEP_SECONDS;
        for (long step = currentStep - WINDOW; step <= currentStep + WINDOW; step++) {
            String expected = codeAtStep(secret, step, DIGITS);
            if (constantTimeEquals(expected, code)) {
                if (lastAcceptedStep != null && step <= lastAcceptedStep) {
                    return -1;
                }
                return step;
            }
        }
        return -1;
    }

    String code(String secret, Instant instant, int digits) {
        return codeAtStep(secret, instant.getEpochSecond() / STEP_SECONDS, digits);
    }

    private String codeAtStep(String secret, long step, int digits) {
        try {
            byte[] key = base32Decode(secret);
            Mac mac = Mac.getInstance("HmacSHA1");
            mac.init(new SecretKeySpec(key, "HmacSHA1"));
            byte[] hash = mac.doFinal(ByteBuffer.allocate(8).putLong(step).array());
            int offset = hash[hash.length - 1] & 0x0F;
            int binary = ((hash[offset] & 0x7F) << 24)
                    | ((hash[offset + 1] & 0xFF) << 16)
                    | ((hash[offset + 2] & 0xFF) << 8)
                    | (hash[offset + 3] & 0xFF);
            int otp = binary % (int) Math.pow(10, digits);
            return String.format(Locale.ROOT, "%0" + digits + "d", otp);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("Unable to calculate TOTP", e);
        }
    }

    public String otpauthUri(String issuer, String accountName, String secret) {
        return "otpauth://totp/" + urlEncode(issuer) + ":" + urlEncode(accountName)
                + "?secret=" + secret + "&issuer=" + urlEncode(issuer) + "&digits=6&period=30";
    }

    private String urlEncode(String value) {
        return java.net.URLEncoder.encode(value, java.nio.charset.StandardCharsets.UTF_8)
                .replace("+", "%20");
    }

    static String base32Encode(byte[] data) {
        StringBuilder out = new StringBuilder((data.length * 8 + 4) / 5);
        int buffer = 0;
        int bitsLeft = 0;
        for (byte b : data) {
            buffer = (buffer << 8) | (b & 0xFF);
            bitsLeft += 8;
            while (bitsLeft >= 5) {
                out.append(BASE32_ALPHABET.charAt((buffer >> (bitsLeft - 5)) & 0x1F));
                bitsLeft -= 5;
            }
        }
        if (bitsLeft > 0) {
            out.append(BASE32_ALPHABET.charAt((buffer << (5 - bitsLeft)) & 0x1F));
        }
        return out.toString();
    }

    static byte[] base32Decode(String value) {
        String normalized = value.replace("=", "").replace(" ", "").toUpperCase(Locale.ROOT);
        int buffer = 0;
        int bitsLeft = 0;
        byte[] out = new byte[normalized.length() * 5 / 8];
        int index = 0;
        for (int i = 0; i < normalized.length(); i++) {
            int val = BASE32_ALPHABET.indexOf(normalized.charAt(i));
            if (val < 0) {
                throw new IllegalArgumentException("Invalid base32 secret");
            }
            buffer = (buffer << 5) | val;
            bitsLeft += 5;
            if (bitsLeft >= 8) {
                out[index++] = (byte) ((buffer >> (bitsLeft - 8)) & 0xFF);
                bitsLeft -= 8;
            }
        }
        return out;
    }

    private boolean constantTimeEquals(String expected, String actual) {
        if (expected.length() != actual.length()) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < expected.length(); i++) {
            result |= expected.charAt(i) ^ actual.charAt(i);
        }
        return result == 0;
    }
}
