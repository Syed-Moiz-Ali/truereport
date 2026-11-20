package com.truereport.uimessages;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;

/**
 * File-based UI message catalogs.
 *
 * <p>Layout (one file per namespace and language):
 * <pre>
 * i18n/languages.json            language registry (single source of truth)
 * i18n/common/&lt;code&gt;.json       keys shared by two or more clients
 * i18n/&lt;client&gt;/&lt;code&gt;.json     keys used only by that client
 * </pre>
 *
 * <p>Java never defines keys: it only reads these files. A language is offered
 * for a client when it is registered in {@code languages.json} and
 * {@code i18n/&lt;client&gt;/&lt;code&gt;.json} exists.</p>
 */
@Component
public class PlatformUiMessageCatalog {

    public static final String DIRECTORY_PROPERTY = "truereport.i18n.ui-messages-dir";
    public static final String DEFAULT_LANGUAGE = "en";
    public static final String COMMON_NAMESPACE = "common";
    public static final String REGISTRY_PATH = "languages.json";

    public static final List<String> CLIENTS =
            List.of("platform_admin", "workshop_admin", "technician");

    private static final String CLASSPATH_ROOT = "i18n/";

    /** One entry of {@code languages.json}. */
    public record Language(String code, String name, String nativeName, String direction) {
    }

    /** The whole {@code languages.json} registry. */
    public record Registry(String defaultLanguage, List<Language> languages) {

        public Language find(String code) {
            if (code == null || code.isBlank()) {
                return null;
            }
            String normalized = code.trim();
            for (Language language : languages) {
                if (language.code().equalsIgnoreCase(normalized)) {
                    return language;
                }
            }
            return null;
        }
    }

    /** A single namespace file for one language. */
    public record NamespaceCatalog(String namespace, String language,
                                   Map<String, String> values, int version) {
    }

    /** All namespace files that make up one client language bundle. */
    public record ClientCatalog(String client, String language,
                                Map<String, NamespaceCatalog> namespaces) {
    }

    /**
     * Backwards-compatible view used by language readiness: the Platform Admin
     * languages that actually ship a catalog file.
     */
    public record StaticLanguage(String code, String name, String nativeName,
                                 String direction, String file) {
    }

    public record StaticManifest(String defaultLanguage, List<StaticLanguage> languages) {

        public StaticLanguage find(String code) {
            if (code == null || code.isBlank()) {
                return null;
            }
            String normalized = code.trim();
            for (StaticLanguage language : languages) {
                if (language.code().equalsIgnoreCase(normalized)) {
                    return language;
                }
            }
            return null;
        }
    }

    /** Static JSON coverage of one catalog against the default catalog. */
    public record StaticCoverage(int total, int missing, int changed,
                                 int placeholderMismatch) {
    }

    private record CacheEntry(NamespaceCatalog catalog, long modifiedAt) {
    }

    private record RegistryCacheEntry(Registry registry, long modifiedAt) {
    }

    private final ObjectMapper objectMapper;
    private final String directory;
    private final boolean filesystemRoot;
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private final Map<String, RegistryCacheEntry> registryCache = new ConcurrentHashMap<>();

    public PlatformUiMessageCatalog(
            ObjectMapper objectMapper,
            @Value("${" + DIRECTORY_PROPERTY
                    + ":src/main/resources/i18n}") String directory) {
        this.objectMapper = objectMapper;
        this.directory = resolveRoot(directory);
        this.filesystemRoot = !this.directory.isBlank()
                && Files.isDirectory(Path.of(this.directory));
    }

    @PostConstruct
    void validateOnStartup() {
        Registry registry = registry();
        if (registry.find(DEFAULT_LANGUAGE) == null) {
            throw new IllegalStateException(
                    "languages.json must register the default language '" + DEFAULT_LANGUAGE + "'");
        }
        if (!hasLanguageCatalog(COMMON_NAMESPACE, DEFAULT_LANGUAGE)) {
            throw new IllegalStateException(
                    "Missing mandatory catalog 'common/" + DEFAULT_LANGUAGE + ".json'");
        }
        for (String client : CLIENTS) {
            if (!hasLanguageCatalog(client, DEFAULT_LANGUAGE)) {
                throw new IllegalStateException("Missing mandatory catalog '" + client + "/"
                        + DEFAULT_LANGUAGE + ".json'");
            }
        }
    }

