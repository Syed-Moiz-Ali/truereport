package com.truereport;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.ApiExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.BeanUtils;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase C0 Workstream C (server i18n): API errors must return stable {@code code} +
 * {@code messageKey} properties so the client can map them to ARB strings. The English
 * {@code detail} text is diagnostic only and is never shown to end users.
 */
class ApiErrorContractTest {

    private final ApiExceptionHandler handler = new ApiExceptionHandler();

    private MockHttpServletRequest request() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/test");
        request.setRequestURI("/api/v1/test");
        return request;
    }

    private MockHttpServletRequest platformRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest(
                "GET", "/api/v1/platform/i18n/languages");
        request.setRequestURI("/api/v1/platform/i18n/languages");
        return request;
    }

    private MockHttpServletRequest platformAdminClientRequest(String path) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", path);
        request.setRequestURI(path);
        request.addHeader("X-Client", "platform_admin");
        return request;
    }

    @Test
    void apiExceptionPreservesStableCodeAndMessageKey() {
        ApiException exception = new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                "error.report.notReady", "The report is not ready");
        ResponseEntity<ProblemDetail> response = handler.handleApi(exception, request());

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody()).isNotNull();
        Map<String, Object> properties = response.getBody().getProperties();
        assertThat(properties.get("code")).isEqualTo("REPORT_NOT_READY");
        assertThat(properties.get("messageKey")).isEqualTo("error.report.notReady");
        assertThat(properties).containsKey("traceId");
        assertThat(response.getBody().getInstance()).isNotNull();
    }

    @Test
    void reportAndDeliveryErrorFactoriesUseStableCodes() {
        assertThat(ApiException.notFound().code()).isEqualTo("NOT_FOUND");
        assertThat(ApiException.notFound().messageKey()).isEqualTo("error.notFound");
        assertThat(ApiException.forbidden().code()).isEqualTo("FORBIDDEN");
        assertThat(ApiException.forbidden().messageKey()).isEqualTo("error.forbidden");
        assertThat(ApiException.conflict("IDEMPOTENCY_KEY_REUSED", "reused").code())
                .isEqualTo("IDEMPOTENCY_KEY_REUSED");
        assertThat(ApiException.unauthorized("SESSION_EXPIRED", "expired").code())
                .isEqualTo("SESSION_EXPIRED");
    }

    @Test
    void validationFailuresExposeFieldMessageKeys() throws Exception {
        BindingResult binding = new BeanPropertyBindingResult(new Object(), "request");
        binding.addError(new FieldError("request", "channel", "BAD"));
        MethodParameter parameter = new MethodParameter(
                BeanUtils.class.getMethod("instantiateClass", Class.class), 0);
        MethodArgumentNotValidException exception =
                new MethodArgumentNotValidException(parameter, binding);

        ResponseEntity<ProblemDetail> response = handler.handleValidation(exception, request());

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
        assertThat(response.getBody().getProperties().get("code")).isEqualTo("VALIDATION_FAILED");
        assertThat(response.getBody().getProperties().get("messageKey"))
                .isEqualTo("error.validation.failed");
        @SuppressWarnings("unchecked")
        List<Map<String, String>> fields =
                (List<Map<String, String>>) response.getBody().getProperties().get("fieldErrors");
        assertThat(fields).hasSize(1);
        assertThat(fields.get(0).get("messageKey")).isEqualTo("error.field.invalid");
        assertThat(fields.get(0).get("field")).isEqualTo("channel");
    }

    @Test
    void notFoundAndBadRequestExposeStableCodes() {
        ResponseEntity<ProblemDetail> notFound = handler.handleNotFound(
                new NoResourceFoundException(HttpMethod.GET, "/missing", "No static resource /missing."), request());
        assertThat(notFound.getBody().getProperties().get("code")).isEqualTo("NOT_FOUND");
        assertThat(notFound.getBody().getProperties().get("messageKey")).isEqualTo("error.notFound");

        ResponseEntity<ProblemDetail> badRequest =
                handler.handleIllegalArgument(new IllegalArgumentException("bad"), request());
        assertThat(badRequest.getBody().getProperties().get("code")).isEqualTo("BAD_REQUEST");
        assertThat(badRequest.getBody().getProperties().get("messageKey"))
                .isEqualTo("error.badRequest");
    }

    @Test
    void platformAdminErrorsOmitLegacyBilingualFields() {
        ApiException exception = new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "TRANSLATION_REQUIRED", "error.translation.required", "Translation required",
                List.of(com.truereport.shared.error.FieldIssue.of("hi.label",
                        "TRANSLATION_REQUIRED", "error.translation.required")));
        ResponseEntity<ProblemDetail> response = handler.handleApi(exception, platformRequest());
        Map<String, Object> properties = response.getBody().getProperties();

        assertThat(properties.get("code")).isEqualTo("TRANSLATION_REQUIRED");
        assertThat(properties.get("messageKey")).isEqualTo("error.translation.required");
        assertThat(response.getBody().getDetail()).isNotBlank();
        assertThat(properties).containsKey("traceId");
        assertThat(properties).doesNotContainKeys("messageEn", "messageAr");

        @SuppressWarnings("unchecked")
        List<Map<String, String>> errors =
                (List<Map<String, String>>) properties.get("errors");
        assertThat(errors).hasSize(1);
        assertThat(errors.get(0).get("messageKey")).isEqualTo("error.translation.required");
        assertThat(errors.get(0)).doesNotContainKeys("messageEn", "messageAr");
    }

    @Test
    void platformAdminValidationErrorsOmitLegacyBilingualFields() throws Exception {
        BindingResult binding = new BeanPropertyBindingResult(new Object(), "request");
        binding.addError(new FieldError("request", "channel", "BAD"));
        MethodParameter parameter = new MethodParameter(
                BeanUtils.class.getMethod("instantiateClass", Class.class), 0);
        MethodArgumentNotValidException exception =
                new MethodArgumentNotValidException(parameter, binding);

        ResponseEntity<ProblemDetail> response = handler.handleValidation(
                exception, platformRequest());
        assertThat(response.getBody().getProperties().get("messageKey"))
                .isEqualTo("error.validation.failed");
        assertThat(response.getBody().getDetail()).isNotBlank();
        assertThat(response.getBody().getProperties())
                .doesNotContainKeys("messageEn", "messageAr");
        @SuppressWarnings("unchecked")
        List<Map<String, String>> fields =
                (List<Map<String, String>>) response.getBody().getProperties().get("fieldErrors");
        assertThat(fields.get(0)).doesNotContainKeys("messageEn", "messageAr");
    }

    @Test
    void platformAdminClientHeaderScopesAuthEndpointErrors() {
        ApiException exception = new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS",
                "error.auth.invalidCredentials", "Invalid credentials");

        ResponseEntity<ProblemDetail> response = handler.handleApi(
                exception, platformAdminClientRequest("/api/v1/auth/login"));

        Map<String, Object> properties = response.getBody().getProperties();
        assertThat(properties.get("code")).isEqualTo("INVALID_CREDENTIALS");
        assertThat(properties.get("messageKey")).isEqualTo("error.auth.invalidCredentials");
        assertThat(response.getBody().getDetail()).isNotBlank();
        assertThat(properties).doesNotContainKeys("messageEn", "messageAr");
    }

    @Test
    void platformAdminClientHeaderScopesValidationErrors() throws Exception {
        BindingResult binding = new BeanPropertyBindingResult(new Object(), "request");
        binding.addError(new FieldError("request", "email", "BAD"));
        MethodParameter parameter = new MethodParameter(
                BeanUtils.class.getMethod("instantiateClass", Class.class), 0);
        MethodArgumentNotValidException exception =
                new MethodArgumentNotValidException(parameter, binding);

        ResponseEntity<ProblemDetail> response = handler.handleValidation(
                exception, platformAdminClientRequest("/api/v1/auth/login"));

        assertThat(response.getBody().getProperties())
                .doesNotContainKeys("messageEn", "messageAr");
        @SuppressWarnings("unchecked")
        List<Map<String, String>> fields =
                (List<Map<String, String>>) response.getBody().getProperties().get("fieldErrors");
        assertThat(fields.get(0)).doesNotContainKeys("messageEn", "messageAr");
    }

    @Test
    void unmarkedClientStillReceivesLegacyBilingualFields() {
        ApiException exception = new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS",
                "error.auth.invalidCredentials", "Invalid credentials");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        request.setRequestURI("/api/v1/auth/login");

        ResponseEntity<ProblemDetail> response = handler.handleApi(exception, request);

        assertThat(response.getBody().getProperties())
                .containsKeys("messageEn", "messageAr");
    }
}
