package com.truereport.shared.error;

import org.springframework.http.HttpStatus;

import java.util.List;

public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final String messageKey;
    private final List<FieldIssue> issues;

    public ApiException(HttpStatus status, String code, String messageKey, String message) {
        this(status, code, messageKey, message, List.of());
    }

    public ApiException(HttpStatus status, String code, String messageKey, String message,
                        List<FieldIssue> issues) {
        super(message);
        this.status = status;
        this.code = code;
        this.messageKey = messageKey;
        this.issues = issues == null ? List.of() : List.copyOf(issues);
    }

    public HttpStatus status() {
        return status;
    }

    public String code() {
        return code;
    }

    public String messageKey() {
        return messageKey;
    }

    public List<FieldIssue> issues() {
        return issues;
    }

    public static ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", "error.notFound", "Not found");
    }

    public static ApiException forbidden() {
        return new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "error.forbidden", "Forbidden");
    }

    public static ApiException unauthorized(String code, String message) {
        return new ApiException(HttpStatus.UNAUTHORIZED, code, "error.unauthorized", message);
    }

    public static ApiException conflict(String code, String message) {
        return new ApiException(HttpStatus.CONFLICT, code, "error.conflict", message);
    }

    public static ApiException unprocessable(String code, String message) {
        return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, code, "error.validation.failed", message);
    }

    public static ApiException validation(String code, String message, List<FieldIssue> issues) {
        return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, code, "error.validation.failed",
                message, issues);
    }

    public static ApiException versionConflict(String message) {
        return new ApiException(HttpStatus.CONFLICT, "VERSION_CONFLICT", "error.versionConflict", message);
    }
}