    /** Reads and caches {@code languages.json}. */
    public Registry registry() {
        long modifiedAt = lastModified(REGISTRY_PATH);
        RegistryCacheEntry existing = registryCache.get(REGISTRY_PATH);
        if (existing != null && existing.modifiedAt() == modifiedAt) {
            return existing.registry();
        }
        synchronized (this) {
            RegistryCacheEntry current = registryCache.get(REGISTRY_PATH);
            if (current != null && current.modifiedAt() == modifiedAt) {
                return current.registry();
            }
            Registry registry = readRegistry();
            registryCache.put(REGISTRY_PATH, new RegistryCacheEntry(registry, modifiedAt));
            return registry;
        }
    }

    public boolean clientSupported(String client) {
        return client != null && CLIENTS.contains(client);
    }

    /** Registered languages that ship a catalog file for this client, in registry order. */
    public List<Language> languagesForClient(String client) {
        if (!clientSupported(client)) {
            throw new IllegalArgumentException("Unknown UI message client: " + client);
        }
        List<Language> result = new ArrayList<>();
        for (Language language : registry().languages()) {
            if (hasLanguageCatalog(client, language.code())) {
                result.add(language);
            }
        }
        return List.copyOf(result);
    }

    public boolean hasLanguageCatalog(String namespace, String language) {
        if (namespace == null || language == null || namespace.isBlank() || language.isBlank()) {
            return false;
        }
        return exists(namespace + "/" + language.trim().toLowerCase(Locale.ROOT) + ".json");
    }

    /** Reads one namespace catalog; a missing file yields an empty catalog. */
    public NamespaceCatalog namespace(String namespace, String language) {
        String code = language == null ? DEFAULT_LANGUAGE : language.trim().toLowerCase(Locale.ROOT);
        String relativePath = namespace + "/" + code + ".json";
        long modifiedAt = lastModified(relativePath);
        CacheEntry existing = cache.get(relativePath);
        if (existing != null && existing.modifiedAt() == modifiedAt) {
            return existing.catalog();
        }
        synchronized (this) {
            CacheEntry current = cache.get(relativePath);
            if (current != null && current.modifiedAt() == modifiedAt) {
                return current.catalog();
            }
            NamespaceCatalog catalog = readNamespace(namespace, code, relativePath);
            cache.put(relativePath, new CacheEntry(catalog, modifiedAt));
            return catalog;
        }
    }

    /** Reads every namespace for a client language; missing files are empty. */
    public ClientCatalog client(String client, String language) {
        if (!clientSupported(client)) {
            throw new IllegalArgumentException("Unknown UI message client: " + client);
        }
        Map<String, NamespaceCatalog> namespaces = new LinkedHashMap<>();
        for (String namespace : namespacesForClient(client)) {
            namespaces.put(namespace, namespace(namespace, language));
        }
        return new ClientCatalog(client, language, Collections.unmodifiableMap(namespaces));
    }

    public static List<String> namespacesForClient(String client) {
        return List.of(COMMON_NAMESPACE, client);
    }

    public void invalidate() {
        cache.clear();
        registryCache.clear();
    }

    /** Platform Admin languages that ship a catalog, with their file path. */
    public StaticManifest manifest() {
        Registry registry = registry();
        List<StaticLanguage> languages = new ArrayList<>();
        for (Language language : languagesForClient("platform_admin")) {
            languages.add(new StaticLanguage(language.code(), language.name(),
                    language.nativeName(), language.direction(),
                    "platform_admin/" + language.code() + ".json"));
        }
        return new StaticManifest(registry.defaultLanguage(), List.copyOf(languages));
    }

