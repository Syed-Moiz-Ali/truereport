package com.truereport.shared.storage;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;

@Component
public class StorageMetrics {

    private final MeterRegistry meterRegistry;
    private final Path root;
    private volatile long cachedUsedBytes;

    public StorageMetrics(MeterRegistry meterRegistry,
                          @Value("${truereport.storage.provider:local}") String provider,
                          @Value("${truereport.storage.root:}") String productionRoot,
                          @Value("${truereport.storage.local-root:./.truereport-storage}") String localRoot) {
        this.meterRegistry = meterRegistry;
        String configured = provider.equalsIgnoreCase("filesystem") ? productionRoot : localRoot;
        this.root = configured == null || configured.isBlank()
                ? null : Path.of(configured).toAbsolutePath().normalize();
    }

    @PostConstruct
    void register() {
        Gauge.builder("truereport.storage.free.bytes", this, StorageMetrics::freeBytes)
                .description("Usable bytes on the configured storage volume")
                .register(meterRegistry);
        Gauge.builder("truereport.storage.capacity.bytes", this, StorageMetrics::capacityBytes)
                .description("Total bytes on the configured storage volume")
                .register(meterRegistry);
        Gauge.builder("truereport.storage.application.used.bytes", this, metrics -> metrics.cachedUsedBytes)
                .description("Application object bytes under the storage root")
                .register(meterRegistry);
        refresh();
    }

    @Scheduled(fixedDelayString = "${truereport.storage.metrics-refresh-ms:60000}")
    public void refresh() {
        cachedUsedBytes = scanUsedBytes();
    }

    private double freeBytes() {
        if (root == null) {
            return 0;
        }
        try {
            return Files.getFileStore(root).getUsableSpace();
        } catch (IOException exception) {
            return 0;
        }
    }

    private double capacityBytes() {
        if (root == null) {
            return 0;
        }
        try {
            return Files.getFileStore(root).getTotalSpace();
        } catch (IOException exception) {
            return 0;
        }
    }

    private long scanUsedBytes() {
        if (root == null || !Files.isDirectory(root)) {
            return 0;
        }
        try (var paths = Files.walk(root)) {
            return paths.filter(path -> Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS))
                    .filter(path -> !path.getFileName().toString().endsWith(".sha256"))
                    .mapToLong(path -> {
                        try {
                            return Files.size(path);
                        } catch (IOException exception) {
                            return 0;
                        }
                    })
                    .sum();
        } catch (IOException exception) {
            return 0;
        }
    }
}
