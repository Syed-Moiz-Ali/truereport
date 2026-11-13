package com.truereport.uimessages;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.uimessages.PlatformUiMessageCatalog.Language;
import com.truereport.uimessages.PlatformUiMessageCatalog.Snapshot;
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

    public UiMessageService(PlatformUiMessageCatalog catalog) {
        this.catalog = catalog;
    }

    public ManifestResult manifest(List<String> requestedNamespaces) {
        Snapshot snapshot = catalog.snapshot();
        List<String> namespaces = resolveNamespaces(requestedNamespaces);
        String fallback = snapshot.defaultLanguage();
        List<ManifestLanguageDto> live = new ArrayList<>();
        for (Language language : snapshot.languages()) {
            live.add(new ManifestLanguageDto(language.definition().code(),
                    language.definition().direction(), language.definition().nativeName(),
                    language.definition().name(), subset(language.versions(), namespaces)));
        }
        Map<String, Integer> versions = subset(snapshot.defaultCatalog().versions(), namespaces);
        UiMessageManifestDto manifest = new UiMessageManifestDto(fallback, versions, live);
        return new ManifestResult(manifest, etag(snapshot.etag() + "|" + String.join(",", namespaces)));
    }

    public BundleResult bundle(String language, List<String> requestedNamespaces) {
        if (language == null || language.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        Snapshot snapshot = catalog.snapshot();
        Language target = snapshot.language(language.trim());
        if (target == null) {
            throw ApiException.notFound();
        }
        List<String> namespaces = resolveNamespaces(requestedNamespaces);
        Language fallback = snapshot.defaultCatalog();
        String targetCode = target.definition().code();
        String fallbackCode = snapshot.defaultLanguage();
        Map<String, Integer> versions = new LinkedHashMap<>();
        Map<String, Map<String, String>> catalogs = new LinkedHashMap<>();
        Map<String, List<String>> missingKeys = new LinkedHashMap<>();
        for (String namespace : namespaces) {
            versions.put(namespace, target.versions().getOrDefault(namespace, 0));
            Map<String, String> primary = target.catalogs().getOrDefault(namespace, Map.of());
            Map<String, String> fallbackCatalog = targetCode.equals(fallbackCode)
                    ? Map.of()
                    : fallback.catalogs().getOrDefault(namespace, Map.of());
            TreeSet<String> keys = new TreeSet<>(primary.keySet());
            keys.addAll(fallbackCatalog.keySet());
            Map<String, String> catalog = new LinkedHashMap<>();
            List<String> missing = new ArrayList<>();
            for (String key : keys) {
                if (primary.containsKey(key)) {
                    catalog.put(key, primary.get(key));
                } else {
                    catalog.put(key, fallbackCatalog.get(key));
                    missing.add(key);
                }
            }
            catalogs.put(namespace, catalog);
            missingKeys.put(namespace, missing);
        }
        UiMessageBundleDto dto = new UiMessageBundleDto(targetCode, fallbackCode, versions,
                catalogs, missingKeys);
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
