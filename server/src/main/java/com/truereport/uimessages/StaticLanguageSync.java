package com.truereport.uimessages;

import com.truereport.shared.i18n.LanguageCatalog;
import com.truereport.uimessages.PlatformUiMessageCatalog.Language;
import com.truereport.uimessages.PlatformUiMessageCatalog.Registry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Seeds {@code platform_languages} from the manifest registry and registers
 * every active LIVE database row in {@link LanguageCatalog}.
 *
 * <p>The registry ({@code i18n/languages.json}) is the source of truth for the
 * DB language set. Every declared code is inserted if missing and refreshed if
 * present, even when it has no Platform Admin UI catalog; the UI manifest is
 * intentionally narrower and stays English-only. Rows added at runtime are not
 * in the registry and are never modified here: LIVE ones stay live, RETIRED ones
 * stay retired. After the sync all active LIVE codes are registered so admin
 * additions survive a restart.</p>
 */
@Service
public class StaticLanguageSync {

    private static final Logger log = LoggerFactory.getLogger(StaticLanguageSync.class);

    private final JdbcTemplate jdbc;
    private final PlatformUiMessageCatalog catalog;
    private final LanguageCatalog languageCatalog;

    public StaticLanguageSync(JdbcTemplate jdbc, PlatformUiMessageCatalog catalog,
                              LanguageCatalog languageCatalog) {
        this.jdbc = jdbc;
        this.catalog = catalog;
        this.languageCatalog = languageCatalog;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void sync() {
        Registry registry = catalog.registry();
        List<String> codes = new ArrayList<>();
        int sortOrder = 1;
        for (Language language : registry.languages()) {
            String code = language.code() == null
                    ? "" : language.code().trim().toLowerCase(Locale.ROOT);
            if (code.isBlank() || codes.contains(code)) {
                continue;
            }
            codes.add(code);
            upsert(code, language.name(), language.nativeName(), language.direction(),
                    sortOrder++);
        }
        String defaultCode = registry.defaultLanguage() == null
                ? "en" : registry.defaultLanguage().trim().toLowerCase(Locale.ROOT);
        jdbc.update("UPDATE platform_languages SET is_default = FALSE WHERE code <> ?",
                defaultCode);
        jdbc.update("""
                UPDATE platform_languages
                SET is_default = TRUE, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, defaultCode);
        log.info("Synchronized UI language registry into platform_languages: {}", codes);
        List<String> liveCodes = jdbc.queryForList("""
                SELECT code FROM platform_languages
                WHERE active = TRUE AND status = 'LIVE'
                ORDER BY sort_order, code
                """, String.class);
        languageCatalog.registerAll(liveCodes);
        log.info("Registered active LIVE languages: {}", liveCodes);
    }

    private void upsert(String code, String name, String nativeName, String direction,
                        int sortOrder) {
        String resolvedName = nativeName;
        if (resolvedName == null || resolvedName.isBlank()) {
            resolvedName = name;
        }
        if (resolvedName == null || resolvedName.isBlank()) {
            resolvedName = code;
        }
        String resolvedDirection = "rtl".equalsIgnoreCase(direction) ? "rtl" : "ltr";
        // Only refresh the display metadata of an existing row: a language an
        // admin retired must not come back to life on the next restart.
        int updated = jdbc.update("""
                UPDATE platform_languages
                SET native_name = ?, direction = ?, sort_order = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, resolvedName.trim(), resolvedDirection, sortOrder, code);
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO platform_languages
                        (code, native_name, direction, active, is_default, sort_order,
                         status, created_at, updated_at, version)
                    VALUES (?, ?, ?, TRUE, FALSE, ?, 'LIVE',
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                    """, code, resolvedName.trim(), resolvedDirection, sortOrder);
        }
    }

}
