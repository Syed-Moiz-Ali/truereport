package com.truereport.uimessages;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.uimessages.api.UiMessagePublishGuard;
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
import java.nio.file.StandardCopyOption;
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
public class PlatformUiMessageCatalog implements UiMessagePublishGuard {

    public static final String DIRECTORY_PROPERTY = "truereport.i18n.ui-messages-dir";
    public static final String SOURCE_LANGUAGE = "en";
    public static final String SOURCE_PATH = "platform_admin/en.json";

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

    private record CacheEntry(LanguageCatalog catalog, long modifiedAt) {
    }

    private final ObjectMapper objectMapper;
    private final String directory;
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

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
    }

    public void requireWritable() {
        Path base = Path.of(directory).toAbsolutePath().normalize();
        try {
            Files.createDirectories(base);
        } catch (IOException error) {
            throw new IllegalStateException("Cannot create UI messages directory: " + base,
                    error);
        }
        if (!Files.isWritable(base)) {
            throw new IllegalStateException("UI messages directory is not writable: " + base);
        }
    }

    public Path writeAtomic(String relativePath, Map<String, String> values) {
        String clean = validateRelativePath(relativePath);
        Path target = filesystemPath(clean);
        Path parent = target.getParent();
        try {
            if (parent != null) {
                Files.createDirectories(parent);
            }
            if (parent == null || !Files.isWritable(parent)) {
                throw new IllegalStateException("UI messages directory is not writable: "
                        + (parent == null ? directory : parent));
            }
            TreeMap<String, String> ordered = new TreeMap<>(values);
            ObjectNode node = objectMapper.createObjectNode();
            ordered.forEach(node::put);
            Path temp = Files.createTempFile(parent, ".ui-messages-", ".json.tmp");
            try {
                objectMapper.writerWithDefaultPrettyPrinter().writeValue(temp.toFile(), node);
                Map<String, String> written = readFlat(new FileSystemResource(temp), temp.toString());
                if (!written.keySet().equals(ordered.keySet())) {
                    throw new IllegalStateException(
                            "Generated UI message file key parity failed before publish");
                }
                for (Map.Entry<String, String> entry : ordered.entrySet()) {
                    if (!entry.getValue().equals(written.get(entry.getKey()))) {
                        throw new IllegalStateException(
                                "Generated UI message file validation failed for '"
                                        + entry.getKey() + "'");
                    }
                }
                try {
                    Files.move(temp, target, StandardCopyOption.ATOMIC_MOVE,
                            StandardCopyOption.REPLACE_EXISTING);
                } catch (java.nio.file.AtomicMoveNotSupportedException unsupported) {
                    Files.move(temp, target, StandardCopyOption.REPLACE_EXISTING);
                }
                invalidate();
                return target;
            } finally {
                Files.deleteIfExists(temp);
            }
        } catch (IOException error) {
            throw new IllegalStateException("Cannot write UI message file '" + clean + "': "
                    + error.getMessage(), error);
        }
    }

    @Override
    public void requirePublishable(String languageCode, String uiMessagesPath,
                                   String defaultLanguagePath) {
        if (uiMessagesPath == null || uiMessagesPath.isBlank()) {
            throw missing(languageCode, "UI message JSON path is not configured");
        }
        LanguageCatalog target;
        try {
            target = load(uiMessagesPath);
        } catch (RuntimeException error) {
            throw missing(languageCode, error.getMessage());
        }
        String sourcePath = defaultLanguagePath == null || defaultLanguagePath.isBlank()
                ? SOURCE_PATH : defaultLanguagePath;
        LanguageCatalog source;
        try {
            source = load(sourcePath);
        } catch (RuntimeException error) {
            throw missing(languageCode, "Default UI message JSON is missing: "
                    + error.getMessage());
        }
        List<String> missing = new ArrayList<>(source.flat().keySet());
        missing.removeAll(target.flat().keySet());
        List<String> extra = new ArrayList<>(target.flat().keySet());
        extra.removeAll(source.flat().keySet());
        List<String> placeholderMismatch = new ArrayList<>();
        for (String key : source.flat().keySet()) {
            String translated = target.flat().get(key);
            if (translated == null) {
                continue;
            }
            if (!placeholders(source.flat().get(key)).equals(placeholders(translated))) {
                placeholderMismatch.add(key);
            }
        }
        if (!missing.isEmpty() || !extra.isEmpty() || !placeholderMismatch.isEmpty()) {
            List<FieldIssue> issues = new ArrayList<>();
            for (String key : missing) {
                issues.add(FieldIssue.of(key, "TRANSLATION_REQUIRED",
                        "error.translation.required"));
            }
            for (String key : extra) {
                issues.add(FieldIssue.of(key, "UI_MESSAGE_KEY_UNKNOWN",
                        "error.validation.failed"));
            }
            for (String key : placeholderMismatch) {
                issues.add(FieldIssue.of(key, "UI_MESSAGE_PLACEHOLDER_MISMATCH",
                        "error.validation.failed"));
            }
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "UI message JSON for " + languageCode + " is incomplete", issues);
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

    private static ApiException missing(String languageCode, String detail) {
        return ApiException.validation("TRANSLATION_REQUIRED",
                "UI message JSON for " + languageCode + " is not publishable: " + detail,
                List.of(FieldIssue.of("uiMessagesPath", "UI_MESSAGES_REQUIRED",
                        "error.translation.required")));
    }

    @SuppressWarnings("unused")
    private static String normalizeCode(String code) {
        return code == null ? "" : code.trim().toLowerCase(Locale.ROOT);
    }
}
