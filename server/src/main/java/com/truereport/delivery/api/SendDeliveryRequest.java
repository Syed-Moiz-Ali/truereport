package com.truereport.delivery.api;

import jakarta.validation.constraints.NotBlank;

/**
 * A delivery channel plus the language to render the customer message in.
 * {@code language} is optional at the annotation level so a blank value reaches
 * the service and returns {@code LANGUAGE_INVALID} (422) instead of a generic
 * request-validation 400.
 */
public record SendDeliveryRequest(
        @NotBlank String channel,
        String language
) {
}
