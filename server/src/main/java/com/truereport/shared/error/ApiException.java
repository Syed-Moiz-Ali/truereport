package com.truereport.shared.error;

import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final String messageKey;

    public ApiException(HttpStatus status, String code, String messageKey, String message) {
        super(message);
        this.status = status;
        this.code = code;
        this.messageKey = messageKey;
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
}
