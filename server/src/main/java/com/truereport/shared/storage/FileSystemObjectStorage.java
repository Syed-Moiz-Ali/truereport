package com.truereport.shared.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.FileStore;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.PosixFilePermission;
import java.nio.file.attribute.PosixFilePermissions;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;
import java.util.Set;
import java.util.UUID;

/**
 * Production self-hosted filesystem storage. Objects are never exposed as static
 * files; callers stream them through authorized backend endpoints.
 */
@Component
@ConditionalOnProperty(name = "truereport.storage.provider", havingValue = "filesystem")
public class FileSystemObjectStorage implements ObjectStorage {

    private static final Set<PosixFilePermission> DIR_PERMISSIONS =
            PosixFilePermissions.fromString("rwx------");
    private static final Set<PosixFilePermission> FILE_PERMISSIONS =
            PosixFilePermissions.fromString("rw-------");
    private static final String CHECKSUM_SUFFIX = ".sha256";
    private final Path root;
    private final long maxObjectBytes;
    private final long maxTotalBytes;
    private final long minFreeBytes;
    private final Object writeLock = new Object();
    private long usedBytes;

    public FileSystemObjectStorage(
            @Value("${truereport.storage.root:}") String root,
            @Value("${truereport.storage.filesystem.max-object-bytes:52428800}") long maxObjectBytes,
            @Value("${truereport.storage.filesystem.max-total-bytes:21474836480}") long maxTotalBytes,
            @Value("${truereport.storage.filesystem.min-free-bytes:1073741824}") long minFreeBytes,
            @Value("${truereport.storage.filesystem.backfill-checksums:true}")
            boolean backfillChecksums) {
        if (root == null || root.isBlank()) {
            throw new IllegalStateException(
                    "STORAGE_ROOT is required when STORAGE_PROVIDER=filesystem");
        }
        this.root = Path.of(root).toAbsolutePath().normalize();
        if (this.root.getParent() == null) {
            throw new IllegalStateException("Filesystem storage root cannot be the filesystem root");
        }
        if (!Files.isDirectory(this.root)) {
            throw new IllegalStateException("Filesystem storage root is missing: " + this.root);
        }
        if (!Files.isReadable(this.root) || !Files.isWritable(this.root)) {
            throw new IllegalStateException("Filesystem storage root is not readable/writable: " + this.root);
        }
        this.maxObjectBytes = positive(maxObjectBytes, "max-object-bytes");
        this.maxTotalBytes = positive(maxTotalBytes, "max-total-bytes");
        this.minFreeBytes = Math.max(0, minFreeBytes);
        ensureFreeSpace(0);
        secureDirectory(this.root);
        this.usedBytes = scanUsedBytes();
        if (backfillChecksums) {
            backfillChecksums();
        }
    }

    @Override
    public void put(String key, byte[] content, String contentType) {
        if (content == null || content.length == 0) {
            throw new IllegalArgumentException("Object content is required");
        }
        if (content.length > maxObjectBytes) {
            throw new IllegalStateException("Object exceeds the configured storage object limit");
        }
        Path target = resolve(key);
        synchronized (writeLock) {
            if (usedBytes + content.length > maxTotalBytes) {
                throw new IllegalStateException("Filesystem storage quota would be exceeded");
            }
            ensureFreeSpace(content.length);
            try {
                createDirectories(target.getParent());
                Path temp = target.resolveSibling("." + target.getFileName() + ".tmp-" + UUID.randomUUID());
                try {
                    try (FileChannel channel = FileChannel.open(temp,
                            StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE)) {
                        channel.write(ByteBuffer.wrap(content));
                        channel.force(true);
                    }
                    secureFile(temp);
                    String expected = sha256(content);
                    if (!expected.equals(sha256(Files.readAllBytes(temp)))) {
                        throw new IOException("Temporary write checksum mismatch");
                    }
                    try {
                        Files.move(temp, target, StandardCopyOption.ATOMIC_MOVE,
                                StandardCopyOption.REPLACE_EXISTING);
                    } catch (AtomicMoveNotSupportedException exception) {
                        throw new IOException("Storage does not support atomic rename", exception);
                    }
                    writeChecksum(target, expected);
                    secureFile(target);
                    usedBytes = scanUsedBytes();
                } finally {
                    Files.deleteIfExists(temp);
                }
            } catch (IOException exception) {
                throw new IllegalStateException("Unable to store object", exception);
            }
        }
    }

    @Override
    public byte[] get(String key) {
        Path target = resolve(key);
        if (!Files.isRegularFile(target, LinkOption.NOFOLLOW_LINKS)) {
            throw new IllegalStateException("Object is missing");
        }
        try {
            byte[] content = Files.readAllBytes(target);
            Path checksum = checksumPath(target);
            if (!Files.isRegularFile(checksum, LinkOption.NOFOLLOW_LINKS)) {
                throw new IllegalStateException("Object checksum metadata is missing");
            }
            String expected = Files.readString(checksum).trim();
            if (!expected.equals(sha256(content))) {
                throw new IllegalStateException("Object checksum mismatch");
            }
            return content;
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to read object", exception);
        }
    }

