package com.truereport.shared.i18n;

import java.util.List;

/** 409 gate failure with a machine-readable issue list. */
public class TranslationReviewRequiredException extends RuntimeException {

    public record Issue(String entityType, String entityId, String field, String lang,
                        String reason) {
    }

    private final List<Issue> issues;

    public TranslationReviewRequiredException(List<Issue> issues) {
        super("Translation review required");
        this.issues = List.copyOf(issues);
    }

    public List<Issue> issues() {
        return issues;
    }
}
