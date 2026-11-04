package com.truereport.shared.storage;

import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.BucketAlreadyOwnedByYouException;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.ServerSideEncryption;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.net.URI;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;
import java.util.Map;

/**
 * Production-oriented S3-compatible storage. Provider selection is D6 and remains
 * a deployment decision; this adapter does not select or contract a cloud vendor.
 */
@Component
@ConditionalOnProperty(name = "truereport.storage.provider", havingValue = "s3")
public class S3ObjectStorage implements ObjectStorage {

    private final S3Client client;
    private final S3Presigner presigner;
    private final String bucket;
    private final String sseAlgorithm;
    private final String kmsKeyId;

    public S3ObjectStorage(
            @Value("${truereport.storage.s3.endpoint:}") String endpoint,
            @Value("${truereport.storage.s3.region:auto}") String region,
            @Value("${truereport.storage.s3.bucket:}") String bucket,
            @Value("${truereport.storage.s3.access-key:}") String accessKey,
            @Value("${truereport.storage.s3.secret-key:}") String secretKey,
            @Value("${truereport.storage.s3.path-style:true}") boolean pathStyle,
            @Value("${truereport.storage.s3.create-bucket:false}") boolean createBucket,
            @Value("${truereport.storage.s3.sse:}") String sseAlgorithm,
            @Value("${truereport.storage.s3.kms-key-id:}") String kmsKeyId) {
        if (bucket == null || bucket.isBlank()) {
            throw new IllegalStateException("S3 bucket is required when STORAGE_PROVIDER=s3");
        }
        if (accessKey == null || accessKey.isBlank() || secretKey == null || secretKey.isBlank()) {
            throw new IllegalStateException("S3 credentials are required when STORAGE_PROVIDER=s3");
        }
        this.bucket = bucket;
        this.sseAlgorithm = sseAlgorithm == null ? "" : sseAlgorithm.trim();
        this.kmsKeyId = kmsKeyId == null ? "" : kmsKeyId.trim();
        S3Configuration configuration = S3Configuration.builder()
                .pathStyleAccessEnabled(pathStyle)
                .build();
        var builder = S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKey, secretKey)))
                .serviceConfiguration(configuration);
        var presignerBuilder = S3Presigner.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKey, secretKey)))
                .serviceConfiguration(configuration);
        if (endpoint != null && !endpoint.isBlank()) {
            builder.endpointOverride(URI.create(endpoint));
            presignerBuilder.endpointOverride(URI.create(endpoint));
        }
        this.client = builder.build();
        this.presigner = presignerBuilder.build();
        if (createBucket) {
            ensureBucket();
        }
    }

    private void ensureBucket() {
        try {
            client.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
        } catch (RuntimeException missing) {
            try {
                client.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
            } catch (BucketAlreadyOwnedByYouException ignored) {
                // Another instance created it concurrently.
            }
        }
    }

    @Override
    public void put(String key, byte[] content, String contentType) {
        validateKey(key);
        String checksum = sha256(content);
        PutObjectRequest.Builder request = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(contentType)
                .metadata(Map.of("sha256", checksum));
        applyEncryption(request);
        client.putObject(request.build(), RequestBody.fromBytes(content));
    }

    @Override
    public byte[] get(String key) {
        validateKey(key);
        var response = client.getObjectAsBytes(GetObjectRequest.builder()
                .bucket(bucket).key(key).build());
        byte[] content = response.asByteArray();
        String expected = response.response().metadata().get("sha256");
        if (expected != null && !expected.isBlank() && !expected.equals(sha256(content))) {
            throw new IllegalStateException("Object checksum mismatch for key");
        }
        return content;
    }

    @Override
    public URI presignedGet(String key, Duration ttl) {
        validateKey(key);
        return URI.create(presigner.presignGetObject(GetObjectPresignRequest.builder()
                        .signatureDuration(ttl)
                        .getObjectRequest(GetObjectRequest.builder()
                                .bucket(bucket).key(key).build())
                        .build())
                .url().toString());
    }

    @Override
    public URI presignedPut(String key, Duration ttl, String contentType) {
        validateKey(key);
        return URI.create(presigner.presignPutObject(PutObjectPresignRequest.builder()
                        .signatureDuration(ttl)
                        .putObjectRequest(PutObjectRequest.builder()
                                .bucket(bucket).key(key).contentType(contentType).build())
                        .build())
                .url().toString());
    }

    @Override
    public void delete(String key) {
        validateKey(key);
        client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
    }

    private void applyEncryption(PutObjectRequest.Builder request) {
        if (sseAlgorithm.isBlank() || sseAlgorithm.equalsIgnoreCase("none")) {
            return;
        }
        if (sseAlgorithm.equalsIgnoreCase("AES256")) {
            request.serverSideEncryption(ServerSideEncryption.AES256);
            return;
        }
        if (sseAlgorithm.equalsIgnoreCase("aws:kms") || sseAlgorithm.equalsIgnoreCase("kms")) {
            if (kmsKeyId.isBlank()) {
                throw new IllegalStateException("KMS key ID is required for aws:kms encryption");
            }
            request.serverSideEncryption(ServerSideEncryption.AWS_KMS)
                    .ssekmsKeyId(kmsKeyId);
            return;
        }
        throw new IllegalStateException("Unsupported S3 server-side encryption setting");
    }

    private void validateKey(String key) {
        if (key == null || key.isBlank() || key.startsWith("/") || key.contains("..")
                || key.contains("\\")) {
            throw new IllegalArgumentException("Invalid object key");
        }
    }

    private String sha256(byte[] content) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(content));
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    @PreDestroy
    void close() {
        presigner.close();
        client.close();
    }
}
