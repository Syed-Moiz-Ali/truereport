package com.truereport.shared.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Duration;

/**
 * Development/test-only storage behind the ObjectStorage boundary.
 * D6 production storage is Pending; production must use an S3-compatible provider.
 */
@Component
@ConditionalOnProperty(name = "truereport.storage.provider", havingValue = "local", matchIfMissing = true)
public class LocalObjectStorage implements ObjectStorage {

    private final Path root;

    public LocalObjectStorage(@Value("${truereport.storage.local-root:./.truereport-storage}") String root) {
        this.root = Path.of(root).toAbsolutePath().normalize();
    }

    @Override
    public void put(String key, byte[] content, String contentType) {
        try {
            Path target = resolve(key);
            Files.createDirectories(target.getParent());
            Files.write(target, content, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        } catch (IOException e) {
            throw new IllegalStateException("Unable to store object", e);
        }
    }

    @Override
    public byte[] get(String key) {
        try {
            return Files.readAllBytes(resolve(key));
        } catch (IOException e) {
            throw new IllegalStateException("Unable to read object", e);
        }
    }

    @Override
    public URI presignedGet(String key, Duration ttl) {
        // Local development only: the API streams guide images through an authorized endpoint.
        return URI.create("local://" + key);
    }

    @Override
    public URI presignedPut(String key, Duration ttl, String contentType) {
        return URI.create("local://" + key);
    }

    @Override
    public void delete(String key) {
        try {
            Files.deleteIfExists(resolve(key));
        } catch (IOException e) {
            throw new IllegalStateException("Unable to delete object", e);
        }
    }

    private Path resolve(String key) {
        Path path = root.resolve(key).normalize();
        if (!path.startsWith(root)) {
            throw new IllegalArgumentException("Invalid object key");
        }
        return path;
    }
}
