package com.truereport.shared.i18n;

/**
 * Hook for modules that must react to a content-review decision.
 *
 * <p>Kept in this module so the review service never imports UI-message or
 * other presentation modules directly.</p>
 */
public interface ContentReviewListener {

    default void reviewed(String entityType, String entityId, String lang, String status,
                          String body) {
    }

    default void bulkApproved(String lang, java.util.List<String> entityTypes) {
    }
}
