package com.truereport.uimessages;

import com.truereport.shared.i18n.ContentSourceCatalog;
import com.truereport.shared.i18n.LegacyContentSource;
import com.truereport.uimessages.PlatformUiMessageCatalog.NamespaceCatalog;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * English source text for static interface keys, exposed to the generic content
 * translation engine as the {@code UI_MESSAGE} entity type.
 *
 * <p>Entity ids are {@code namespace:key} where namespace is {@code common} or
 * one of the client namespaces. {@code common} keys are stored once, not once
 * per client, because every client bundle merges the common namespace.</p>
 */
@Component
public class UiMessageSourceCatalog implements LegacyContentSource {

    public static final String ENTITY_TYPE = "UI_MESSAGE";
    public static final String FIELD = "value";

    private final PlatformUiMessageCatalog catalog;

    public UiMessageSourceCatalog(PlatformUiMessageCatalog catalog) {
        this.catalog = catalog;
    }

    @Override
    public Set<String> entityTypes() {
        return Set.of(ENTITY_TYPE);
    }

    @Override
    public boolean lenientMachineGuards(String entityType) {
        return ENTITY_TYPE.equals(entityType);
    }

    @Override
    public int targetCount(String entityType) {
        return ENTITY_TYPE.equals(entityType) ? english().size() : 0;
    }

    @Override
    public boolean partOfContentScope() {
        return false;
    }

    @Override
    public boolean exists(String entityType, String entityId) {
        return ENTITY_TYPE.equals(entityType) && source(entityType, entityId, FIELD, "en") != null;
    }

    @Override
    public String source(String entityType, String entityId, String field, String sourceLang) {
        if (!ENTITY_TYPE.equals(entityType) || !FIELD.equals(field)) {
            return null;
        }
        String[] parts = split(entityId);
        if (parts == null) {
            return null;
        }
        Map<String, String> values = catalog.namespace(parts[0], "en").values();
        return values.get(parts[1]);
    }

    @Override
    public List<ContentSourceCatalog.Source> sources(String entityType, String field,
                                                     String sourceLang) {
        if (!ENTITY_TYPE.equals(entityType) || !FIELD.equals(field)) {
            return List.of();
        }
        return english().entrySet().stream()
                .map(entry -> new ContentSourceCatalog.Source(entry.getKey(), entry.getValue()))
                .toList();
    }

    /** Flat English map keyed by {@code namespace:key}. */
    public Map<String, String> english() {
        Map<String, String> result = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry
                : catalog.namespace("common", "en").values().entrySet()) {
            result.put("common:" + entry.getKey(), entry.getValue());
        }
        for (String client : PlatformUiMessageCatalog.CLIENTS) {
            NamespaceCatalog namespace = catalog.namespace(client, "en");
            for (Map.Entry<String, String> entry : namespace.values().entrySet()) {
                result.put(client + ":" + entry.getKey(), entry.getValue());
            }
        }
        return result;
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
