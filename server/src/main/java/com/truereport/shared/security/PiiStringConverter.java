package com.truereport.shared.security;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class PiiStringConverter implements AttributeConverter<String, String> {

    private static volatile PiiCipher cipher;

    static void register(PiiCipher value) {
        cipher = value;
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        requireCipher();
        return cipher.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        requireCipher();
        return cipher.decrypt(dbData);
    }

    private void requireCipher() {
        if (cipher == null) {
            throw new IllegalStateException("PII cipher has not been initialized");
        }
    }
}
