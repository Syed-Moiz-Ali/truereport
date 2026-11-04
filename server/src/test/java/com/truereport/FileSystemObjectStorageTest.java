package com.truereport;

import com.truereport.shared.storage.FileSystemObjectStorage;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermissions;
import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FileSystemObjectStorageTest {

    @TempDir
    Path root;

    @Test
    void atomicWriteCreatesChecksumAndRestrictsPermissions() throws Exception {
        FileSystemObjectStorage storage = storage(50_000_000L, 100_000_000L);
        storage.put("evidence/ws/job/original", new byte[]{1, 2, 3}, "image/jpeg");
        assertThat(storage.get("evidence/ws/job/original")).containsExactly(1, 2, 3);
        assertThat(Files.readString(root.resolve("evidence/ws/job/original.sha256"))).isNotBlank();
        assertThat(Files.walk(root).filter(path -> path.getFileName().toString().startsWith(".")).count())
                .isZero();
        Assumptions.assumeTrue(Files.getFileStore(root).supportsFileAttributeView("posix"));
        assertThat(PosixFilePermissions.toString(Files.getPosixFilePermissions(
                root.resolve("evidence/ws/job/original")))).isEqualTo("rw-------");
    }

    @Test
    void readAndWriteRejectChecksumMismatchAndBadKeys() throws Exception {
        FileSystemObjectStorage storage = storage(50_000_000L, 100_000_000L);
        storage.put("reports/a.pdf", new byte[]{4, 5}, "application/pdf");
        Files.writeString(root.resolve("reports/a.pdf.sha256"), "wrong\n");
        assertThatThrownBy(() -> storage.get("reports/a.pdf"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("checksum");

        assertThatThrownBy(() -> storage.put("../escape", new byte[]{1}, "text/plain"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> storage.put("/absolute", new byte[]{1}, "text/plain"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> storage.put("a//b", new byte[]{1}, "text/plain"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> storage.presignedGet("reports/a.pdf", Duration.ofMinutes(1)))
                .isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void quotaAndObjectLimitRejectBeforeWriting() throws Exception {
        FileSystemObjectStorage objectLimited = storage(2L, 6L);
        assertThatThrownBy(() -> objectLimited.put("a", new byte[]{1, 2, 3}, "text/plain"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("object limit");
        FileSystemObjectStorage quotaLimited = storage(10L, 3L);
        quotaLimited.put("a", new byte[]{1, 2}, "text/plain");
        assertThatThrownBy(() -> quotaLimited.put("b", new byte[]{3, 4}, "text/plain"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("quota");
        assertThatThrownBy(() -> new FileSystemObjectStorage(root.toString(), 5L, 10L,
                Long.MAX_VALUE, false))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("free-space");
    }

    @Test
    void startupBackfillsChecksumsForExistingObjects() throws Exception {
        Path legacy = root.resolve("legacy/file.bin");
        Files.createDirectories(legacy.getParent());
        Files.write(legacy, new byte[]{9, 8, 7});
        FileSystemObjectStorage storage = storage(50_000_000L, 100_000_000L);
        assertThat(Files.exists(root.resolve("legacy/file.bin.sha256"))).isTrue();
        assertThat(storage.get("legacy/file.bin")).containsExactly(9, 8, 7);
    }

    private FileSystemObjectStorage storage(long maxObject, long maxTotal) {
        return new FileSystemObjectStorage(root.toString(), maxObject, maxTotal, 0, true);
    }
}
