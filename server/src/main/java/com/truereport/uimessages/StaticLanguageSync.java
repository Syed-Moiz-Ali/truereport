package com.truereport.uimessages;

import com.truereport.uimessages.PlatformUiMessageCatalog.StaticLanguage;
import com.truereport.uimessages.PlatformUiMessageCatalog.StaticManifest;
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
 * Mirrors the languages advertised for Platform Admin into {@code platform_languages}.
 *
 * <p>The database registry backs dynamic content translations, readiness and
 * user preferences. Every language registered in {@code i18n/languages.json}
 * with a {@code i18n/platform_admin/<code>.json} file is inserted if missing and
 * refreshed if present. Shared rows for other apps are retained even when they
 * are not advertised for Platform Admin. Platform Admin never edits the registry
 * directly.</p>
 */
@Service
public class StaticLanguageSync {

    private static final Logger log = LoggerFactory.getLogger(StaticLanguageSync.class);

    private final JdbcTemplate jdbc;
    private final PlatformUiMessageCatalog catalog;

    public StaticLanguageSync(JdbcTemplate jdbc, PlatformUiMessageCatalog catalog) {
        this.jdbc = jdbc;
        this.catalog = catalog;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void sync() {
        StaticManifest manifest = catalog.manifest();
        List<String> codes = new ArrayList<>();
        int sortOrder = 1;
        for (StaticLanguage language : manifest.languages()) {
            String code = language.code().trim().toLowerCase(Locale.ROOT);
            if (codes.contains(code)) {
                continue;
            }
            codes.add(code);
            upsert(language, sortOrder++);
        }
        String defaultCode = manifest.defaultLanguage() == null
                ? "en" : manifest.defaultLanguage().trim().toLowerCase(Locale.ROOT);
        jdbc.update("UPDATE platform_languages SET is_default = FALSE WHERE code <> ?",
                defaultCode);
        jdbc.update("""
                UPDATE platform_languages
                SET is_default = TRUE, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE code = ?
                """, defaultCode);
        log.info("Synchronized static UI languages from manifest: {}", codes);
    }

    private void upsert(StaticLanguage language, int sortOrder) {
        String code = language.code().trim().toLowerCase(Locale.ROOT);
        String nativeName = language.nativeName() == null || language.nativeName().isBlank()
                ? language.name() : language.nativeName().trim();
        String direction = "rtl".equalsIgnoreCase(language.direction()) ? "rtl" : "ltr";
        int updated = jdbc.update("""
                UPDATE platform_languages
                SET native_name = ?, direction = ?, active = TRUE, sort_order = ?,
                    status = 'LIVE', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE code = ?
                """, nativeName, direction, sortOrder, code);
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO platform_languages
                        (code, native_name, direction, active, is_default, sort_order,
                         status, created_at, updated_at, version)
                    VALUES (?, ?, ?, TRUE, FALSE, ?, 'LIVE',
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                    """, code, nativeName, direction, sortOrder);
        }
    }

}
