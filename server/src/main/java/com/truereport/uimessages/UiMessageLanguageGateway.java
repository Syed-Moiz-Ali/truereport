package com.truereport.uimessages;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

@Repository
public class UiMessageLanguageGateway {

    public record Language(
            String code,
            String nativeName,
            String direction,
            boolean active,
            boolean isDefault,
            int sortOrder,
            String status,
            String uiMessagesPath) {
    }

    private static final String COLUMNS = """
            code, native_name, direction, active, is_default, sort_order,
            status, ui_messages_path
            """;

    private static final RowMapper<Language> MAPPER = (rs, i) -> new Language(
            rs.getString("code"),
            rs.getString("native_name"),
            rs.getString("direction"),
            rs.getBoolean("active"),
            rs.getBoolean("is_default"),
            rs.getInt("sort_order"),
            rs.getString("status"),
            rs.getString("ui_messages_path"));

    private final JdbcTemplate jdbc;

    public UiMessageLanguageGateway(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Language> findLive() {
        return jdbc.query("""
                SELECT %s FROM platform_languages
                WHERE active = TRUE AND status = 'LIVE'
                ORDER BY sort_order, code
                """.formatted(COLUMNS), MAPPER);
    }

    public Optional<Language> find(String code) {
        if (code == null || code.isBlank()) {
            return Optional.empty();
        }
        return jdbc.query("""
                SELECT %s FROM platform_languages
                WHERE LOWER(code) = ?
                """.formatted(COLUMNS), MAPPER, code.trim().toLowerCase(Locale.ROOT))
                .stream().findFirst();
    }

    public String defaultCode() {
        return jdbc.query("SELECT code FROM platform_languages WHERE is_default = TRUE",
                rs -> rs.next() ? rs.getString(1) : null);
    }

    public void setUiMessagesPath(String code, String path) {
        jdbc.update("""
                UPDATE platform_languages
                SET ui_messages_path = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, path, code);
    }

    public void setUiMessagesReview(String code, String hash, String reviewedBy) {
        jdbc.update("""
                UPDATE platform_languages
                SET ui_messages_hash = ?, ui_messages_reviewed_at = CURRENT_TIMESTAMP,
                    ui_messages_reviewed_by = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE code = ?
                """, hash, reviewedBy, code);
    }

    public void setStatus(String code, String status) {
        jdbc.update("""
                UPDATE platform_languages
                SET status = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, status, code);
    }
}