    /**
     * Compares a client-language catalog against the English source. The
     * comparison covers {@code common} plus the namespace of the supplied path,
     * which is what the bundle actually merges.
     */
    public StaticCoverage coverage(String relativePath) {
        String clean = validateRelativePath(relativePath);
        String[] parts = clean.split("/");
        if (parts.length != 2) {
            throw new IllegalArgumentException("UI message path must be <namespace>/<code>.json");
        }
        String namespace = parts[0];
        String language = parts[1].endsWith(".json")
                ? parts[1].substring(0, parts[1].length() - ".json".length()) : parts[1];
        Map<String, String> source = new TreeMap<>();
        source.putAll(readFlatIfPresent(COMMON_NAMESPACE, DEFAULT_LANGUAGE));
        source.putAll(readFlatIfPresent(namespace, DEFAULT_LANGUAGE));
        Map<String, String> target = new TreeMap<>();
        target.putAll(readFlatIfPresent(COMMON_NAMESPACE, language));
        target.putAll(readFlatIfPresent(namespace, language));

        int missing = 0;
        int changed = 0;
        int placeholderMismatch = 0;
        for (Map.Entry<String, String> entry : source.entrySet()) {
            String value = target.get(entry.getKey());
            if (value == null) {
                missing++;
                continue;
            }
            if (!entry.getValue().equals(value)) {
                changed++;
            }
            if (!placeholders(entry.getValue()).equals(placeholders(value))) {
                placeholderMismatch++;
            }
        }
        return new StaticCoverage(source.size(), missing, changed, placeholderMismatch);
    }

    private Map<String, String> readFlatIfPresent(String namespace, String language) {
        String path = namespace + "/" + language + ".json";
        if (!exists(path)) {
            return Map.of();
        }
        return readFlat(resource(path), path);
    }

    public byte[] readBytes(String relativePath) {
        String clean = validateRelativePath(relativePath);
        Resource resource = resource(clean);
        try (InputStream stream = resource.getInputStream()) {
            return stream.readAllBytes();
        } catch (IOException error) {
            throw new IllegalStateException("Cannot read UI message file '" + clean
                    + "': " + error.getMessage(), error);
        }
    }

    public boolean exists(String relativePath) {
        String clean = validateRelativePath(relativePath);
        if (filesystemRoot) {
            return Files.isRegularFile(filesystemPath(clean));
        }
        return new ClassPathResource(CLASSPATH_ROOT + clean).exists();
    }

    private Registry readRegistry() {
        Resource resource = resource(REGISTRY_PATH);
        try (InputStream stream = resource.getInputStream()) {
            JsonNode root = objectMapper.readTree(stream);
            if (root == null || !root.isObject()) {
                throw new IllegalStateException("UI message registry must be a JSON object");
            }
            String defaultLanguage = root.path("defaultLanguage").asText(DEFAULT_LANGUAGE).trim();
            JsonNode languagesNode = root.get("languages");
            if (languagesNode == null || !languagesNode.isArray()) {
                throw new IllegalStateException("UI message registry must declare languages[]");
            }
            List<Language> languages = new ArrayList<>();
            Set<String> seen = new LinkedHashSet<>();
            for (JsonNode node : languagesNode) {
                String code = node.path("code").asText("").trim().toLowerCase(Locale.ROOT);
                if (code.isEmpty()) {
                    throw new IllegalStateException("UI message registry language is missing code");
                }
                if (!seen.add(code)) {
                    throw new IllegalStateException(
                            "Duplicate UI message registry language: " + code);
                }
                String name = node.path("name").asText(code);
                String nativeName = node.path("nativeName").asText(name);
                String direction = "rtl".equalsIgnoreCase(node.path("direction").asText("ltr"))
                        ? "rtl" : "ltr";
                languages.add(new Language(code, name, nativeName, direction));
            }
            if (languages.isEmpty()) {
                throw new IllegalStateException("UI message registry has no languages");
            }
            String effectiveDefault = languages.stream()
                    .anyMatch(language -> language.code().equalsIgnoreCase(defaultLanguage))
                    ? defaultLanguage.toLowerCase(Locale.ROOT) : languages.get(0).code();
            return new Registry(effectiveDefault, List.copyOf(languages));
        } catch (IOException error) {
            throw new IllegalStateException("Cannot read UI message registry '"
                    + REGISTRY_PATH + "': " + error.getMessage(), error);
        }
    }

    private NamespaceCatalog readNamespace(String namespace, String language, String relativePath) {
        if (!exists(relativePath)) {
            return new NamespaceCatalog(namespace, language, Map.of(), 1);
        }
        Map<String, String> values = readFlat(resource(relativePath), relativePath);
        Map<String, String> sorted = Collections.unmodifiableMap(new TreeMap<>(values));
        return new NamespaceCatalog(namespace, language, sorted, version(sorted));
    }

