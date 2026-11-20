package com.truereport.shared.text;

/**
 * Masking for customer names shown on public report pages.
 */
public final class CustomerNames {

    private CustomerNames() {
    }

    /**
     * Masks a customer name: {@code "E2E Customer"} becomes {@code "E2E C***"}.
     * Returns {@code null} when the input is blank so callers can omit the field.
     */
    public static String mask(String name) {
        if (name == null || name.isBlank()) {
            return null;
        }
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0] + "***";
        }
        return parts[0] + " " + Character.toUpperCase(parts[parts.length - 1].charAt(0)) + "***";
    }
}
