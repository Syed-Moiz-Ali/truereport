package com.truereport;

import com.truereport.shared.storage.S3ObjectStorage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@EnabledIfEnvironmentVariable(named = "S3_TEST_ENDPOINT", matches = ".+")
class S3ObjectStorageIT {

    @Test
    void roundTripChecksumAndPresignedReadAgainstLocalS3() throws Exception {
        String endpoint = System.getenv("S3_TEST_ENDPOINT");
        String bucket = "truereport-test";
        S3ObjectStorage storage = new S3ObjectStorage(
                endpoint, "us-east-1", bucket, "truereport", "truereport-secret",
                true, true, "", "");
        String key = "tests/" + UUID.randomUUID() + ".txt";
        byte[] content = "private evidence test".getBytes(StandardCharsets.UTF_8);
        storage.put(key, content, "text/plain");
        assertThat(storage.get(key)).isEqualTo(content);

        URI signed = storage.presignedGet(key, Duration.ofMinutes(2));
        HttpResponse<byte[]> response = HttpClient.newHttpClient().send(
                HttpRequest.newBuilder(signed).GET().build(),
                HttpResponse.BodyHandlers.ofByteArray());
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).isEqualTo(content);

        URI upload = storage.presignedPut("tests/" + UUID.randomUUID() + ".txt",
                Duration.ofMinutes(2), "text/plain");
        assertThat(upload.toString()).contains("X-Amz-Signature");
        storage.delete(key);
    }
}
