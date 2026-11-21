package com.truereport.shared.i18n;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Supported languages come from the static manifest ({@code i18n/languages.json})
 * and from the live database registry.
 *
 * <p>The manifest remains the boot-time seed. Platform Admin language creation
 * registers the new code at runtime, and {@code StaticLanguageSync} re-registers
 * every active LIVE row on startup, so an admin-added language survives a
 * restart without editing the manifest.</p>
 *
 * <p>The runtime set is thread-safe: request threads may read while the Platform
 * Admin endpoints register or retire a language.</p>
 */
@Component
public class LanguageCatalog {

    private static final String MANIFEST = "i18n/languages.json";

    private final String defaultLanguage;
    private final List<String> languages = new CopyOnWriteArrayList<>();
    private final Set<String> supported = ConcurrentHashMap.newKeySet();

    public LanguageCatalog(ObjectMapper objectMapper,
                           @Value("${truereport.i18n.default-language:}") String configuredDefault)
            throws IOException {
        JsonNode root;
        try (InputStream input = new ClassPathResource(MANIFEST).getInputStream()) {
            root = objectMapper.readTree(input);
        }
        LinkedHashSet<String> codes = new LinkedHashSet<>();
        for (JsonNode language : root.path("languages")) {
            String code = language.path("code").asText("");
            if (!code.isBlank()) {
                codes.add(normalize(code));
            }
        }
        if (codes.isEmpty()) {
            throw new IllegalStateException(MANIFEST + " must declare at least one language");
        }
        String manifestDefault = normalize(root.path("defaultLanguage").asText(codes.iterator().next()));
        String effectiveDefault = configuredDefault == null || configuredDefault.isBlank()
                ? manifestDefault : normalize(configuredDefault);
        if (!codes.contains(effectiveDefault)) {
            effectiveDefault = manifestDefault;
        }
        this.defaultLanguage = effectiveDefault;
        this.languages.addAll(codes);
        this.supported.addAll(codes);
    }

    public String defaultLanguage() {
        return defaultLanguage;
    }

    public List<String> languages() {
        return List.copyOf(languages);
    }

    public boolean isSupported(String code) {
        return code != null && supported.contains(normalize(code));
    }

    /** Makes an admin-created or reactivated code usable without a restart. */
    public void register(String code) {
        String normalized = normalize(code);
        if (normalized.isBlank() || !supported.add(normalized)) {
            return;
        }
        languages.add(normalized);
    }

    /**
     * Removes a retired code from every runtime lookup. The default language is
     * never removed; the admin write path rejects retiring it before reaching
     * here.
     */
    public void unregister(String code) {
        String normalized = normalize(code);
        if (normalized.isBlank() || normalized.equals(defaultLanguage)) {
            return;
        }
        supported.remove(normalized);
        languages.remove(normalized);
    }

    /** Registers every code in order, skipping blanks and duplicates. */
    public void registerAll(Collection<String> codes) {
        if (codes == null) {
            return;
        }
        for (String code : codes) {
            register(code);
        }
    }

    public String normalize(String code) {
        return code == null ? "" : code.trim().toLowerCase(Locale.ROOT);
    }

    /**
     * Resolves the first supported language from an {@code Accept-Language}
     * header, honouring q-values and falling back from {@code es-MX} to
     * {@code es}. Returns {@code null} when none of the requested languages is
     * supported so callers can try the user's saved preference next.
     */
    public String firstSupported(String header) {
        if (header == null || header.isBlank()) {
            return null;
        }
        List<Locale.LanguageRange> ranges;
        try {
            ranges = Locale.LanguageRange.parse(header);
        } catch (IllegalArgumentException exception) {
            return null;
        }
        for (Locale.LanguageRange range : ranges) {
            String candidate = normalize(range.getRange());
            if (candidate.isBlank()) {
                continue;
            }
            if (supported.contains(candidate)) {
                return candidate;
            }
            int separator = candidate.indexOf('-');
            if (separator > 0) {
                String base = candidate.substring(0, separator);
                if (supported.contains(base)) {
                    return base;
                }
            }
        }
        return null;
    }

    public String fromAcceptLanguage(String header) {
        String supported = firstSupported(header);
        return supported == null ? defaultLanguage : supported;
    }
}
