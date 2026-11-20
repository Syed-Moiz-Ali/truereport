package com.truereport.delivery;

import java.text.MessageFormat;
import java.util.Locale;
import java.util.ResourceBundle;

/**
 * User-facing delivery (SMS/WhatsApp/email) text.
 *
 * <p>All wording lives in the English bundle ({@code i18n/delivery_en.properties})
 * with {@link MessageFormat} placeholders
 * ({@code {0}} = report number, {@code {1}} = public link). No literal user-facing
 * text may be added here; add a key to the bundle instead.
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
        return new MessageFormat(pattern, Locale.ENGLISH).format(args);
    }

    private static ResourceBundle bundle(String language) {
        // Delivery bundles are English-only; the parameter keeps the call sites
        // language-aware for future catalog support.
        return ResourceBundle.getBundle(BASE_NAME, Locale.ENGLISH);
    }

    public record Message(String subject, String body) {
    }
}
