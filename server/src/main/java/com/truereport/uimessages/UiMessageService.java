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

    public UiMessageService(PlatformUiMessageCatalog catalog) {
        this.catalog = catalog;
    }

    public UiMessageManifestDto manifest(String client, List<String> requestedNamespaces) {
        requireClient(client);
        List<String> namespaces = resolveNamespaces(client, requestedNamespaces);
        Registry registry = catalog.registry();
        String fallback = registry.defaultLanguage();
        List<ManifestLanguageDto> languages = new ArrayList<>();
        for (Language language : catalog.languagesForClient(client)) {
            Map<String, Map<String, String>> catalogs =
                    mergedCatalogs(client, language.code(), namespaces, fallback);
            Map<String, String> messages = new LinkedHashMap<>();
            catalogs.values().forEach(messages::putAll);
            languages.add(new ManifestLanguageDto(language.code(), language.name(),
                    language.nativeName(), language.direction(),
                    PlatformUiMessageCatalog.version(messages)));
        }
        return new UiMessageManifestDto(fallback, client, namespaces, languages);
    }

    public UiMessageBundleDto bundle(String client, String language,
                                     List<String> requestedNamespaces) {
        requireClient(client);
        Registry registry = catalog.registry();
        String fallback = registry.defaultLanguage();
        String code = language == null || language.isBlank()
                ? fallback : language.trim().toLowerCase(Locale.ROOT);
        Language target = registry.find(code);
        if (target == null || !catalog.hasLanguageCatalog(client, target.code())) {
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
