package com.truereport.identity;

import com.truereport.shared.error.ApiException;
import org.springframework.http.HttpStatus;

/**
 * Initial/admin-set password policy for Phase C0 Workstream A.
 *
 * <p>Rules: 12-128 chars, at least one upper-case, one lower-case, one digit
 * and one non-alphanumeric character. The password value is never included in
 * the thrown message.
 */
public final class PasswordPolicy {

    private PasswordPolicy() {
    }

    public static void requireValid(String password) {
        if (!isValid(password)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "PASSWORD_POLICY_VIOLATION",
                    "error.password.policy", "Password does not meet the security policy");
        }
    }

    public static boolean isValid(String password) {
        if (password == null || password.length() < 12 || password.length() > 128) {
            return false;
        }
        boolean upper = false;
        boolean lower = false;
        boolean digit = false;
        boolean special = false;
        for (int i = 0; i < password.length(); i++) {
            char c = password.charAt(i);
            if (Character.isUpperCase(c)) {
                upper = true;
            } else if (Character.isLowerCase(c)) {
                lower = true;
            } else if (Character.isDigit(c)) {
                digit = true;
            } else {
                special = true;
            }
        }
        return upper && lower && digit && special;
    }
}
