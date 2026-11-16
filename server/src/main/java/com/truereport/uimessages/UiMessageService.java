package com.truereport.uimessages;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.uimessages.PlatformUiMessageCatalog.LanguageCatalog;
import com.truereport.uimessages.PlatformUiMessageCatalog.StaticLanguage;
import com.truereport.uimessages.PlatformUiMessageCatalog.StaticManifest;
import com.truereport.uimessages.api.UiMessageDtos.ManifestLanguageDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageBundleDto;
import com.truereport.uimessages.api.UiMessageDtos.UiMessageManifestDto;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

/**
 * Serves the static UI-message manifest and catalogs.
 *
 * <p>The static language list and its JSON files are the only sources of
 * truth. No database registry, generation job, review or publish step is
 * involved: adding a language means adding a JSON file and a manifest entry,
 * then reloading the backend.</p>
 */
@Service
public class UiMessageService {

    public static final Set<String> NAMESPACES = PlatformUiMessageCatalog.NAMESPACES;
    public static final List<String> NAMESPACE_ORDER = PlatformUiMessageCatalog.NAMESPACE_ORDER;

    public record BundleResult(UiMessageBundleDto bundle, String etag) {
    }

    public record ManifestResult(UiMessageManifestDto manifest, String etag) {
    }

    private final PlatformUiMessageCatalog catalog;

    public UiMessageService(PlatformUiMessageCatalog catalog) {
        this.catalog = catalog;
    }

    public ManifestResult manifest(List<String> requestedNamespaces) {
        List<String> namespaces = resolveNamespaces(requestedNamespaces);
        StaticManifest source = catalog.manifest();
        String fallback = source.defaultLanguage();
        List<ManifestLanguageDto> live = new ArrayList<>();
        Map<String, LanguageCatalog> loaded = new LinkedHashMap<>();
        for (StaticLanguage language : source.languages()) {
            LanguageCatalog languageCatalog;
            try {
                languageCatalog = catalog.load(language.file());
            } catch (RuntimeException broken) {
                // A missing or invalid catalog is skipped from the picker;
                // clients fall back to the default language.
                continue;
            }
            loaded.put(language.code(), languageCatalog);
            PlatformUiMessageCatalog.StaticCoverage coverage =
                    catalog.coverage(language.file());
            live.add(new ManifestLanguageDto(language.code(), language.direction(),
                    language.nativeName(),
                    subset(languageCatalog.versions(), namespaces),
                    language.file(), coverage.total(), coverage.missing(),
                    coverage.placeholderMismatch()));
        }
        Map<String, Integer> versions = new LinkedHashMap<>();
        LanguageCatalog defaultCatalog = loaded.get(fallback);
        if (defaultCatalog == null) {
            defaultCatalog = loaded.values().stream().findFirst().orElse(null);
        }
        for (String namespace : namespaces) {
            versions.put(namespace, defaultCatalog == null
                    ? 0 : defaultCatalog.versions().getOrDefault(namespace, 0));
        }
        UiMessageManifestDto manifest = new UiMessageManifestDto(fallback, versions, live);
        StringBuilder etagSource = new StringBuilder("manifest|").append(fallback)
                .append('|').append(String.join(",", namespaces));
        live.forEach(language -> etagSource.append('|').append(language.code())
                .append(':').append(language.path()).append(':').append(language.versions()));
        return new ManifestResult(manifest, etag(etagSource.toString()));
    }

    public BundleResult bundle(String language, List<String> requestedNamespaces) {
        if (language == null || language.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        StaticManifest source = catalog.manifest();
        StaticLanguage targetLanguage = source.find(language);
        if (targetLanguage == null) {
            throw ApiException.notFound();
        }
        LanguageCatalog target;
        try {
            target = catalog.load(targetLanguage.file());
        } catch (RuntimeException broken) {
            target = null;
        }
        String fallback = source.defaultLanguage();
        StaticLanguage fallbackLanguage = source.find(fallback);
        LanguageCatalog fallbackCatalog = null;
        if (fallbackLanguage != null
                && !fallbackLanguage.code().equalsIgnoreCase(targetLanguage.code())) {
            try {
                fallbackCatalog = catalog.load(fallbackLanguage.file());
            } catch (RuntimeException broken) {
                fallbackCatalog = null;
            }
        }
        if (target == null) {
            // Missing catalog falls back to the default language catalog.
            if (fallbackCatalog == null) {
                throw ApiException.notFound();
            }
            target = fallbackCatalog;
        }
        List<String> namespaces = resolveNamespaces(requestedNamespaces);
        Map<String, Integer> versions = new LinkedHashMap<>();
        Map<String, Map<String, String>> catalogs = new LinkedHashMap<>();
        Map<String, List<String>> missingKeys = new LinkedHashMap<>();
        for (String namespace : namespaces) {
            versions.put(namespace, target.versions().getOrDefault(namespace, 0));
            Map<String, String> primary = target.catalogs().getOrDefault(namespace, Map.of());
            Map<String, String> fallbackValues = fallbackCatalog == null
                    ? Map.of()
                    : fallbackCatalog.catalogs().getOrDefault(namespace, Map.of());
            TreeSet<String> keys = new TreeSet<>(primary.keySet());
            keys.addAll(fallbackValues.keySet());
            Map<String, String> catalogValues = new LinkedHashMap<>();
            List<String> missing = new ArrayList<>();
            for (String key : keys) {
                if (primary.containsKey(key)) {
                    catalogValues.put(key, primary.get(key));
                } else {
                    catalogValues.put(key, fallbackValues.get(key));
                    missing.add(key);
                }
            }
            catalogs.put(namespace, catalogValues);
            missingKeys.put(namespace, missing);
        }
        UiMessageBundleDto dto = new UiMessageBundleDto(targetLanguage.code(), fallback,
                versions, catalogs, missingKeys);
        return new BundleResult(dto, etag(target.etag() + "|" + String.join(",", namespaces)));
    }

    private Map<String, Integer> subset(Map<String, Integer> versions, List<String> namespaces) {
        Map<String, Integer> result = new LinkedHashMap<>();
        for (String namespace : namespaces) {
            result.put(namespace, versions.getOrDefault(namespace, 0));
        }
        return result;
    }

    private List<String> resolveNamespaces(List<String> requested) {
        if (requested == null || requested.isEmpty()) {
            return NAMESPACE_ORDER;
        }
        List<String> resolved = new ArrayList<>();
        for (String raw : requested) {
            if (raw == null) {
                continue;
            }
            for (String part : raw.split(",")) {
                String namespace = part.trim();
                if (namespace.isEmpty()) {
                    continue;
                }
                if (!NAMESPACES.contains(namespace)) {
                    throw validation("namespaces", "UI_MESSAGE_NAMESPACE_INVALID",
                            "error.validation.failed");
                }
                if (!resolved.contains(namespace)) {
                    resolved.add(namespace);
                }
            }
        }
        return resolved.isEmpty() ? NAMESPACE_ORDER : resolved;
    }

    private static String etag(String canonical) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(canonical.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte value : hash) {
                hex.append(Character.forDigit((value >> 4) & 0xF, 16));
                hex.append(Character.forDigit(value & 0xF, 16));
            }
            return "W/\"" + hex + "\"";
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException(error);
        }
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid UI message request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
