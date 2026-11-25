package com.truereport.localization;

import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * The closed list of languages an admin can add, so nobody has to invent a
 * language tag or guess the writing direction.
 *
 * <p>{@code code} is the BCP-47 tag used by the catalogs and the API,
 * {@code name} is the English label, {@code nativeName} is what the language
 * selector shows, and {@code direction} drives the Flutter {@code Directionality}
 * of every app.</p>
 */
@Component
public class WellKnownLanguages {

    public record KnownLanguage(String code, String name, String nativeName, String direction) {
    }

    private static final List<KnownLanguage> LANGUAGES = List.of(
            new KnownLanguage("ar", "Arabic", "العربية", "rtl"),
            new KnownLanguage("bg", "Bulgarian", "Български", "ltr"),
            new KnownLanguage("bn", "Bengali", "বাংলা", "ltr"),
            new KnownLanguage("ca", "Catalan", "Català", "ltr"),
            new KnownLanguage("cs", "Czech", "Čeština", "ltr"),
            new KnownLanguage("da", "Danish", "Dansk", "ltr"),
            new KnownLanguage("de", "German", "Deutsch", "ltr"),
            new KnownLanguage("el", "Greek", "Ελληνικά", "ltr"),
            new KnownLanguage("en", "English", "English", "ltr"),
            new KnownLanguage("es", "Spanish", "Español", "ltr"),
            new KnownLanguage("et", "Estonian", "Eesti", "ltr"),
            new KnownLanguage("fa", "Persian", "فارسی", "rtl"),
            new KnownLanguage("fi", "Finnish", "Suomi", "ltr"),
            new KnownLanguage("fr", "French", "Français", "ltr"),
            new KnownLanguage("he", "Hebrew", "עברית", "rtl"),
            new KnownLanguage("hi", "Hindi", "हिन्दी", "ltr"),
            new KnownLanguage("hr", "Croatian", "Hrvatski", "ltr"),
            new KnownLanguage("hu", "Hungarian", "Magyar", "ltr"),
            new KnownLanguage("id", "Indonesian", "Bahasa Indonesia", "ltr"),
            new KnownLanguage("it", "Italian", "Italiano", "ltr"),
            new KnownLanguage("ja", "Japanese", "日本語", "ltr"),
            new KnownLanguage("ko", "Korean", "한국어", "ltr"),
            new KnownLanguage("lt", "Lithuanian", "Lietuvių", "ltr"),
            new KnownLanguage("lv", "Latvian", "Latviešu", "ltr"),
            new KnownLanguage("ms", "Malay", "Bahasa Melayu", "ltr"),
            new KnownLanguage("nl", "Dutch", "Nederlands", "ltr"),
            new KnownLanguage("no", "Norwegian", "Norsk", "ltr"),
            new KnownLanguage("pl", "Polish", "Polski", "ltr"),
            new KnownLanguage("pt", "Portuguese", "Português", "ltr"),
            new KnownLanguage("pt-BR", "Portuguese (Brazil)", "Português (Brasil)", "ltr"),
            new KnownLanguage("ro", "Romanian", "Română", "ltr"),
            new KnownLanguage("ru", "Russian", "Русский", "ltr"),
            new KnownLanguage("sk", "Slovak", "Slovenčina", "ltr"),
            new KnownLanguage("sl", "Slovenian", "Slovenščina", "ltr"),
            new KnownLanguage("sr", "Serbian", "Српски", "ltr"),
            new KnownLanguage("sv", "Swedish", "Svenska", "ltr"),
            new KnownLanguage("sw", "Swahili", "Kiswahili", "ltr"),
            new KnownLanguage("ta", "Tamil", "தமிழ்", "ltr"),
            new KnownLanguage("th", "Thai", "ไทย", "ltr"),
            new KnownLanguage("tr", "Turkish", "Türkçe", "ltr"),
            new KnownLanguage("uk", "Ukrainian", "Українська", "ltr"),
            new KnownLanguage("ur", "Urdu", "اردو", "rtl"),
            new KnownLanguage("vi", "Vietnamese", "Tiếng Việt", "ltr"),
            new KnownLanguage("zh", "Chinese (Simplified)", "简体中文", "ltr"),
            new KnownLanguage("zh-Hant", "Chinese (Traditional)", "繁體中文", "ltr")
    );

    public List<KnownLanguage> all() {
        return LANGUAGES;
    }

    public Optional<KnownLanguage> find(String code) {
        if (code == null || code.isBlank()) {
            return Optional.empty();
        }
        String normalized = code.trim().toLowerCase(Locale.ROOT);
        return LANGUAGES.stream()
                .filter(language -> language.code().toLowerCase(Locale.ROOT).equals(normalized))
                .findFirst();
    }
}
