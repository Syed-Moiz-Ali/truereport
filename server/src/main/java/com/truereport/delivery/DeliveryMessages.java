package com.truereport.delivery;

public final class DeliveryMessages {

    private DeliveryMessages() {
    }

    public static Message forLink(String language, String reportNumber, String url) {
        if ("ar".equals(language)) {
            return new Message("تقرير فحص المركبة جاهز",
                    "تقرير فحص المركبة جاهز. معرّف التقرير: " + reportNumber + ". الرابط: " + url);
        }
        return new Message("Vehicle inspection report ready",
                "Your vehicle inspection report is ready. Report ID: " + reportNumber
                        + ". Link: " + url);
    }

    public static Message forEmail(String language, String reportNumber) {
        if ("ar".equals(language)) {
            return new Message("تقرير فحص المركبة جاهز",
                    "تقرير فحص المركبة جاهز. معرّف التقرير: " + reportNumber
                            + ". الترجمة العربية قيد المراجعة.");
        }
        return new Message("Vehicle inspection report ready",
                "Your vehicle inspection report is ready. Report ID: " + reportNumber
                        + ". The attached PDF is the report. The Arabic wording is pending native review.");
    }

    public record Message(String subject, String body) {
    }
}
