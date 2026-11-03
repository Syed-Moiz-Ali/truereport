package com.truereport.shared.storage;

import java.net.URI;
import java.time.Duration;

/**
 * Provider-neutral object-storage boundary. D6 production storage is Pending;
 * the implementation will use an S3-compatible provider. MinIO is local-only.
 */
public interface ObjectStorage {

    void put(String key, byte[] content, String contentType);

    byte[] get(String key);

    URI presignedGet(String key, Duration ttl);

    URI presignedPut(String key, Duration ttl, String contentType);

    void delete(String key);
}
