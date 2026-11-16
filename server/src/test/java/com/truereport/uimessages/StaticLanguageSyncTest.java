package com.truereport.uimessages;

import com.truereport.uimessages.PlatformUiMessageCatalog.StaticLanguage;
import com.truereport.uimessages.PlatformUiMessageCatalog.StaticManifest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class StaticLanguageSyncTest {

    private JdbcTemplate jdbc;
    private PlatformUiMessageCatalog catalog;

    @BeforeEach
    void setUp() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource(
                "jdbc:h2:mem:static_sync_" + UUID.randomUUID()
                        + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1",
                "sa", "");
        jdbc = new JdbcTemplate(dataSource);
        jdbc.execute("""
                CREATE TABLE platform_languages (
                    code VARCHAR(16) NOT NULL PRIMARY KEY,
                    native_name VARCHAR(80) NOT NULL,
                    direction VARCHAR(3) NOT NULL,
                    active BOOLEAN NOT NULL DEFAULT TRUE,
                    is_default BOOLEAN NOT NULL DEFAULT FALSE,
                    sort_order INT NOT NULL DEFAULT 0,
                    status VARCHAR(16) NOT NULL DEFAULT 'LIVE',
                    created_at TIMESTAMP NOT NULL,
                    updated_at TIMESTAMP NOT NULL,
                    version INT NOT NULL DEFAULT 0
                )
                """);
        catalog = mock(PlatformUiMessageCatalog.class);
    }

    @Test
    void insertsOnlyManifestLanguageAndKeepsSharedRows() {
        insertSharedArabicRow();
        when(catalog.manifest()).thenReturn(englishOnlyManifest());

        new StaticLanguageSync(jdbc, catalog).sync();

        Map<String, Object> english = jdbc.queryForMap("""
                SELECT code, native_name, direction, active, is_default, sort_order, status
                FROM platform_languages WHERE code = 'en'
                """);
        assertThat(english.get("native_name")).isEqualTo("English");
        assertThat(english.get("direction")).isEqualTo("ltr");
        assertThat(english.get("active")).isEqualTo(true);
        assertThat(english.get("is_default")).isEqualTo(true);
        assertThat(english.get("sort_order")).isEqualTo(1);
        assertThat(english.get("status")).isEqualTo("LIVE");
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_languages WHERE is_default = TRUE",
                Integer.class)).isEqualTo(1);

        // Shared rows for other apps must survive a Platform Admin reset.
        assertThat(status("ar")).isEqualTo("LIVE");
        assertThat(active("ar")).isTrue();
    }

    @Test
    void updatesExistingEnglishRow() {
        jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order,
                     status, created_at, updated_at, version)
                VALUES ('en', 'Old English', 'ltr', FALSE, FALSE, 9, 'RETIRED',
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """);
        when(catalog.manifest()).thenReturn(englishOnlyManifest());

        new StaticLanguageSync(jdbc, catalog).sync();

        Map<String, Object> english = jdbc.queryForMap("""
                SELECT native_name, active, is_default, sort_order, status
                FROM platform_languages WHERE code = 'en'
                """);
        assertThat(english.get("native_name")).isEqualTo("English");
        assertThat(english.get("active")).isEqualTo(true);
        assertThat(english.get("is_default")).isEqualTo(true);
        assertThat(english.get("sort_order")).isEqualTo(1);
        assertThat(english.get("status")).isEqualTo("LIVE");
    }

    private void insertSharedArabicRow() {
        jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order,
                     status, created_at, updated_at, version)
                VALUES ('ar', 'Arabic', 'rtl', TRUE, FALSE, 2, 'LIVE',
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """);
    }

    private StaticManifest englishOnlyManifest() {
        return new StaticManifest("en", List.of(
                new StaticLanguage("en", "English", "English", "ltr",
                        "platform_admin/en.json")));
    }

    private String status(String code) {
        return jdbc.queryForObject(
                "SELECT status FROM platform_languages WHERE code = ?", String.class, code);
    }

    private boolean active(String code) {
        return Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT active FROM platform_languages WHERE code = ?", Boolean.class, code));
    }
}
