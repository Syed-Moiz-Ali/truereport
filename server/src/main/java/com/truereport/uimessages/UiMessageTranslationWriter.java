package com.truereport.uimessages;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.i18n.ContentReviewListener;
import com.truereport.shared.i18n.ContentTranslationStore;
import com.truereport.shared.i18n.ContentTranslationStore.UiMessageRow;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Writes approved interface translations back into the JSON catalogs.
 *
 * <p>Static UI text is still served from {@code i18n/<namespace>/<lang>.json}
 * files. The review desk approves rows in {@code content_translation}; this
 * listener mirrors those approvals into the catalogs, so a language can gain a
 * UI catalog through the normal translation pipeline instead of a manual file
 * drop.</p>
 */
@Component
public class UiMessageTranslationWriter implements ContentReviewListener {

    private static final Logger log = LoggerFactory.getLogger(UiMessageTranslationWriter.class);

    private final PlatformUiMessageCatalog catalog;
    private final ContentTranslationStore translations;
    private final ObjectMapper objectMapper;
    private volatile boolean warned;

    public UiMessageTranslationWriter(PlatformUiMessageCatalog catalog,
                                      ContentTranslationStore translations,
                                      ObjectMapper objectMapper) {
        this.catalog = catalog;
        this.translations = translations;
        this.objectMapper = objectMapper;
    }

    @Override
    public void reviewed(String entityType, String entityId, String lang, String status,
                         String body) {
        if (!UiMessageSourceCatalog.ENTITY_TYPE.equals(entityType)
                || !"REVIEWED".equals(status)
                || body == null || body.isBlank()) {
            return;
        }
        writeOne(entityId, lang, body);
    }

    @Override
    public void bulkApproved(String lang, List<String> entityTypes) {
        if (entityTypes != null && !entityTypes.isEmpty()
                && !entityTypes.contains(UiMessageSourceCatalog.ENTITY_TYPE)) {
            return;
        }
        List<UiMessageRow> rows = translations.reviewedUiMessages(lang);
        if (rows.isEmpty()) {
            return;
        }
        Map<String, Map<String, String>> byNamespace = new LinkedHashMap<>();
        for (UiMessageRow row : rows) {
            String[] parts = split(row.entityId());
            if (parts == null) {
                continue;
            }
            byNamespace.computeIfAbsent(parts[0], key -> new LinkedHashMap<>())
                    .put(parts[1], row.body());
        }
        for (Map.Entry<String, Map<String, String>> entry : byNamespace.entrySet()) {
            writeFile(entry.getKey(), lang, entry.getValue());
        }
    }

    private void writeOne(String entityId, String lang, String body) {
        String[] parts = split(entityId);
        if (parts == null) {
            return;
        }
        writeFile(parts[0], lang, Map.of(parts[1], body));
    }

    private void writeFile(String namespace, String lang, Map<String, String> values) {
        Path root = catalog.writableRoot();
        if (root == null) {
            if (!warned) {
                warned = true;
                log.warn("UI message catalogs are not writable. Set UI_MESSAGES_DIR to a writable "
                        + "directory to publish approved interface translations.");
            }
            return;
        }
        Path file = root.resolve(namespace).resolve(lang + ".json");
        synchronized (this) {
            try {
                Files.createDirectories(file.getParent());
                Map<String, Object> json = Files.exists(file)
                        ? objectMapper.readValue(file.toFile(),
                                new TypeReference<LinkedHashMap<String, Object>>() {
                                })
                        : new LinkedHashMap<>();
                json.putAll(values);
                Path temp = file.resolveSibling("." + file.getFileName() + ".tmp");
                objectMapper.writerWithDefaultPrettyPrinter().writeValue(temp.toFile(), json);
                try {
                    Files.move(temp, file, StandardCopyOption.REPLACE_EXISTING,
                            StandardCopyOption.ATOMIC_MOVE);
                } catch (IOException atomicFailure) {
                    Files.move(temp, file, StandardCopyOption.REPLACE_EXISTING);
                }
            } catch (IOException exception) {
                log.warn("Could not write UI message catalog {}: {}", file, exception.getMessage());
            }
        }
    }

    private static String[] split(String entityId) {
        if (entityId == null) {
            return null;
        }
        int colon = entityId.indexOf(':');
        if (colon <= 0 || colon == entityId.length() - 1) {
            return null;
        }
        String namespace = entityId.substring(0, colon);
        if (!"common".equals(namespace)
                && !PlatformUiMessageCatalog.CLIENTS.contains(namespace)) {
            return null;
        }
        return new String[]{namespace, entityId.substring(colon + 1)};
    }
}
