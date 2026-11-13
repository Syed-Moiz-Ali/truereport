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

@Component
public class PlatformUiMessageCatalog {

    public static final String EXTERNAL_DIRECTORY_PROPERTY = "truereport.i18n.platform-admin-dir";

    public static final List<String> NAMESPACE_ORDER = List.of("platform_admin", "common");
    public static final Set<String> NAMESPACES = Set.copyOf(NAMESPACE_ORDER);

    private static final String CLASSPATH_ROOT = "i18n/platform_admin/";
    private static final String MANIFEST_FILE = "manifest.json";

    public record Definition(String code, String name, String nativeName,
                             String direction, String file) {
    }

    public record Language(Definition definition,
                           Map<String, Map<String, String>> catalogs,
                           Map<String, Integer> versions,
                           String etag) {
    }

    public record Snapshot(String defaultLanguage, List<Language> languages, String etag) {

        public Language defaultCatalog() {
            return language(defaultLanguage);
        }

        public Language language(String code) {
            if (code == null || code.isBlank()) {
                return null;
            }
            for (Language language : languages) {
                if (language.definition().code().equals(code)) {
                    return language;
                }
            }
            for (Language language : languages) {
                if (language.definition().code().equalsIgnoreCase(code)) {
                    return language;
                }
            }
            return null;
        }
    }

    private final ObjectMapper objectMapper;
    private final String externalDirectory;
    private volatile Snapshot snapshot;

    public PlatformUiMessageCatalog(
            ObjectMapper objectMapper,
            @Value("${" + EXTERNAL_DIRECTORY_PROPERTY + ":}") String externalDirectory) {
        this.objectMapper = objectMapper;
        this.externalDirectory = externalDirectory == null ? "" : externalDirectory.trim();
    }

    @PostConstruct
    void loadOnStartup() {
        reload();
    }

    public Snapshot snapshot() {
        Snapshot current = snapshot;
        if (current == null) {
            synchronized (this) {
                current = snapshot;
                if (current == null) {
                    current = read();
                    snapshot = current;
                }
            }
        }
        return current;
    }

    public synchronized Snapshot reload() {
        Snapshot loaded = read();
        snapshot = loaded;
        return loaded;
    }

    private Snapshot read() {
        JsonNode manifest = readJson(resource(MANIFEST_FILE), MANIFEST_FILE);
        if (!manifest.isObject()) {
            throw new IllegalStateException("Platform UI message manifest must be a JSON object: "
                    + MANIFEST_FILE);
        }
        String defaultLanguage = text(manifest, "defaultLanguage", MANIFEST_FILE);
        JsonNode languageNodes = manifest.get("languages");
        if (languageNodes == null || !languageNodes.isArray() || languageNodes.isEmpty()) {
            throw new IllegalStateException(
                    "Platform UI message manifest must define at least one language: "
                            + MANIFEST_FILE);
        }
        List<Definition> definitions = new ArrayList<>();
        Set<String> codes = new LinkedHashSet<>();
        for (JsonNode node : languageNodes) {
            Definition definition = definition(node);
            if (!codes.add(definition.code())) {
                throw new IllegalStateException("Duplicate UI message language code '"
                        + definition.code() + "' in " + MANIFEST_FILE);
            }
            definitions.add(definition);
        }
        if (!codes.contains(defaultLanguage)) {
            throw new IllegalStateException("Default UI message language '" + defaultLanguage
                    + "' is not listed in " + MANIFEST_FILE);
        }

        List<Language> languages = new ArrayList<>();
        for (Definition definition : definitions) {
            Map<String, Map<String, String>> catalogs = loadCatalogs(definition);
            Map<String, Integer> versions = new LinkedHashMap<>();
            for (String namespace : NAMESPACE_ORDER) {
                versions.put(namespace, namespaceVersion(catalogs.get(namespace)));
            }
            languages.add(new Language(definition, catalogs, versions, languageEtag(definition, catalogs)));
        }
        return new Snapshot(defaultLanguage, List.copyOf(languages), manifestEtag(defaultLanguage, languages));
    }

