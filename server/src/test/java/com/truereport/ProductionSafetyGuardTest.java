package com.truereport;

import com.truereport.shared.config.ProductionSafetyGuard;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionSafetyGuardTest {

    @TempDir
    Path storage;

    @Test
    void developmentProfileMayUseLocalAndFakeAdapters() {
        assertThatCode(() -> new ProductionSafetyGuard(
                "dev", "local", "", false, "", 0,
                true, "fake", false, true, true, true))
                .doesNotThrowAnyException();
    }

    @Test
    void productionRejectsUnsafeStorageAndDefaults() throws Exception {
        assertThatThrownBy(() -> guard("local", storage.toString(), true, "", 0))
                .hasMessageContaining("STORAGE_PROVIDER=filesystem");
        assertThatThrownBy(() -> guard("s3", storage.toString(), true, "", 0))
                .hasMessageContaining("STORAGE_PROVIDER=filesystem");
        assertThatThrownBy(() -> guard("filesystem", "", true, "", 0))
                .hasMessageContaining("storage root is missing");
        assertThatThrownBy(() -> guard("filesystem", storage.resolve("missing").toString(), true, "", 0))
                .hasMessageContaining("not a directory");
        assertThatThrownBy(() -> guard("filesystem", storage.toString(), false, "", 0))
                .hasMessageContaining("persistent volume");
        Files.createDirectories(storage.resolve("static"));
        assertThatThrownBy(() -> guard("filesystem", storage.resolve("static").toString(), true, "", 0))
                .hasMessageContaining("web/static");
        assertThatThrownBy(() -> guard("filesystem", storage.toString(), true, storage.toString(), 0))
                .hasMessageContaining("configured web root");
        assertThatThrownBy(() -> guard("filesystem", storage.toString(), true, "", Long.MAX_VALUE))
                .hasMessageContaining("insufficient free space");
        assertThatThrownBy(() -> new ProductionSafetyGuard(
                "prod", "filesystem", storage.toString(), true, "", 0,
                true, "fake", false, false, false, false))
                .hasMessageContaining("fake delivery");
        assertThatThrownBy(() -> new ProductionSafetyGuard(
                "prod", "filesystem", storage.toString(), true, "", 0,
                false, "smtp", false, false, false, false))
                .hasMessageContaining("real recipients");
        assertThatThrownBy(() -> new ProductionSafetyGuard(
                "prod", "filesystem", storage.toString(), true, "", 0,
                false, "smtp", true, false, true, true))
                .hasMessageContaining("OpenAPI");
    }

    @Test
    void safeFilesystemProductionConfigurationStarts() {
        assertThatCode(() -> new ProductionSafetyGuard(
                "prod", "filesystem", storage.toString(), true, "", 0,
                false, "smtp", true, false, false, false))
                .doesNotThrowAnyException();
    }

    private ProductionSafetyGuard guard(String provider, String root, boolean persistent,
                                        String webRoot, long minFree) {
        return new ProductionSafetyGuard(
                "prod", provider, root, persistent, webRoot, minFree,
                false, "smtp", true, false, false, false);
    }
}
