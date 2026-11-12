package com.truereport.localization;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.web.servlet.LocaleResolver;

import java.util.Locale;

/**
 * Accept-Language + {@code ?lang} resolution for API responses and errors.
 * Resolution order: {@code ?lang}, Accept-Language, English.
 */
@Configuration
public class LocaleConfig {

    @Bean
    public MessageSource messageSource() {
        ResourceBundleMessageSource source = new ResourceBundleMessageSource();
        source.setBasename("i18n/messages");
        source.setDefaultEncoding("UTF-8");
        source.setFallbackToSystemLocale(false);
        source.setUseCodeAsDefaultMessage(false);
        return source;
    }

    @Bean
    public LocaleResolver localeResolver() {
        return new QueryParamLocaleResolver();
    }

    static final class QueryParamLocaleResolver implements LocaleResolver {

        @Override
        public Locale resolveLocale(HttpServletRequest request) {
            String lang = request.getParameter("lang");
            if (lang != null && !lang.isBlank()) {
                return Locale.forLanguageTag(lang.trim());
            }
            String header = request.getHeader("Accept-Language");
            if (header != null && !header.isBlank()) {
                String tag = header.split(",")[0].split(";")[0].trim();
                if (!tag.isBlank()) {
                    return Locale.forLanguageTag(tag);
                }
            }
            return Locale.ENGLISH;
        }

        @Override
        public void setLocale(HttpServletRequest request, HttpServletResponse response, Locale locale) {
            // Stateless API: locale is resolved per request only.
        }
    }
}