    private Definition definition(JsonNode node) {
        if (node == null || !node.isObject()) {
            throw new IllegalStateException("Each language entry in " + MANIFEST_FILE
                    + " must be a JSON object");
        }
        String code = text(node, "code", MANIFEST_FILE);
        String file = text(node, "file", MANIFEST_FILE);
        String name = text(node, "name", MANIFEST_FILE);
        String nativeName = text(node, "nativeName", MANIFEST_FILE);
        String direction = text(node, "direction", MANIFEST_FILE).toLowerCase(Locale.ROOT);
        if (!direction.equals("ltr") && !direction.equals("rtl")) {
            throw new IllegalStateException("UI message language '" + code
                    + "' direction must be ltr or rtl in " + MANIFEST_FILE);
        }
        return new Definition(code, name, nativeName, direction, file);
    }

    private Map<String, Map<String, String>> loadCatalogs(Definition definition) {
        Resource resource = resource(definition.file());
        JsonNode root = readJson(resource, definition.file());
        if (!root.isObject()) {
            throw new IllegalStateException("UI message language file '" + definition.file()
                    + "' for '" + definition.code() + "' must be a flat JSON object");
        }
        Map<String, Map<String, String>> catalogs = new LinkedHashMap<>();
        for (String namespace : NAMESPACE_ORDER) {
            catalogs.put(namespace, new TreeMap<>());
        }
        root.fields().forEachRemaining(entry -> {
            String qualified = entry.getKey();
            JsonNode value = entry.getValue();
            if (qualified == null || qualified.isBlank()) {
                throw new IllegalStateException("UI message language file '" + definition.file()
                        + "' contains a blank key");
            }
            if (!value.isTextual()) {
                throw new IllegalStateException("UI message language file '" + definition.file()
                        + "' must be flat: value for '" + qualified + "' is not a string");
            }
            String namespace = namespaceOf(qualified);
            String key = messageKeyOf(qualified);
            catalogs.get(namespace).put(key, value.asText());
        });
        Map<String, Map<String, String>> immutable = new LinkedHashMap<>();
        catalogs.forEach((namespace, values) ->
                immutable.put(namespace, Collections.unmodifiableMap(values)));
        return Collections.unmodifiableMap(immutable);
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

    private JsonNode readJson(Resource resource, String label) {
        try (InputStream stream = resource.getInputStream()) {
            JsonNode node = objectMapper.readTree(stream);
            if (node == null) {
                throw new IllegalStateException("UI message file '" + label + "' is empty");
            }
            return node;
        } catch (IOException error) {
            throw new IllegalStateException("Cannot read UI message file '" + label
                    + "' from " + resource.getDescription() + ": " + error.getMessage(), error);
        }
    }

    private Resource resource(String file) {
        if (!externalDirectory.isBlank()) {
            return new FileSystemResource(Path.of(externalDirectory).resolve(file));
        }
        return new ClassPathResource(CLASSPATH_ROOT + file);
    }

    private static String text(JsonNode node, String field, String label) {
        JsonNode value = node.get(field);
        if (value == null || !value.isTextual() || value.asText().isBlank()) {
            throw new IllegalStateException("UI message file '" + label
                    + "' requires a non-blank string field '" + field + "'");
        }
        return value.asText();
    }

    private static int namespaceVersion(Map<String, String> catalog) {
        if (catalog == null || catalog.isEmpty()) {
            return 1;
        }
        StringBuilder canonical = new StringBuilder();
        catalog.forEach((key, value) -> canonical
                .append(key).append('\u0000').append(value).append('\u0001'));
        int version = positiveInt(canonical.toString());
        return Math.max(1, version);
    }

    private static String languageEtag(Definition definition,
                                       Map<String, Map<String, String>> catalogs) {
        StringBuilder canonical = new StringBuilder();
        canonical.append(definition.code()).append('|')
                .append(definition.name()).append('|')
                .append(definition.nativeName()).append('|')
                .append(definition.direction());
        catalogs.forEach((namespace, values) -> {
            canonical.append('|').append(namespace);
            values.forEach((key, value) -> canonical
                    .append('\u0000').append(key).append('\u0001').append(value));
        });
        return quote(sha256(canonical.toString()));
    }

    private static String manifestEtag(String defaultLanguage, List<Language> languages) {
        StringBuilder canonical = new StringBuilder("manifest|").append(defaultLanguage);
        languages.stream()
                .sorted((left, right) -> left.definition().code()
                        .compareTo(right.definition().code()))
                .forEach(language -> canonical
                        .append('|').append(language.definition().code())
                        .append(':').append(language.definition().direction())
                        .append(':').append(language.definition().nativeName())
                        .append(':').append(language.definition().name())
                        .append(':').append(language.etag()));
        return quote(sha256(canonical.toString()));
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
