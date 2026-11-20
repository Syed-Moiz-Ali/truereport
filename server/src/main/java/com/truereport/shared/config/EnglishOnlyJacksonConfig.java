package com.truereport.shared.config;

import tools.jackson.databind.BeanDescription;
import tools.jackson.databind.SerializationConfig;
import tools.jackson.databind.module.SimpleModule;
import tools.jackson.databind.ser.BeanPropertyWriter;
import tools.jackson.databind.ser.ValueSerializerModifier;
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * English-only API surface: Arabic duplicate fields ({@code labelAr},
 * {@code messageAr}, {@code nameAr}, ...) are omitted from every JSON response.
 * The database columns and internal model stay intact for a possible future
 * bilingual release, but clients never receive Arabic content.
 */
@Configuration
public class EnglishOnlyJacksonConfig {

    @Bean
    JsonMapperBuilderCustomizer englishOnlyResponseFields() {
        SimpleModule module = new SimpleModule("english-only-fields");
        module.setSerializerModifier(new ValueSerializerModifier() {
            @Override
            public List<BeanPropertyWriter> changeProperties(SerializationConfig config,
                                                             BeanDescription.Supplier beanDesc,
                                                             List<BeanPropertyWriter> writers) {
                return new java.util.ArrayList<>(writers.stream()
                        .filter(writer -> !isArabicField(writer.getName()))
                        .toList());
            }
        });
        return builder -> builder.addModule(module);
    }

    private static boolean isArabicField(String name) {
        return name != null && (name.endsWith("Ar") || name.endsWith("AR"));
    }
}
