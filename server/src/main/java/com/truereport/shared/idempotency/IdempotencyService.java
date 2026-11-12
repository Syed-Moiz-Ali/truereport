package com.truereport.shared.idempotency;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Optional;

/**
 * Persistent idempotency keys. A replay returns the original response.
 */
@Service
public class IdempotencyService {

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public IdempotencyService(JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    public Optional<StoredResponse> find(String actorId, String endpoint, String key) {
        if (isBlank(key)) {
            return Optional.empty();
        }
        String hash = hash(key);
        return jdbc.query("""
                SELECT response_status, response_json FROM platform_idempotency_keys
                WHERE actor_id = ? AND endpoint = ? AND key_hash = ?
                """, (rs, i) -> new StoredResponse(rs.getInt(1), rs.getString(2)),
                actorId, endpoint, hash).stream().findFirst();
    }

    public StoredResponse store(String actorId, String endpoint, String key,
                                int status, Object response) {
        String json = toJson(response);
        if (isBlank(key)) {
            return new StoredResponse(status, json);
        }
        String hash = hash(key);
        int existing = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_idempotency_keys
                WHERE actor_id = ? AND endpoint = ? AND key_hash = ?
                """, Integer.class, actorId, endpoint, hash);
        if (existing > 0) {
            StoredResponse stored = find(actorId, endpoint, key)
                    .orElseThrow(() -> ApiException.conflict("IDEMPOTENCY_CONFLICT",
                            "Idempotency key already used"));
            if (stored.status() != status) {
                throw ApiException.conflict("IDEMPOTENCY_CONFLICT",
                        "Idempotency key reused with a different response");
            }
            return stored;
        }
        jdbc.update("""
                INSERT INTO platform_idempotency_keys
                    (id, actor_id, endpoint, key_hash, response_status, response_json, created_at)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                """, UuidV7.generate().toString(), actorId, endpoint, hash, status, json);
        return new StoredResponse(status, json);
    }

    private String toJson(Object response) {
        if (response == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(response);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to serialize idempotent response", ex);
        }
    }

    private static String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    public record StoredResponse(int status, String json) {
    }
}
