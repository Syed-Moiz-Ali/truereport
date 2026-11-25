package com.truereport.uimessages;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.uimessages.PlatformUiMessageCatalog.ClientCatalog;
import com.truereport.uimessages.PlatformUiMessageCatalog.Language;
import com.truereport.uimessages.PlatformUiMessageCatalog.NamespaceCatalog;
import com.truereport.uimessages.PlatformUiMessageCatalog.Registry;
import com.truereport.uimessages.api.UiMessageDtos.ManifestLanguageDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageBundleDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageManifestDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Builds the manifest and bundle for one Flutter client.
 *
 * <p>Every key and value comes from the JSON catalogs under {@code i18n}; Java
 * only merges the {@code common} namespace with the client namespace and fills
 * missing keys from English. Adding a language is a data-only change.</p>
 */
@Service
public class UiMessageService {

    public static final List<String> CLIENTS = PlatformUiMessageCatalog.CLIENTS;
    public static final String COMMON_NAMESPACE = PlatformUiMessageCatalog.COMMON_NAMESPACE;

    private final PlatformUiMessageCatalog catalog;
    private final JdbcTemplate jdbc;

    public UiMessageService(PlatformUiMessageCatalog catalog, JdbcTemplate jdbc) {
        this.catalog = catalog;
        this.jdbc = jdbc;
    }

    public record AppCoverage(String app, int translated, int total, boolean catalog) {
    }

    /**
     * Interface-text coverage per app namespace for one language. The catalogs
     * are written on approval, so the file's key count is the approved count.
     */
    public List<AppCoverage> appCoverage(String language) {
        String defaultLanguage = catalog.registry().defaultLanguage();
        String code = language == null || language.isBlank()
                ? defaultLanguage
                : language.trim().toLowerCase(Locale.ROOT);
        List<String> namespaces = new ArrayList<>();
        namespaces.add(COMMON_NAMESPACE);
        namespaces.addAll(CLIENTS);
        List<AppCoverage> rows = new ArrayList<>();
        for (String namespace : namespaces) {
            int total = catalog.namespace(namespace, defaultLanguage).values().size();
            int translated = catalog.namespace(namespace, code).values().size();
            rows.add(new AppCoverage(namespace, Math.min(translated, total), total,
                    catalog.hasLanguageCatalog(namespace, code)));
        }
        return rows;
    }

    public UiMessageManifestDto manifest(String client, List<String> requestedNamespaces) {
        requireClient(client);
        List<String> namespaces = resolveNamespaces(client, requestedNamespaces);
        Registry registry = catalog.registry();
        String fallback = registry.defaultLanguage();
        List<ManifestLanguageDto> languages = new ArrayList<>();
        for (PlatformUiMessageCatalog.Language language : liveLanguages(registry)) {
            Map<String, Map<String, String>> catalogs =
                    mergedCatalogs(client, language.code(), namespaces, fallback);
            Map<String, String> messages = new LinkedHashMap<>();
            catalogs.values().forEach(messages::putAll);
            languages.add(new ManifestLanguageDto(language.code(), language.name(),
                    language.nativeName(), language.direction(),
                    PlatformUiMessageCatalog.version(messages),
                    catalog.hasLanguageCatalog(client, language.code())));
        }
        return new UiMessageManifestDto(fallback, client, namespaces, languages);
    }

    /**
     * Registry languages that are LIVE in {@code platform_languages}, in registry
     * order with the default language first. A language added in the admin
     * console appears here before it has any UI catalog; its bundle then serves
     * English with the right writing direction.
     */
    private List<PlatformUiMessageCatalog.Language> liveLanguages(
            Registry registry) {
        java.util.Set<String> live = new java.util.HashSet<>(jdbc.queryForList("""
                SELECT code FROM platform_languages
                WHERE active = TRUE AND status = 'LIVE'
                """, String.class));
        List<PlatformUiMessageCatalog.Language> result = new ArrayList<>();
        for (PlatformUiMessageCatalog.Language language : registry.languages()) {
            if (live.isEmpty() || live.contains(language.code())) {
                result.add(language);
            }
        }
        return result;
    }

    public UiMessageBundleDto bundle(String client, String language,
                                     List<String> requestedNamespaces) {
        requireClient(client);
        Registry registry = catalog.registry();
        String fallback = registry.defaultLanguage();
        String code = language == null || language.isBlank()
                ? fallback : language.trim().toLowerCase(Locale.ROOT);
        Language target = registry.find(code);
        if (target == null) {
            throw ApiException.notFound();
        }
        List<String> namespaces = resolveNamespaces(client, requestedNamespaces);
        Map<String, Map<String, String>> catalogs =
                mergedCatalogs(client, target.code(), namespaces, fallback);

        Map<String, Integer> versions = new LinkedHashMap<>();
        Map<String, String> messages = new LinkedHashMap<>();
        for (Map.Entry<String, Map<String, String>> entry : catalogs.entrySet()) {
            versions.put(entry.getKey(), PlatformUiMessageCatalog.version(entry.getValue()));
            messages.putAll(entry.getValue());
        }

        return new UiMessageBundleDto(target.code(), fallback, client, namespaces,
                versions, catalogs, messages);
    }

    private Map<String, Map<String, String>> mergedCatalogs(String client, String language,
                                                           List<String> namespaces,
                                                           String fallback) {
        ClientCatalog localized = catalog.client(client, language);
        ClientCatalog english = catalog.client(client, fallback);
        Map<String, Map<String, String>> catalogs = new LinkedHashMap<>();
        for (String namespace : namespaces) {
            Map<String, String> merged = new LinkedHashMap<>();
            merged.putAll(values(english, namespace));
            // Existing translations win over English; unknown keys are kept.
            merged.putAll(values(localized, namespace));
            catalogs.put(namespace, merged);
        }
        return catalogs;
    }

    private Map<String, String> values(ClientCatalog client, String namespace) {
        NamespaceCatalog catalog = client.namespaces().get(namespace);
        return catalog == null ? Map.of() : catalog.values();
    }

    private void requireClient(String client) {
        if (!catalog.clientSupported(client)) {
            throw ApiException.notFound();
        }
    }

    private List<String> resolveNamespaces(String client, List<String> requested) {
        List<String> allowed = PlatformUiMessageCatalog.namespacesForClient(client);
        if (requested == null || requested.isEmpty()) {
            return allowed;
        }
        LinkedHashSet<String> requestedSet = new LinkedHashSet<>();
        for (String raw : requested) {
            if (raw == null) {
                continue;
            }
            for (String part : raw.split(",")) {
                String namespace = part.trim();
                if (namespace.isEmpty()) {
                    continue;
                }
                if (!allowed.contains(namespace)) {
                    throw validation("namespaces", "UI_MESSAGE_NAMESPACE_INVALID",
                            "error.validation.failed");
                }
                requestedSet.add(namespace);
            }
        }
        if (requestedSet.isEmpty()) {
            return allowed;
        }
        // Always answer in the canonical common-first order, whatever order the
        // caller listed the namespaces in.
        List<String> resolved = new ArrayList<>();
        for (String namespace : allowed) {
            if (requestedSet.contains(namespace)) {
                resolved.add(namespace);
            }
        }
        return List.copyOf(resolved);
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid UI message request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
