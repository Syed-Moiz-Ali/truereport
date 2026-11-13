package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.LanguageDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

@Repository
public class LanguageRepository {

    private final JdbcTemplate jdbc;

    public LanguageRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final String COLUMNS = """
            code, native_name, direction, active, is_default, sort_order, status,
            ui_messages_path, ui_messages_hash, ui_messages_reviewed_at, ui_messages_reviewed_by
            """;

    private static final org.springframework.jdbc.core.RowMapper<LanguageDto> MAPPER = (rs, i) ->
            new LanguageDto(
                    rs.getString("code"),
                    rs.getString("native_name"),
                    rs.getString("direction"),
                    rs.getBoolean("active"),
                    rs.getBoolean("is_default"),
                    rs.getInt("sort_order"),
                    statusOf(rs),
                    rs.getString("ui_messages_path"),
                    rs.getString("ui_messages_hash"),
                    timestamp(rs.getTimestamp("ui_messages_reviewed_at")),
                    rs.getString("ui_messages_reviewed_by")
            );

    private static String timestamp(Timestamp value) {
        return value == null ? null : value.toInstant().toString();
    }

    private static String statusOf(java.sql.ResultSet rs) throws java.sql.SQLException {
        String status = rs.getString("status");
        return status == null ? "DRAFT" : status;
    }

    public List<LanguageDto> findAll() {
        return jdbc.query("SELECT " + COLUMNS
                + " FROM platform_languages ORDER BY sort_order, code", MAPPER);
    }

    public List<LanguageDto> findActive() {
        return jdbc.query("SELECT " + COLUMNS
                + " FROM platform_languages WHERE active = TRUE ORDER BY sort_order, code", MAPPER);
    }

    public List<LanguageDto> findLive() {
        return jdbc.query("SELECT " + COLUMNS
                + " FROM platform_languages WHERE active = TRUE AND status = 'LIVE'"
                + " ORDER BY sort_order, code", MAPPER);
    }

    public Optional<LanguageDto> find(String code) {
        return jdbc.query("SELECT " + COLUMNS
                + " FROM platform_languages WHERE code = ?", MAPPER, code).stream().findFirst();
    }

    public String defaultCode() {
        return jdbc.query("""
                SELECT code FROM platform_languages WHERE is_default = TRUE
                """, rs -> rs.next() ? rs.getString(1) : null);
    }

    public void insert(LanguageDto language) {
        jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order, status,
                     ui_messages_path, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """,
                language.code(), language.nativeName(), language.direction(), language.active(),
                language.isDefault(), language.sortOrder(),
                language.status() == null ? "DRAFT" : language.status(),
                language.uiMessagesPath());
    }

    public void update(LanguageDto language) {
        jdbc.update("""
                UPDATE platform_languages
                SET native_name = ?, direction = ?, active = ?, sort_order = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """,
                language.nativeName(), language.direction(), language.active(),
                language.sortOrder(), language.code());
    }

    public void setStatus(String code, String status) {
        jdbc.update("""
                UPDATE platform_languages
                SET status = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, status, code);
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

    public void setUiMessagesPath(String code, String path) {
        jdbc.update("""
                UPDATE platform_languages
                SET ui_messages_path = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, path, code);
    }

    public void setLive(String code) {
        jdbc.update("""
                UPDATE platform_languages
                SET status = 'LIVE', active = TRUE, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE code = ?
                """, code);
    }

    public void setDefault(String code) {
        jdbc.update("UPDATE platform_languages SET is_default = FALSE WHERE is_default = TRUE");
        jdbc.update("UPDATE platform_languages SET is_default = TRUE,"
                + " updated_at = CURRENT_TIMESTAMP WHERE code = ?", code);
    }

    public void reorder(List<String> codes) {
        int order = 1;
        for (String code : codes) {
            jdbc.update("UPDATE platform_languages SET sort_order = ?,"
                    + " updated_at = CURRENT_TIMESTAMP WHERE code = ?", order++, code);
        }
    }

    public Optional<String> preferredLanguage(String userId) {
        return jdbc.query("""
                SELECT language_code FROM platform_user_language_preferences WHERE user_id = ?
                """, (rs, i) -> rs.getString(1), userId).stream().findFirst();
    }

    public void savePreference(String userId, String languageCode) {
        int updated = jdbc.update("""
                UPDATE platform_user_language_preferences
                SET language_code = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?
                """, languageCode, userId);
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO platform_user_language_preferences (user_id, language_code, updated_at)
                    VALUES (?, ?, CURRENT_TIMESTAMP)
                    """, userId, languageCode);
        }
    }

    public int countActive() {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM platform_languages WHERE active = TRUE",
                Integer.class);
        return count == null ? 0 : count;
    }

    public int countJobsUsing(String code) {
        try {
            Integer count = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM inspection_jobs WHERE preferred_language = ?", Integer.class, code);
            return count == null ? 0 : count;
        } catch (RuntimeException ex) {
            return 0;
        }
    }
}
