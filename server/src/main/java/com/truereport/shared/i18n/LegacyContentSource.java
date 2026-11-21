package com.truereport.shared.i18n;

import java.util.List;
import java.util.Set;

/**
 * Implemented by modules that keep their English source text outside the clean
 * {@code platform_*} tables (for example the legacy {@code localized_content}
 * store). The generic translation engine never imports those modules directly.
 */
public interface LegacyContentSource {

    Set<String> entityTypes();

    boolean exists(String entityType, String entityId);

    String source(String entityType, String entityId, String field, String sourceLang);

    List<ContentSourceCatalog.Source> sources(String entityType, String field, String sourceLang);

    default boolean updateSource(String entityType, String entityId, String field, String text,
                                 String sourceLang) {
        return false;
    }
}
