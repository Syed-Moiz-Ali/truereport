package com.truereport.shared.i18n;

import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * Facade used by write services: canonical writes trigger FROM_CANONICAL jobs,
 * authoring-language writes store the authored text and trigger TO_CANONICAL.
 */
@Service
public class ContentAuthoring {

    private final ContentChangePublisher changes;
    private final LanguageCatalog languages;
    private final RequestLanguageContext context;

    public ContentAuthoring(ContentChangePublisher changes, LanguageCatalog languages,
                            RequestLanguageContext context) {
        this.changes = changes;
        this.languages = languages;
        this.context = context;
    }

    public String language() {
        return languages.normalize(context.authoringLanguage());
    }

    public boolean isCanonical() {
        return language().equals(languages.defaultLanguage());
    }

    public String defaultLanguage() {
        return languages.defaultLanguage();
    }

    public void publish(String entityType, String entityId, Map<String, String> fields) {
        if (fields.isEmpty()) {
            return;
        }
        if (isCanonical()) {
            fields.forEach((field, text) ->
                    changes.fieldChanged(entityType, entityId, field, text));
        } else {
            String lang = language();
            fields.forEach((field, text) ->
                    changes.authored(entityType, entityId, field, lang, text));
        }
    }
}