    @Override
    public URI presignedGet(String key, Duration ttl) {
        throw new UnsupportedOperationException(
                "Filesystem objects are served only through authorized backend endpoints");
    }

    @Override
    public URI presignedPut(String key, Duration ttl, String contentType) {
        throw new UnsupportedOperationException(
                "Filesystem uploads are served only through authorized backend endpoints");
    }

    @Override
    public void delete(String key) {
        Path target = resolve(key);
        synchronized (writeLock) {
            try {
                Files.deleteIfExists(target);
                Files.deleteIfExists(checksumPath(target));
                usedBytes = scanUsedBytes();
            } catch (IOException exception) {
                throw new IllegalStateException("Unable to delete object", exception);
            }
        }
    }

    public long usedBytes() {
        synchronized (writeLock) {
            return usedBytes;
        }
    }

    public long freeBytes() {
        try {
            FileStore store = Files.getFileStore(root);
            return store.getUsableSpace();
        } catch (IOException exception) {
            return 0;
        }
    }

    public Path root() {
        return root;
    }

    private void backfillChecksums() {
        try (var paths = Files.walk(root)) {
            paths.filter(path -> Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS))
                    .filter(path -> !path.getFileName().toString().endsWith(CHECKSUM_SUFFIX))
                    .filter(path -> {
                        try {
                            return !Files.exists(checksumPath(path), LinkOption.NOFOLLOW_LINKS);
                        } catch (RuntimeException exception) {
                            return false;
                        }
                    })
                    .forEach(path -> {
                        try {
                            writeChecksum(path, sha256(Files.readAllBytes(path)));
                        } catch (IOException exception) {
                            throw new IllegalStateException("Unable to backfill storage checksum", exception);
                        }
                    });
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to scan storage for checksum backfill", exception);
        }
    }

    private long scanUsedBytes() {
        try (var paths = Files.walk(root)) {
            return paths.filter(path -> Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS))
                    .filter(path -> !path.getFileName().toString().endsWith(CHECKSUM_SUFFIX))
                    .mapToLong(path -> {
                        try {
                            return Files.size(path);
                        } catch (IOException exception) {
                            return 0;
                        }
                    })
                    .sum();
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to calculate storage usage", exception);
        }
    }

    private void ensureFreeSpace(long incomingBytes) {
        try {
            long free = Files.getFileStore(root).getUsableSpace();
            if (free - incomingBytes < minFreeBytes) {
                throw new IllegalStateException("Filesystem storage free-space reserve is too low");
            }
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to read filesystem free space", exception);
        }
    }

    private void createDirectories(Path directory) throws IOException {
        if (directory == null || Files.isDirectory(directory)) {
            return;
        }
        createDirectories(directory.getParent());
        Files.createDirectory(directory);
        secureDirectory(directory);
    }

    private void writeChecksum(Path target, String hash) throws IOException {
        Path checksum = checksumPath(target);
        Path temp = checksum.resolveSibling("." + checksum.getFileName() + ".tmp-" + UUID.randomUUID());
        try {
            Files.writeString(temp, hash + "\n", StandardOpenOption.CREATE_NEW);
            secureFile(temp);
            Files.move(temp, checksum, StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING);
        } finally {
            Files.deleteIfExists(temp);
        }
    }

    private Path checksumPath(Path target) {
        return target.resolveSibling(target.getFileName() + CHECKSUM_SUFFIX);
    }

    private Path resolve(String key) {
        if (key == null || key.isBlank() || key.startsWith("/") || key.startsWith("\\")
                || key.contains("\\") || key.contains("\0")) {
            throw new IllegalArgumentException("Invalid object key");
        }
        String[] segments = key.split("/", -1);
        for (String segment : segments) {
            if (segment.isBlank() || segment.equals(".") || segment.equals("..")) {
                throw new IllegalArgumentException("Invalid object key");
            }
        }
        Path path = root.resolve(key).normalize();
        if (!path.startsWith(root) || path.equals(root)) {
            throw new IllegalArgumentException("Invalid object key");
        }
        return path;
    }

    private void secureDirectory(Path directory) {
        try {
            if (Files.getFileStore(directory).supportsFileAttributeView("posix")) {
                Files.setPosixFilePermissions(directory, DIR_PERMISSIONS);
            }
        } catch (IOException ignored) {
            // Windows/dev filesystems may not expose POSIX permissions.
        }
    }

    private void secureFile(Path file) {
        try {
            if (Files.getFileStore(file).supportsFileAttributeView("posix")) {
                Files.setPosixFilePermissions(file, FILE_PERMISSIONS);
            }
        } catch (IOException ignored) {
            // Windows/dev filesystems may not expose POSIX permissions.
        }
    }

    private String sha256(byte[] content) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(content));
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private long positive(long value, String name) {
        if (value <= 0) {
            throw new IllegalArgumentException(name + " must be positive");
        }
        return value;
    }
}
