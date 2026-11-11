package com.truereport.shared.error;

/**
 * A single, bilingual field-level validation issue.
 *
 * <p>{@code code} and {@code messageKey} are stable machine identifiers. When
 * {@code messageEn}/{@code messageAr} are supplied they are used verbatim;
 * otherwise the message key is resolved against the localized bundles.</p>
 */
public record FieldIssue(
        String field,
        String code,
        String messageKey,
        String messageEn,
        String messageAr,
        String detail
) {
    public static FieldIssue of(String field, String code, String messageKey) {
        return new FieldIssue(field, code, messageKey, null, null, null);
    }
}
