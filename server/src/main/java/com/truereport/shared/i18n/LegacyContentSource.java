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

    /**
     * True when machine-translation guards tuned for prose must relax for this
     * entity type. Short interface labels are legitimately identical across
     * languages ({@code Rotor} → {@code Rotor}) and often shrink to one word
     * ({@code Move down} → {@code Descendre}), so the "provider echoed English"
     * and "provider dropped content" checks would reject good translations.
     */
    default boolean lenientMachineGuards(String entityType) {
        return false;
    }

    /**
     * How many source values this entity type can translate, or 0 when the
     * count is unknown/expensive. The review desk uses it to tell "nothing is
     * happening" apart from "nothing is translated yet".
     */
    default int targetCount(String entityType) {
        return 0;
    }

    /**
     * False when this source's entity types are interface text rather than
     * business content, so the {@code CONTENT} scope never counts them.
     */
    default boolean partOfContentScope() {
        return true;
    }
}
