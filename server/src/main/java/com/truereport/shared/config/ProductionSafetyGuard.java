package com.truereport.shared.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

/**
 * Fails production startup when an unsafe development/storage setting is used.
 * Owner decision: self-hosted filesystem storage, no cloud object storage.
 */
@Component
public class ProductionSafetyGuard {

    public ProductionSafetyGuard(
            @Value("${spring.profiles.active:}") String activeProfiles,
            @Value("${truereport.storage.provider:local}") String storageProvider,
            @Value("${truereport.storage.root:}") String storageRoot,
            @Value("${truereport.storage.filesystem.persistent-volume:false}")
            boolean persistentVolume,
            @Value("${truereport.storage.filesystem.web-root:}") String webRoot,
            @Value("${truereport.storage.filesystem.min-free-bytes:1073741824}")
            long minFreeBytes,
            @Value("${truereport.delivery.fake-enabled:true}") boolean fakeDelivery,
            @Value("${truereport.delivery.email-provider:smtp}") String emailProvider,
            @Value("${truereport.delivery.real-recipients-enabled:false}")
            boolean realRecipientsEnabled,
            @Value("${truereport.dev.seed-enabled:false}") boolean seedEnabled,
            @Value("${springdoc.api-docs.enabled:true}") boolean apiDocsEnabled,
            @Value("${springdoc.swagger-ui.enabled:true}") boolean swaggerEnabled) {
        if (!activeProfiles.contains("prod")) {
            return;
        }
        require(storageProvider.equalsIgnoreCase("filesystem"),
                "Production requires STORAGE_PROVIDER=filesystem; local and cloud modes are disabled");
        require(persistentVolume,
                "Production filesystem storage must be on a configured persistent volume");
        Path root = safePath(storageRoot);
        require(root != null, "Production storage root is missing");
        require(Files.isDirectory(root), "Production storage root is not a directory");
        require(Files.isReadable(root) && Files.isWritable(root),
                "Production storage root is not readable/writable");
        String normalized = root.toString().replace('\\', '/').toLowerCase(Locale.ROOT);
        require(!normalized.startsWith("/tmp/") && !normalized.equals("/tmp")
                        && !normalized.startsWith("/run/"),
                "Production storage root cannot be on an ephemeral tmpfs layer");
        require(!containsWebSegment(normalized),
                "Production storage root cannot be inside a web/static root");
        if (webRoot != null && !webRoot.isBlank()) {
            Path web = safePath(webRoot);
            require(web == null || !root.startsWith(web),
                    "Production storage root cannot be inside the configured web root");
        }
        require(freeBytes(root) >= Math.max(0, minFreeBytes),
                "Production storage root has insufficient free space");
        require(!fakeDelivery, "Production must not use fake delivery providers");
        require(!emailProvider.equalsIgnoreCase("fake"),
                "Production must not use the fake email provider");
        require(realRecipientsEnabled,
                "Production must explicitly enable real recipients after D8 approval");
        require(!seedEnabled, "Production must not enable development seed data");
        require(!apiDocsEnabled && !swaggerEnabled,
                "Production must disable OpenAPI/Swagger exposure");
    }

    private boolean containsWebSegment(String path) {
        return path.contains("/static/") || path.contains("/public/")
                || path.contains("/resources/") || path.contains("/www/")
                || path.contains("/html/") || path.contains("/webapps/")
                || path.endsWith("/static") || path.endsWith("/public")
                || path.endsWith("/www") || path.endsWith("/html");
    }

    private Path safePath(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Path.of(value).toAbsolutePath().normalize();
        } catch (RuntimeException exception) {
            return null;
        }
    }

    private long freeBytes(Path root) {
        try {
            return Files.getFileStore(root).getUsableSpace();
        } catch (IOException exception) {
            return 0;
        }
    }

    private void require(boolean condition, String message) {
        if (!condition) {
            throw new IllegalStateException("Unsafe production configuration: " + message);
        }
    }
}
