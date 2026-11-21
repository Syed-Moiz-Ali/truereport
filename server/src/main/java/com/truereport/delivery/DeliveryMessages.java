package com.truereport.delivery;

import java.text.MessageFormat;
import java.util.Locale;
import java.util.MissingResourceException;
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
        return new Message(value(language, "link.subject"),
                format(value(language, "link.body"), language, reportNumber, url));
    }

    public static Message forEmail(String language, String reportNumber) {
        return new Message(value(language, "email.subject"),
                format(value(language, "email.body"), language, reportNumber));
    }

    private static String format(String pattern, String language, Object... args) {
        return new MessageFormat(pattern, locale(language)).format(args);
    }

    private static String value(String language, String key) {
        ResourceBundle target = target(language);
        if (target.containsKey(key)) {
            return target.getString(key);
        }
        return english().getString(key);
    }

    private static ResourceBundle target(String language) {
        Locale locale = locale(language);
        if (Locale.ENGLISH.equals(locale)) {
            return english();
        }
        try {
            return ResourceBundle.getBundle(BASE_NAME, locale);
        } catch (MissingResourceException exception) {
            return english();
        }
    }

    private static ResourceBundle english() {
        return ResourceBundle.getBundle(BASE_NAME, Locale.ENGLISH);
    }

    private static Locale locale(String language) {
        if (language == null || language.isBlank()) {
            return Locale.ENGLISH;
        }
        return Locale.forLanguageTag(language.trim().toLowerCase(Locale.ROOT));
    }

    public record Message(String subject, String body) {
    }
}
