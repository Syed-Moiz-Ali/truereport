package com.truereport.reports;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Component
public class ChromiumPdfRenderer implements PdfRenderer {

    private final String configuredPath;

    public ChromiumPdfRenderer(
            @Value("${truereport.report.chrome-path:}") String configuredPath) {
        this.configuredPath = configuredPath;
    }

    @Override
    public byte[] render(String html) {
        Path executable = executable();
        Path work = null;
        try {
            work = Files.createTempDirectory("truereport-pdf-");
            Path input = work.resolve("report.html");
            Path output = work.resolve("report.pdf");
            Path profile = work.resolve("profile");
            Files.writeString(input, html, StandardCharsets.UTF_8);
            Files.createDirectories(profile);

            List<String> command = new ArrayList<>();
            command.add(executable.toString());
            command.add("--headless=new");
            command.add("--disable-gpu");
            command.add("--no-sandbox");
            command.add("--disable-dev-shm-usage");
            command.add("--hide-scrollbars");
            command.add("--no-pdf-header-footer");
            command.add("--run-all-compositor-stages-before-draw");
            command.add("--virtual-time-budget=3000");
            command.add("--user-data-dir=" + profile);
            command.add("--print-to-pdf=" + output);
            command.add(input.toUri().toString());

            Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
            boolean finished = process.waitFor(90, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                throw new IllegalStateException("Chromium PDF rendering timed out");
            }
            if (process.exitValue() != 0 || !Files.exists(output)) {
                throw new IllegalStateException("Chromium PDF rendering failed with exit code "
                        + process.exitValue());
            }
            return Files.readAllBytes(output);
        } catch (IOException exception) {
            throw new IllegalStateException("Cannot run Chromium PDF renderer", exception);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Chromium PDF rendering was interrupted", exception);
        } finally {
            delete(work);
        }
    }

    public boolean available() {
        try {
            executable();
            return true;
        } catch (RuntimeException exception) {
            return false;
        }
    }

    private Path executable() {
        if (configuredPath != null && !configuredPath.isBlank()) {
            Path path = Path.of(configuredPath);
            if (Files.isRegularFile(path)) {
                return path;
            }
            throw new IllegalStateException("Configured Chromium path does not exist");
        }
        List<String> candidates = List.of(
                "/usr/bin/chromium",
                "/usr/bin/chromium-browser",
                "/usr/bin/google-chrome",
                "/usr/bin/google-chrome-stable",
                "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
                "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
                "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
                "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe"
        );
        for (String candidate : candidates) {
            Path path = Path.of(candidate);
            if (Files.isRegularFile(path)) {
                return path;
            }
        }
        try {
            Process process = new ProcessBuilder("chromium", "--version").start();
            if (process.waitFor(2, TimeUnit.SECONDS) && process.exitValue() == 0) {
                return Path.of("chromium");
            }
        } catch (Exception ignored) {
            // Fall through to the explicit failure.
        }
        throw new IllegalStateException("No Chromium executable is available");
    }

    private void delete(Path root) {
        if (root == null) {
            return;
        }
        try (var paths = Files.walk(root)) {
            paths.sorted((left, right) -> right.getNameCount() - left.getNameCount())
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException ignored) {
                            // Best effort cleanup.
                        }
                    });
        } catch (IOException ignored) {
            // Best effort cleanup.
        }
    }
}