    private Map<String, String> readFlat(Resource resource, String label) {
        try (InputStream stream = resource.getInputStream()) {
            JsonNode root = objectMapper.readTree(stream);
            if (root == null || !root.isObject()) {
                throw new IllegalStateException("UI message file '" + label
                        + "' must be a flat JSON object");
            }
            Map<String, String> result = new TreeMap<>();
            root.fields().forEachRemaining(entry -> {
                if (entry.getKey() == null || entry.getKey().isBlank()) {
                    throw new IllegalStateException("UI message file '" + label
                            + "' contains a blank key");
                }
                if (!entry.getValue().isTextual()) {
                    throw new IllegalStateException("UI message file '" + label
                            + "' must be flat: value for '" + entry.getKey()
                            + "' is not a string");
                }
                result.put(entry.getKey(), entry.getValue().asText());
            });
            return result;
        } catch (IOException error) {
            throw new IllegalStateException("Cannot read UI message file '" + label
                    + "' from " + resource.getDescription() + ": " + error.getMessage(), error);
        }
    }

    private long lastModified(String relativePath) {
        try {
            Path filesystem = filesystemPath(relativePath);
            if (!Files.isRegularFile(filesystem)) {
                return -1L;
            }
            return Files.getLastModifiedTime(filesystem).toMillis();
        } catch (IOException | IllegalArgumentException error) {
            return -1L;
        }
    }

    private Resource resource(String relativePath) {
        if (filesystemRoot) {
            return new FileSystemResource(filesystemPath(relativePath));
        }
        return new ClassPathResource(CLASSPATH_ROOT + relativePath);
    }

    private Path filesystemPath(String relativePath) {
        String clean = validateRelativePath(relativePath);
        Path base = Path.of(directory).toAbsolutePath().normalize();
        Path resolved = base.resolve(clean).normalize();
        if (!resolved.startsWith(base)) {
            throw new IllegalArgumentException("UI message path escapes the configured directory");
        }
        return resolved;
    }

    /**
     * Accepts either the catalog root or the legacy platform_admin directory and
     * resolves to the directory that actually holds {@code languages.json}.
     */
    private static String resolveRoot(String configured) {
        if (configured == null || configured.isBlank()) {
            return "";
        }
        Path candidate = Path.of(configured.trim()).toAbsolutePath().normalize();
        if (Files.isRegularFile(candidate.resolve(REGISTRY_PATH))) {
            return candidate.toString();
        }
        Path parent = candidate.getParent();
        if (parent != null && Files.isRegularFile(parent.resolve(REGISTRY_PATH))) {
            return parent.toString();
        }
        return candidate.toString();
    }

    public static String validateRelativePath(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("UI message path is required");
        }
        String value = raw.trim().replace('\\', '/');
        if (value.startsWith("/") || value.matches("^[A-Za-z]:.*")
                || value.indexOf('\0') >= 0) {
            throw new IllegalArgumentException("UI message path must be relative: " + raw);
        }
        Path path = Path.of(value);
        for (Path segment : path) {
            if ("..".equals(segment.toString())) {
                throw new IllegalArgumentException("UI message path traversal is not allowed: "
                        + raw);
            }
        }
        Path normalized = path.normalize();
        if (normalized.isAbsolute() || normalized.startsWith("..")) {
            throw new IllegalArgumentException("UI message path is invalid: " + raw);
        }
        return normalized.toString().replace('\\', '/');
    }

    /** Stable positive version derived from the catalog content. */
    public static int version(Map<String, String> values) {
        if (values == null || values.isEmpty()) {
            return 1;
        }
        StringBuilder canonical = new StringBuilder();
        values.forEach((key, value) -> canonical
                .append(key).append('\u0000').append(value).append('\u0001'));
        return Math.max(1, positiveInt(canonical.toString()));
    }

    private static Set<String> placeholders(String value) {
        Set<String> names = new java.util.TreeSet<>();
        java.util.regex.Matcher matcher =
                java.util.regex.Pattern.compile("\\{(\\w+)}").matcher(value);
        while (matcher.find()) {
            names.add(matcher.group(1));
        }
        return names;
    }

    private static int positiveInt(String value) {
        byte[] hash = sha256(value);
        int result = ((hash[0] & 0x7f) << 24)
                | ((hash[1] & 0xff) << 16)
                | ((hash[2] & 0xff) << 8)
                | (hash[3] & 0xff);
        return result & 0x7fffffff;
    }

    private static byte[] sha256(String value) {
        try {
            return MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException(error);
        }
    }
}
