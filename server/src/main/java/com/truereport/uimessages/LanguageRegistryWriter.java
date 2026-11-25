package com.truereport.uimessages;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Keeps {@code i18n/languages.json} in step with the language registry.
 *
 * <p>The manifest, the language selector and the per-app UI catalogs are all
 * driven by that file, so adding a language in the admin console must write it
 * here; otherwise the new language exists in the database but never reaches the
 * client. Writes are atomic and invalidate the catalog cache.</p>
 */
@Service
public class LanguageRegistryWriter {

    private static final Logger log = LoggerFactory.getLogger(LanguageRegistryWriter.class);
    private static final String REGISTRY_FILE = "languages.json";

    private final PlatformUiMessageCatalog catalog;
    private final ObjectMapper objectMapper;

    public LanguageRegistryWriter(PlatformUiMessageCatalog catalog, ObjectMapper objectMapper) {
        this.catalog = catalog;
        this.objectMapper = objectMapper;
    }

    /** Adds or refreshes one language in the registry file. */
    public boolean register(String code, String name, String nativeName, String direction) {
        if (code == null || code.isBlank()) {
            return false;
        }
        String normalized = code.trim();
        return write(registry -> {
            List<Map<String, Object>> languages = languages(registry);
            Map<String, Object> entry = null;
            for (Map<String, Object> candidate : languages) {
                if (normalized.equalsIgnoreCase(String.valueOf(candidate.get("code")))) {
                    entry = candidate;
                    break;
                }
            }
            if (entry == null) {
                entry = new LinkedHashMap<>();
                entry.put("code", normalized);
                languages.add(entry);
            }
            entry.put("name", blankTo(name, normalized));
            entry.put("nativeName", blankTo(nativeName, normalized));
            entry.put("direction", "rtl".equalsIgnoreCase(direction) ? "rtl" : "ltr");
            registry.put("languages", languages);
        });
    }

    /** Drops a retired language so it stops being advertised. */
    public boolean unregister(String code) {
        if (code == null || code.isBlank()) {
            return false;
        }
        String normalized = code.trim();
        return write(registry -> {
            List<Map<String, Object>> languages = languages(registry);
            languages.removeIf(candidate ->
                    normalized.equalsIgnoreCase(String.valueOf(candidate.get("code"))));
            registry.put("languages", languages);
        });
    }

    private boolean write(RegistryEdit edit) {
        Path root = catalog.writableRoot();
        if (root == null) {
            log.warn("UI message catalogs are not writable. Set UI_MESSAGES_DIR so a new "
                    + "language can be added to languages.json.");
            return false;
        }
        Path file = root.resolve(REGISTRY_FILE);
        synchronized (this) {
            try {
                Map<String, Object> registry = read(file);
                edit.apply(registry);
                Path temp = file.resolveSibling("." + file.getFileName() + ".tmp");
                objectMapper.writerWithDefaultPrettyPrinter().writeValue(temp.toFile(), registry);
                try {
                    Files.move(temp, file, StandardCopyOption.REPLACE_EXISTING,
                            StandardCopyOption.ATOMIC_MOVE);
                } catch (IOException atomicFailure) {
                    Files.move(temp, file, StandardCopyOption.REPLACE_EXISTING);
                }
                catalog.invalidate();
                return true;
            } catch (IOException exception) {
                log.warn("Could not write the language registry {}: {}", file,
                        exception.getMessage());
                return false;
            }
        }
    }

    private Map<String, Object> read(Path file) throws IOException {
        if (!Files.exists(file)) {
            Map<String, Object> empty = new LinkedHashMap<>();
            empty.put("defaultLanguage", PlatformUiMessageCatalog.DEFAULT_LANGUAGE);
            empty.put("languages", new ArrayList<Map<String, Object>>());
            return empty;
        }
        Map<String, Object> registry = objectMapper.readValue(file.toFile(),
                new TypeReference<LinkedHashMap<String, Object>>() {
                });
        if (registry.get("defaultLanguage") == null) {
            registry.put("defaultLanguage", PlatformUiMessageCatalog.DEFAULT_LANGUAGE);
        }
        return registry;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> languages(Map<String, Object> registry) {
        Object raw = registry.get("languages");
        List<Map<String, Object>> languages = new ArrayList<>();
        if (raw instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> map) {
                    languages.add((Map<String, Object>) map);
                }
            }
        }
        return languages;
    }

    private static String blankTo(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    @FunctionalInterface
    private interface RegistryEdit {
        void apply(Map<String, Object> registry);
    }
}
