package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.LanguageDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Access to the manifest-synchronized language registry.
 *
 * <p>{@code StaticLanguageSync} seeds the manifest languages. Platform Admin
 * may additionally create, retire and reactivate codes; those writes are
 * intentionally soft so content translation rows are never deleted.</p>
 */
@Repository
public class LanguageRepository {

    private final JdbcTemplate jdbc;

    public LanguageRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final String COLUMNS = """
            code, native_name, direction, active, is_default, sort_order, status
            """;

    private static final RowMapper<LanguageDto> MAPPER = (rs, i) ->
            new LanguageDto(
                    rs.getString("code"),
                    rs.getString("native_name"),
                    rs.getString("direction"),
                    rs.getBoolean("active"),
                    rs.getBoolean("is_default"),
                    rs.getInt("sort_order"),
                    statusOf(rs)
            );

    private static String statusOf(java.sql.ResultSet rs) throws java.sql.SQLException {
        String status = rs.getString("status");
        return status == null ? "LIVE" : status;
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

    public int updateStatus(String code, String status, boolean active) {
        return jdbc.update("""
                UPDATE platform_languages
                SET status = ?, active = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE code = ?
                """, status, active, code);
    }

    /** Highest sort order in the whole registry, retired rows included. */
    public int maxSortOrder() {
        Integer max = jdbc.queryForObject(
                "SELECT COALESCE(MAX(sort_order), 0) FROM platform_languages", Integer.class);
        return max == null ? 0 : max;
    }

    public int insert(String code, String nativeName, String direction, int sortOrder) {
        return jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order,
                     status, created_at, updated_at, version)
                VALUES (?, ?, ?, TRUE, FALSE, ?, 'LIVE',
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, code, nativeName, direction, sortOrder);
    }

    /** Reactivates a retired row in place, preserving every translation row. */
    public int reactivate(String code, String nativeName, String direction, int sortOrder) {
        return jdbc.update("""
                UPDATE platform_languages
                SET native_name = ?, direction = ?, active = TRUE, status = 'LIVE',
                    sort_order = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, nativeName, direction, sortOrder, code);
    }

    /** Soft retire: the row and all child content stay in the database. */
    public int retire(String code) {
        return jdbc.update("""
                UPDATE platform_languages
                SET status = 'RETIRED', active = FALSE, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE code = ?
                """, code);
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

}
