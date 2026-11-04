package com.truereport.shared.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PiiCipher {

    private final PiiCrypto crypto;

    public PiiCipher(@Value("${truereport.pii.keys:}") String keys,
                     @Value("${truereport.pii.active-key-id:v1}") String activeKeyId,
                     @Value("${truereport.encryption.key:}") String fallbackKey) {
        this.crypto = PiiCrypto.fromStrings(keys, fallbackKey, activeKeyId);
        if (this.crypto == null) {
            throw new IllegalStateException("APP_PII_KEYS or APP_ENCRYPTION_KEY is required");
        }
        PiiStringConverter.register(this);
    }

    public String encrypt(String value) {
        return crypto.encrypt(value);
    }

    public String decrypt(String value) {
        return crypto.decrypt(value);
    }

    public String activeKeyId() {
        return crypto.activeKeyId();
    }
}
