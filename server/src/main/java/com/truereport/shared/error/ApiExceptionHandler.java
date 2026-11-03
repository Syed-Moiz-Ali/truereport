package com.truereport.shared.error;

import com.truereport.shared.web.RequestIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.net.URI;
import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ProblemDetail> handleApi(ApiException exception, HttpServletRequest request) {
        ProblemDetail detail = problem(exception.status(), exception.code(), exception.messageKey(),
                exception.getMessage(), request);
        return ResponseEntity.status(exception.status()).body(detail);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException exception,
                                                          HttpServletRequest request) {
        ProblemDetail detail = problem(HttpStatus.UNPROCESSABLE_ENTITY, "VALIDATION_FAILED",
                "error.validation.failed", "Validation failed", request);
        List<Map<String, String>> fields = exception.getBindingResult().getFieldErrors().stream()
                .map(this::fieldError)
                .toList();
        detail.setProperty("fieldErrors", fields);
        return ResponseEntity.unprocessableEntity().body(detail);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(NoResourceFoundException exception,
                                                        HttpServletRequest request) {
        ProblemDetail detail = problem(HttpStatus.NOT_FOUND, "NOT_FOUND", "error.notFound",
                "Not found", request);
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(detail);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ProblemDetail> handleIllegalArgument(IllegalArgumentException exception,
                                                               HttpServletRequest request) {
        ProblemDetail detail = problem(HttpStatus.BAD_REQUEST, "BAD_REQUEST", "error.badRequest",
                "Invalid request", request);
        return ResponseEntity.badRequest().body(detail);
    }

    private Map<String, String> fieldError(FieldError error) {
        return Map.of(
                "field", error.getField(),
                "code", error.getCode() == null ? "INVALID" : error.getCode(),
                "messageKey", "error.field.invalid"
        );
    }

    private ProblemDetail problem(HttpStatus status, String code, String messageKey,
                                  String detailText, HttpServletRequest request) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(status, detailText);
        detail.setType(URI.create("https://truereport.example/problems/" + code.toLowerCase()));
        detail.setTitle(status.getReasonPhrase());
        detail.setInstance(URI.create(request.getRequestURI()));
        detail.setProperty("code", code);
        detail.setProperty("messageKey", messageKey);
        detail.setProperty("traceId", MDC.get(RequestIdFilter.MDC_KEY));
        return detail;
    }
}
