package com.truereport.shared.i18n;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * Resolves the active language for the current request:
 * {@code ?lang} (when supported), then {@code Accept-Language} (q-values, first
 * supported), then the caller's saved preference, then
 * {@code truereport.i18n.default-language}.
 *
 * <p>An explicit query parameter beats the header, but an unsupported value is
 * ignored (debug log) instead of failing the request. Request state is read
 * lazily so the component is safe in background jobs and snapshots, where it
 * simply yields the default language.</p>
 */
@Component
public class RequestLanguageContext {

    private static final Logger log = LoggerFactory.getLogger(RequestLanguageContext.class);

    private final LanguageCatalog catalog;
    private final JdbcTemplate jdbc;

    public RequestLanguageContext(LanguageCatalog catalog, JdbcTemplate jdbc) {
        this.catalog = catalog;
        this.jdbc = jdbc;
    }

    public String activeLanguage() {
        HttpServletRequest request = currentRequest();
        return resolve(request == null ? null : request.getParameter("lang"));
    }

    /**
     * Explicit language for a localized read. A supported value wins; anything
     * else falls through to the normal request resolution.
     */
    public String resolve(String explicit) {
        String requested = catalog.normalize(explicit);
        if (!requested.isBlank()) {
            if (catalog.isSupported(requested)) {
                return requested;
            }
            log.debug("Ignoring unsupported language '{}' (falling back)", explicit);
        }
        return headerOrPreferred();
    }

    public boolean isDefaultLanguage() {
        return catalog.normalize(activeLanguage()).equals(catalog.defaultLanguage());
    }

    /**
     * Language the author wrote content in: {@code Content-Language} first, then
     * the normal request language resolution. {@code ?lang} is a read/display
     * parameter and is deliberately ignored here.
     */
    public String authoringLanguage() {
        HttpServletRequest request = currentRequest();
        if (request != null) {
            String header = catalog.firstSupported(request.getHeader("Content-Language"));
            if (header != null) {
                return header;
            }
        }
        return headerOrPreferred();
    }

    private String headerOrPreferred() {
        HttpServletRequest request = currentRequest();
        if (request != null) {
            String header = catalog.firstSupported(request.getHeader("Accept-Language"));
            if (header != null) {
                return header;
            }
        }
        String preferred = preferredLanguage();
        if (catalog.isSupported(preferred)) {
            return catalog.normalize(preferred);
        }
        return catalog.defaultLanguage();
    }

    private String preferredLanguage() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (!(authentication instanceof JwtAuthenticationToken token)) {
            return null;
        }
        String userId = token.getToken().getClaimAsString("uid");
        if (userId == null || userId.isBlank()) {
            return null;
        }
        return jdbc.query("""
                SELECT language_code FROM platform_user_language_preferences WHERE user_id = ?
                """, (rs, i) -> rs.getString(1), userId).stream().findFirst().orElse(null);
    }

    private static HttpServletRequest currentRequest() {
        RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
        if (attributes instanceof ServletRequestAttributes servlet) {
            return servlet.getRequest();
        }
        return null;
    }
}
