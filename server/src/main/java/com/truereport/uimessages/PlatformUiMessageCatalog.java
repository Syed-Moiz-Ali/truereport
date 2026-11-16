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
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class PlatformUiMessageCatalog {

    public static final String DIRECTORY_PROPERTY = "truereport.i18n.ui-messages-dir";
    public static final String SOURCE_LANGUAGE = "en";
    public static final String SOURCE_PATH = "platform_admin/en.json";
    public static final String MANIFEST_PATH = "platform_admin/manifest.json";

    public static final List<String> NAMESPACE_ORDER = List.of("platform_admin", "common");
    public static final Set<String> NAMESPACES = Set.copyOf(NAMESPACE_ORDER);

    private static final String CLASSPATH_ROOT = "i18n/";
    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");

    public record LanguageCatalog(
            String path,
            Map<String, String> flat,
            Map<String, Map<String, String>> catalogs,
            Map<String, Integer> versions,
            String etag) {
    }

    /**
     * One static language declared by {@code manifest.json}. The manifest is
     * the single source of truth for static UI languages; no database row or
     * publish step is involved.
     */
    public record StaticLanguage(
            String code,
            String name,
            String nativeName,
            String direction,
            String file) {
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

    private record CacheEntry(LanguageCatalog catalog, long modifiedAt) {
    }

    private record ManifestCacheEntry(StaticManifest manifest, long modifiedAt) {
    }

    private final ObjectMapper objectMapper;
    private final String directory;
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private final Map<String, ManifestCacheEntry> manifestCache = new ConcurrentHashMap<>();

    public PlatformUiMessageCatalog(
            ObjectMapper objectMapper,
            @Value("${" + DIRECTORY_PROPERTY
                    + ":src/main/resources/i18n/platform_admin}") String directory) {
        this.objectMapper = objectMapper;
        this.directory = directory == null ? "" : directory.trim();
    }

    @PostConstruct
    void validateOnStartup() {
        validateRelativePath(SOURCE_PATH);
        manifest();
    }

    public LanguageCatalog load(String relativePath) {
        String clean = validateRelativePath(relativePath);
        long modifiedAt = lastModified(clean);
        CacheEntry existing = cache.get(clean);
        if (existing != null && existing.modifiedAt() == modifiedAt) {
            return existing.catalog();
        }
        synchronized (this) {
            CacheEntry current = cache.get(clean);
            if (current != null && current.modifiedAt() == modifiedAt) {
                return current.catalog();
            }
            LanguageCatalog catalog = readCatalog(clean);
            cache.put(clean, new CacheEntry(catalog, modifiedAt));
            return catalog;
        }
    }

    private long lastModified(String relativePath) {
        Path filesystem = filesystemPath(relativePath);
        if (!Files.isRegularFile(filesystem)) {
            return -1L;
        }
        try {
            return Files.getLastModifiedTime(filesystem).toMillis();
        } catch (IOException error) {
            return -1L;
        }
    }

    public Map<String, String> loadFlat(String relativePath) {
        return load(relativePath).flat();
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
        Path filesystem = filesystemPath(clean);
        if (Files.isRegularFile(filesystem)) {
            return true;
        }
        return new ClassPathResource(CLASSPATH_ROOT + clean).exists();
    }

    public void invalidate() {
        cache.clear();
        manifestCache.clear();
    }

    /** Reads {@code manifest.json}; the source of truth for static languages. */
    public StaticManifest manifest() {
        long modifiedAt = lastModified(MANIFEST_PATH);
        ManifestCacheEntry existing = manifestCache.get(MANIFEST_PATH);
        if (existing != null && existing.modifiedAt() == modifiedAt) {
            return existing.manifest();
        }
        synchronized (this) {
            ManifestCacheEntry current = manifestCache.get(MANIFEST_PATH);
            if (current != null && current.modifiedAt() == modifiedAt) {
                return current.manifest();
            }
            StaticManifest manifest = readManifest();
            manifestCache.put(MANIFEST_PATH, new ManifestCacheEntry(manifest, modifiedAt));
            return manifest;
        }
    }

    /**
     * Compares a static catalog against the default catalog. Missing keys are
     * reported individually; placeholder mismatches are counted separately.
     */
    public StaticCoverage coverage(String relativePath) {
        Map<String, String> source = loadFlat(SOURCE_PATH);
        Map<String, String> target;
        try {
            target = loadFlat(relativePath);
        } catch (RuntimeException missing) {
            target = Map.of();
        }
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

    private StaticManifest readManifest() {
        Resource resource = resource(MANIFEST_PATH);
        try (InputStream stream = resource.getInputStream()) {
            JsonNode root = objectMapper.readTree(stream);
            if (root == null || !root.isObject()) {
                throw new IllegalStateException("UI message manifest must be a JSON object");
            }
            String defaultLanguage = root.path("defaultLanguage").asText("en");
            JsonNode languagesNode = root.get("languages");
            if (languagesNode == null || !languagesNode.isArray()) {
                throw new IllegalStateException("UI message manifest must declare languages[]");
            }
            List<StaticLanguage> languages = new ArrayList<>();
            Set<String> seen = new java.util.LinkedHashSet<>();
            for (JsonNode node : languagesNode) {
                String code = node.path("code").asText("").trim();
                if (code.isEmpty()) {
                    throw new IllegalStateException("UI message manifest language is missing code");
                }
                if (!seen.add(code.toLowerCase(Locale.ROOT))) {
                    throw new IllegalStateException(
                            "Duplicate UI message manifest language: " + code);
                }
                String file = validateRelativePath(node.path("file").asText(""));
                if (!file.startsWith("platform_admin/")) {
                    file = "platform_admin/" + file;
                }
                String name = node.path("name").asText(code);
                String nativeName = node.path("nativeName").asText(name);
                String direction = node.path("direction").asText("ltr");
                String normalizedDirection = direction.equalsIgnoreCase("rtl") ? "rtl" : "ltr";
                languages.add(new StaticLanguage(code, name, nativeName,
                        normalizedDirection, file));
            }
            if (languages.isEmpty()) {
                throw new IllegalStateException("UI message manifest has no languages");
            }
            String configuredDefault = defaultLanguage;
            String effectiveDefault = languages.stream()
                    .anyMatch(language -> language.code().equals(configuredDefault))
                    ? configuredDefault : languages.get(0).code();
            return new StaticManifest(effectiveDefault, List.copyOf(languages));
        } catch (IOException error) {
            throw new IllegalStateException("Cannot read UI message manifest '"
                    + MANIFEST_PATH + "': " + error.getMessage(), error);
        }
    }

    private LanguageCatalog readCatalog(String relativePath) {
        Map<String, String> flat = readFlat(resource(relativePath), relativePath);
        Map<String, Map<String, String>> catalogs = new LinkedHashMap<>();
        for (String namespace : NAMESPACE_ORDER) {
            catalogs.put(namespace, new TreeMap<>());
        }
        flat.forEach((qualified, value) -> {
            String namespace = namespaceOf(qualified);
            String key = messageKeyOf(qualified);
            catalogs.get(namespace).put(key, value);
        });
        Map<String, Map<String, String>> immutable = new LinkedHashMap<>();
        catalogs.forEach((namespace, values) ->
                immutable.put(namespace, Collections.unmodifiableMap(values)));
        Map<String, Integer> versions = new LinkedHashMap<>();
        for (String namespace : NAMESPACE_ORDER) {
            versions.put(namespace, namespaceVersion(immutable.get(namespace)));
        }
        return new LanguageCatalog(relativePath, Collections.unmodifiableMap(flat),
                Collections.unmodifiableMap(immutable), Collections.unmodifiableMap(versions),
                etag(relativePath, immutable));
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

    private Resource resource(String relativePath) {
        Path filesystem = filesystemPath(relativePath);
        if (Files.isRegularFile(filesystem)) {
            return new FileSystemResource(filesystem);
        }
        return new ClassPathResource(CLASSPATH_ROOT + relativePath);
    }

    private Path filesystemPath(String relativePath) {
        String clean = validateRelativePath(relativePath);
        Path base = Path.of(directory).toAbsolutePath().normalize();
        String withinBase = clean;
        Path first = Path.of(clean).getName(0);
        if (base.getFileName() != null
                && base.getFileName().toString().equals(first.toString())) {
            withinBase = clean.substring(first.toString().length() + 1);
        }
        Path resolved = base.resolve(withinBase).normalize();
        if (!resolved.startsWith(base)) {
            throw new IllegalArgumentException("UI message path escapes the configured directory");
        }
        return resolved;
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

    private static String namespaceOf(String qualified) {
        int dot = qualified.indexOf('.');
        if (dot > 0) {
            String candidate = qualified.substring(0, dot);
            if (NAMESPACES.contains(candidate)) {
                return candidate;
            }
        }
        return NAMESPACE_ORDER.get(0);
    }

    private static String messageKeyOf(String qualified) {
        int dot = qualified.indexOf('.');
        if (dot > 0 && NAMESPACES.contains(qualified.substring(0, dot))) {
            return qualified.substring(dot + 1);
        }
        return qualified;
    }

    private static int namespaceVersion(Map<String, String> catalog) {
        if (catalog == null || catalog.isEmpty()) {
            return 1;
        }
        StringBuilder canonical = new StringBuilder();
        catalog.forEach((key, value) -> canonical
                .append(key).append('\u0000').append(value).append('\u0001'));
        return Math.max(1, positiveInt(canonical.toString()));
    }

    private static String etag(String path, Map<String, Map<String, String>> catalogs) {
        StringBuilder canonical = new StringBuilder(path);
        catalogs.forEach((namespace, values) -> {
            canonical.append('|').append(namespace);
            values.forEach((key, value) -> canonical
                    .append('\u0000').append(key).append('\u0001').append(value));
        });
        return quote(sha256(canonical.toString()));
    }

    private static Set<String> placeholders(String value) {
        Set<String> names = new java.util.TreeSet<>();
        Matcher matcher = PLACEHOLDER.matcher(value);
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

    private static String quote(byte[] hash) {
        StringBuilder hex = new StringBuilder(hash.length * 2);
        for (byte value : hash) {
            hex.append(Character.forDigit((value >> 4) & 0xF, 16));
            hex.append(Character.forDigit(value & 0xF, 16));
        }
        return "\"" + hex + "\"";
    }
}
