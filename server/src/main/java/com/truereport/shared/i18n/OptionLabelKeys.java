package com.truereport.shared.i18n;

import java.util.regex.Pattern;

/**
 * Deterministic catalog keys for option-set values.
 *
 * <p>The convention is {@code option.<lowerCamel(setCode)>.<lowerCamel(valueCode)>}
 * so {@code ISSUE_TYPE} / {@code WORN} becomes {@code option.issueType.worn}.
 * Keys are dotted lowerCamel and satisfy the same taxonomy as the backend
 * {@code common} catalog: {@code ^[a-z][A-Za-z0-9]*(\.[a-z][A-Za-z0-9]*)+$}.</p>
 */
public final class OptionLabelKeys {

    public static final String PATTERN = "^[a-z][A-Za-z0-9]*(\\.[a-z][A-Za-z0-9]*)+$";

    private static final Pattern VALID = Pattern.compile(PATTERN);

    private OptionLabelKeys() {
    }

    public static String generate(String optionSetCode, String valueCode) {
        return "option." + lowerCamel(optionSetCode) + "." + lowerCamel(valueCode);
    }

    public static boolean isValid(String key) {
        return key != null && VALID.matcher(key).matches();
    }

    /**
     * Converts an upper-snake code to lowerCamel: {@code FRONT_LEFT} -> {@code frontLeft},
     * {@code SAFETY_CRITICAL} -> {@code safetyCritical}. Non-alphanumeric separators
     * start a new segment; digits stay in the current segment.
     */
    private static String lowerCamel(String code) {
        if (code == null) {
            return "value";
        }
        StringBuilder result = new StringBuilder();
        boolean upperNext = false;
        for (int index = 0; index < code.length(); index++) {
            char character = code.charAt(index);
            boolean alphaNumeric = (character >= 'a' && character <= 'z')
                    || (character >= 'A' && character <= 'Z')
                    || (character >= '0' && character <= '9');
            if (!alphaNumeric) {
                if (result.length() > 0) {
                    upperNext = true;
                }
                continue;
            }
            if (result.length() == 0) {
                result.append(Character.toLowerCase(character));
            } else if (upperNext) {
                result.append(Character.toUpperCase(character));
                upperNext = false;
            } else {
                result.append(Character.toLowerCase(character));
            }
        }
        if (result.length() == 0) {
            return "value";
        }
        if (!Character.isLetter(result.charAt(0))) {
            result.insert(0, 'v');
        }
        return result.toString();
    }
}
