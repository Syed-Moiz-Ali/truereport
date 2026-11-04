package com.truereport.delivery.api;

import jakarta.validation.constraints.NotBlank;

public record SendDeliveryRequest(
        @NotBlank String channel,
        @NotBlank String language
) {
}
