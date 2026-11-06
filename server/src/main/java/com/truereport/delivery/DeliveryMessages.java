package com.truereport.delivery;

import java.text.MessageFormat;
import java.util.Locale;
import java.util.ResourceBundle;

/**
 * User-facing delivery (SMS/WhatsApp/email) text.
 *
 * <p>All wording lives in per-language bundles ({@code i18n/delivery_en.properties},
 * {@code i18n/delivery_ar.properties}) with {@link MessageFormat} placeholders
 * ({@code {0}} = report number, {@code {1}} = public link). No literal user-facing
 * text may be added here; add a key to both bundles instead.
 */
public final class DeliveryMessages {

    private static final String BASE_NAME = "i18n.delivery";

    private DeliveryMessages() {
    }

    public static Message forLink(String language, String reportNumber, String url) {
        ResourceBundle bundle = bundle(language);
        return new Message(bundle.getString("link.subject"),
                format(bundle.getString("link.body"), language, reportNumber, url));
    }

    public static Message forEmail(String language, String reportNumber) {
        ResourceBundle bundle = bundle(language);
        return new Message(bundle.getString("email.subject"),
                format(bundle.getString("email.body"), language, reportNumber));
    }

    private static String format(String pattern, String language, Object... args) {
        Locale locale = "ar".equals(language) ? new Locale("ar") : Locale.ENGLISH;
        return new MessageFormat(pattern, locale).format(args);
    }

    private static ResourceBundle bundle(String language) {
        Locale locale = "ar".equals(language) ? new Locale("ar") : Locale.ENGLISH;
        return ResourceBundle.getBundle(BASE_NAME, locale);
    }

    public record Message(String subject, String body) {
    }
}
