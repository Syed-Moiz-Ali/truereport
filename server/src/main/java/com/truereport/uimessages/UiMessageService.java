package com.truereport.uimessages;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.uimessages.PlatformUiMessageCatalog.LanguageCatalog;
import com.truereport.uimessages.UiMessageLanguageGateway.Language;
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

@Service
public class UiMessageService {

    public static final Set<String> NAMESPACES = PlatformUiMessageCatalog.NAMESPACES;
    public static final List<String> NAMESPACE_ORDER = PlatformUiMessageCatalog.NAMESPACE_ORDER;

    public record BundleResult(UiMessageBundleDto bundle, String etag) {
    }

    public record ManifestResult(UiMessageManifestDto manifest, String etag) {
    }

    private final PlatformUiMessageCatalog catalog;
    private final UiMessageLanguageGateway languages;

    public UiMessageService(PlatformUiMessageCatalog catalog, UiMessageLanguageGateway languages) {
        this.catalog = catalog;
        this.languages = languages;
    }

    public ManifestResult manifest(List<String> requestedNamespaces) {
        List<String> namespaces = resolveNamespaces(requestedNamespaces);
        String fallback = defaultCode();
        List<ManifestLanguageDto> live = new ArrayList<>();
        Map<String, LanguageCatalog> loaded = new LinkedHashMap<>();
        for (Language language : languages.findLive()) {
            if (language.uiMessagesPath() == null || language.uiMessagesPath().isBlank()) {
                continue;
            }
            LanguageCatalog languageCatalog;
            try {
                languageCatalog = catalog.load(language.uiMessagesPath());
            } catch (RuntimeException broken) {
                continue;
            }
            loaded.put(language.code(), languageCatalog);
            live.add(new ManifestLanguageDto(language.code(), language.direction(),
                    language.nativeName(), language.nameEn(),
                    subset(languageCatalog.versions(), namespaces),
                    language.uiMessagesPath()));
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
        Language targetLanguage = languages.find(language)
                .orElseThrow(ApiException::notFound);
        if (!targetLanguage.active() || !"LIVE".equals(targetLanguage.status())) {
            throw ApiException.notFound();
        }
        if (targetLanguage.uiMessagesPath() == null
                || targetLanguage.uiMessagesPath().isBlank()) {
            throw ApiException.notFound();
        }
        LanguageCatalog target;
        try {
            target = catalog.load(targetLanguage.uiMessagesPath());
        } catch (RuntimeException broken) {
            throw ApiException.notFound();
        }
        List<String> namespaces = resolveNamespaces(requestedNamespaces);
        String fallback = defaultCode();
        LanguageCatalog fallbackCatalog = null;
        if (!targetLanguage.code().equalsIgnoreCase(fallback)) {
            Language fallbackLanguage = languages.find(fallback).orElse(null);
            if (fallbackLanguage != null && fallbackLanguage.uiMessagesPath() != null
                    && !fallbackLanguage.uiMessagesPath().isBlank()) {
                try {
                    fallbackCatalog = catalog.load(fallbackLanguage.uiMessagesPath());
                } catch (RuntimeException broken) {
                    fallbackCatalog = null;
                }
            }
        }
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

    private String defaultCode() {
        String fallback = languages.defaultCode();
        return fallback == null ? "en" : fallback;
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
            return "\"" + hex + "\"";
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException(error);
        }
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid UI message request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
