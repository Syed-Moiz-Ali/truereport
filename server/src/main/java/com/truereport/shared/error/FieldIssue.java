package com.truereport.shared.error;

/**
 * A single field-level validation issue.
 *
 * <p>{@code code} and {@code messageKey} are stable machine identifiers. When
 * {@code messageEn} is supplied it is used verbatim; otherwise the message key
 * is resolved against the English bundle.</p>
 */
public record FieldIssue(
        String field,
        String code,
        String messageKey,
        String messageEn,
        String detail
) {
    public static FieldIssue of(String field, String code, String messageKey) {
        return new FieldIssue(field, code, messageKey, null, null);
    }
}
