package com.truereport.shared.error;

import com.truereport.shared.web.RequestIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.net.URI;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Locale ARABIC = Locale.forLanguageTag("ar");
    private static final Locale ENGLISH = Locale.ENGLISH;
    private static final String CLIENT_HEADER = "X-Client";
    private static final String PLATFORM_ADMIN_CLIENT = "platform_admin";

    private final MessageSource messageSource;
    private final org.springframework.web.servlet.LocaleResolver localeResolver;

    /** Kept for plain unit tests that instantiate the handler directly. */
    public ApiExceptionHandler() {
        this(null, null);
    }

    @org.springframework.beans.factory.annotation.Autowired
    public ApiExceptionHandler(MessageSource messageSource,
                               org.springframework.web.servlet.LocaleResolver localeResolver) {
        this.messageSource = messageSource;
        this.localeResolver = localeResolver;
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ProblemDetail> handleApi(ApiException exception, HttpServletRequest request) {
        Locale requested = resolveLocale(request);
        boolean platformAdmin = isPlatformAdmin(request);
        String messageEn = resolve(exception.messageKey(), ENGLISH, exception.getMessage());
        String messageAr = resolve(exception.messageKey(), ARABIC, exception.getMessage());
        String detailText = platformAdmin
                ? messageEn
                : resolve(exception.messageKey(), requested, exception.getMessage());

        ProblemDetail detail = problem(exception.status(), exception.code(), exception.messageKey(),
                detailText, messageEn, messageAr, request);
        if (!exception.issues().isEmpty()) {
            List<Map<String, String>> errors = new ArrayList<>();
            for (FieldIssue issue : exception.issues()) {
                String issueEn = issue.messageEn() != null
                        ? issue.messageEn()
                        : resolve(issue.messageKey(), ENGLISH, issue.code());
                String issueAr = issue.messageAr() != null
                        ? issue.messageAr()
                        : resolve(issue.messageKey(), ARABIC, issueEn);
                Map<String, String> mapped = new LinkedHashMap<>();
                mapped.put("field", issue.field());
                mapped.put("code", issue.code());
                mapped.put("messageKey", issue.messageKey());
                if (!platformAdmin) {
                    mapped.put("messageEn", issueEn);
                    mapped.put("messageAr", issueAr);
                }
                errors.add(mapped);
            }
            detail.setProperty("errors", errors);
            detail.setProperty("fieldErrors", errors);
        }
        return ResponseEntity.status(exception.status()).body(detail);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException exception,
                                                          HttpServletRequest request) {
        Locale requested = resolveLocale(request);
        boolean platformAdmin = isPlatformAdmin(request);
        String messageEn = resolve("error.validation.failed", ENGLISH, "Validation failed");
        String messageAr = resolve("error.validation.failed", ARABIC, messageEn);
        String detailText = platformAdmin
                ? messageEn
                : resolve("error.validation.failed", requested, messageEn);
        ProblemDetail detail = problem(HttpStatus.UNPROCESSABLE_ENTITY, "VALIDATION_FAILED",
                "error.validation.failed", detailText, messageEn, messageAr, request);
        List<Map<String, String>> fields = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> fieldError(error, messageEn, messageAr, platformAdmin))
                .toList();
        detail.setProperty("fieldErrors", fields);
        detail.setProperty("errors", fields);
        return ResponseEntity.unprocessableEntity().body(detail);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(NoResourceFoundException exception,
                                                        HttpServletRequest request) {
        Locale requested = resolveLocale(request);
        boolean platformAdmin = isPlatformAdmin(request);
        String messageEn = resolve("error.notFound", ENGLISH, "Not found");
        String messageAr = resolve("error.notFound", ARABIC, messageEn);
        ProblemDetail detail = problem(HttpStatus.NOT_FOUND, "NOT_FOUND", "error.notFound",
                platformAdmin ? messageEn : resolve("error.notFound", requested, messageEn),
                messageEn, messageAr, request);
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(detail);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ProblemDetail> handleIllegalArgument(IllegalArgumentException exception,
                                                               HttpServletRequest request) {
        Locale requested = resolveLocale(request);
        boolean platformAdmin = isPlatformAdmin(request);
        String messageEn = resolve("error.badRequest", ENGLISH, "Invalid request");
        String messageAr = resolve("error.badRequest", ARABIC, messageEn);
        ProblemDetail detail = problem(HttpStatus.BAD_REQUEST, "BAD_REQUEST", "error.badRequest",
                platformAdmin ? messageEn : resolve("error.badRequest", requested, messageEn),
                messageEn, messageAr, request);
        return ResponseEntity.badRequest().body(detail);
    }

    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<ProblemDetail> handleDataIntegrity(
            org.springframework.dao.DataIntegrityViolationException exception,
            HttpServletRequest request) {
        Locale requested = resolveLocale(request);
        boolean platformAdmin = isPlatformAdmin(request);
        String messageEn = resolve("error.dataIntegrity", ENGLISH, "The change violates a data constraint");
        String messageAr = resolve("error.dataIntegrity", ARABIC, messageEn);
        ProblemDetail detail = problem(HttpStatus.CONFLICT, "DATA_INTEGRITY_VIOLATION",
                "error.dataIntegrity",
                platformAdmin ? messageEn : resolve("error.dataIntegrity", requested, messageEn),
                messageEn, messageAr, request);
        return ResponseEntity.status(HttpStatus.CONFLICT).body(detail);
    }

    private Map<String, String> fieldError(FieldError error, String messageEn,
                                           String messageAr, boolean platformAdmin) {
        Map<String, String> mapped = new LinkedHashMap<>();
        mapped.put("field", error.getField());
        mapped.put("code", error.getCode() == null ? "INVALID" : error.getCode());
        mapped.put("messageKey", "error.field.invalid");
        if (!platformAdmin) {
            mapped.put("messageEn", messageEn);
            mapped.put("messageAr", messageAr);
        }
        return mapped;
    }

    private ProblemDetail problem(HttpStatus status, String code, String messageKey,
                                  String detailText, String messageEn, String messageAr,
                                  HttpServletRequest request) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(status, detailText);
        detail.setType(URI.create("https://truereport.example/problems/" + code.toLowerCase()));
        detail.setTitle(status.getReasonPhrase());
        detail.setInstance(URI.create(request.getRequestURI()));
        detail.setProperty("code", code);
        detail.setProperty("messageKey", messageKey);
        if (!isPlatformAdmin(request)) {
            detail.setProperty("messageEn", messageEn);
            detail.setProperty("messageAr", messageAr);
        }
        detail.setProperty("traceId", MDC.get(RequestIdFilter.MDC_KEY));
        return detail;
    }

    private boolean isPlatformAdmin(HttpServletRequest request) {
        String uri = request.getRequestURI();
        if (uri != null && uri.startsWith("/api/v1/platform/")) {
            return true;
        }
        String client = request.getHeader(CLIENT_HEADER);
        return PLATFORM_ADMIN_CLIENT.equalsIgnoreCase(client == null ? null : client.trim());
    }

    private Locale resolveLocale(HttpServletRequest request) {
        if (localeResolver != null) {
            try {
                Locale resolved = localeResolver.resolveLocale(request);
                if (resolved != null) {
                    return resolved;
                }
            } catch (RuntimeException ignored) {
                // fall through to the request header
            }
        }
        String header = request.getHeader("Accept-Language");
        if (header != null && !header.isBlank()) {
            String tag = header.split(",")[0].split(";")[0].trim();
            if (!tag.isBlank()) {
                return Locale.forLanguageTag(tag);
            }
        }
        return ENGLISH;
    }

    private String resolve(String key, Locale locale, String fallback) {
        if (messageSource == null || key == null) {
            return fallback;
        }
        try {
            String resolved = messageSource.getMessage(key, null, locale);
            return resolved == null || resolved.isBlank() ? fallback : resolved;
        } catch (RuntimeException ignored) {
            return fallback;
        }
    }
}
