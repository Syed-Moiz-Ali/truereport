package com.truereport.delivery;

import java.util.List;

public interface DeliveryProvider {

    String name();

    DeliveryResult send(DeliveryMessage message);

    record DeliveryMessage(
            String channel,
            String recipient,
            String language,
            String subject,
            String body,
            String reportNumber,
            byte[] pdf,
            String pdfFilename
    ) {
    }

    record DeliveryResult(
            boolean accepted,
            String providerMessageId,
            String errorCode,
            String errorMessage,
            boolean delivered
    ) {
        public static DeliveryResult sent(String providerMessageId) {
            return new DeliveryResult(true, providerMessageId, null, null, false);
        }

        public static DeliveryResult delivered(String providerMessageId) {
            return new DeliveryResult(true, providerMessageId, null, null, true);
        }

        public static DeliveryResult failed(String errorCode, String errorMessage) {
            return new DeliveryResult(false, null, errorCode, errorMessage, false);
        }
    }

    record DeliveryMessageList(List<DeliveryMessage> messages) {
    }
}
