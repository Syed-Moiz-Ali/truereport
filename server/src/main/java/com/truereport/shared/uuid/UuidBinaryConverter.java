package com.truereport.shared.uuid;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.nio.ByteBuffer;
import java.util.UUID;

@Converter(autoApply = true)
public class UuidBinaryConverter implements AttributeConverter<UUID, byte[]> {

    @Override
    public byte[] convertToDatabaseColumn(UUID attribute) {
        if (attribute == null) {
            return null;
        }
        return ByteBuffer.allocate(16)
                .putLong(attribute.getMostSignificantBits())
                .putLong(attribute.getLeastSignificantBits())
                .array();
    }

    @Override
    public UUID convertToEntityAttribute(byte[] dbData) {
        if (dbData == null) {
            return null;
        }
        if (dbData.length != 16) {
            throw new IllegalArgumentException("UUID BINARY column must be 16 bytes, got " + dbData.length);
        }
        ByteBuffer buffer = ByteBuffer.wrap(dbData);
        return new UUID(buffer.getLong(), buffer.getLong());
    }
}
