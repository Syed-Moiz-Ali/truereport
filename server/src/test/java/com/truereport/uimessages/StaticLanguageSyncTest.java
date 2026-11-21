package com.truereport.uimessages;

import com.truereport.shared.i18n.LanguageCatalog;
import com.truereport.uimessages.PlatformUiMessageCatalog.Language;
import com.truereport.uimessages.PlatformUiMessageCatalog.Registry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class StaticLanguageSyncTest {

    private JdbcTemplate jdbc;
    private PlatformUiMessageCatalog catalog;
    private LanguageCatalog languageCatalog;

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
        languageCatalog = mock(LanguageCatalog.class);
    }

    @Test
    void seedsEveryRegistryLanguageInManifestOrder() {
        when(catalog.registry()).thenReturn(registry());

        new StaticLanguageSync(jdbc, catalog, languageCatalog).sync();

        assertRow("en", "English", "ltr", true, true, 1, "LIVE");
        assertRow("es", "Español", "ltr", true, false, 2, "LIVE");
        assertRow("fr", "Français", "ltr", true, false, 3, "LIVE");
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_languages WHERE is_default = TRUE",
                Integer.class)).isEqualTo(1);
        assertRegisteredLiveCodes("en", "es", "fr");
    }

    @Test
    void refreshesAnExistingManifestRow() {
        jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order,
                     status, created_at, updated_at, version)
                VALUES ('en', 'Old English', 'ltr', FALSE, FALSE, 9, 'RETIRED',
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """);
        when(catalog.registry()).thenReturn(registry());

        new StaticLanguageSync(jdbc, catalog, languageCatalog).sync();

        assertRow("en", "English", "ltr", true, true, 1, "LIVE");
        assertRegisteredLiveCodes("en", "es", "fr");
    }

    @Test
    void leavesRuntimeAddedRowsAloneAndRegistersOnlyLiveOnes() {
        insertRuntimeLanguage("de", "Deutsch", true, "LIVE", 40);
        insertRuntimeLanguage("it", "Italiano", false, "RETIRED", 41);
        when(catalog.registry()).thenReturn(registry());

        new StaticLanguageSync(jdbc, catalog, languageCatalog).sync();

        // de is not in the registry: keep it LIVE, active and in its own order.
        assertRow("de", "Deutsch", "ltr", true, false, 40, "LIVE");
        // it is not in the registry: keep it retired.
        assertRow("it", "Italiano", "ltr", false, false, 41, "RETIRED");
        assertRegisteredLiveCodes("en", "es", "fr", "de");
    }

    @SuppressWarnings("unchecked")
    private void assertRegisteredLiveCodes(String... expected) {
        ArgumentCaptor<List<String>> captor = ArgumentCaptor.forClass(List.class);
        verify(languageCatalog).registerAll(captor.capture());
        assertThat(captor.getValue()).containsExactly(expected);
    }

    private void assertRow(String code, String nativeName, String direction, boolean active,
                           boolean isDefault, int sortOrder, String status) {
        Map<String, Object> row = jdbc.queryForMap("""
                SELECT native_name, direction, active, is_default, sort_order, status
                FROM platform_languages WHERE code = ?
                """, code);
        assertThat(row.get("native_name")).isEqualTo(nativeName);
        assertThat(row.get("direction")).isEqualTo(direction);
        assertThat(row.get("active")).isEqualTo(active);
        assertThat(row.get("is_default")).isEqualTo(isDefault);
        assertThat(row.get("sort_order")).isEqualTo(sortOrder);
        assertThat(row.get("status")).isEqualTo(status);
    }

    private void insertRuntimeLanguage(String code, String nativeName, boolean active,
                                       String status, int sortOrder) {
        jdbc.update("""
                INSERT INTO platform_languages
                    (code, native_name, direction, active, is_default, sort_order,
                     status, created_at, updated_at, version)
                VALUES (?, ?, 'ltr', ?, FALSE, ?, ?,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, code, nativeName, active, sortOrder, status);
    }

    private static Registry registry() {
        return new Registry("en", List.of(
                new Language("en", "English", "English", "ltr"),
                new Language("es", "Spanish", "Español", "ltr"),
                new Language("fr", "French", "Français", "ltr")));
    }
}
