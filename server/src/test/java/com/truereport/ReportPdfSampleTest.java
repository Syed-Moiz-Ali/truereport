package com.truereport;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.reports.EvidenceDerivative;
import com.truereport.reports.ReportPdfService;
import com.truereport.reports.ReportSnapshot;
import com.truereport.reports.ReportVersion;
import com.truereport.shared.storage.ObjectStorage;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = "truereport.report.worker-enabled=false")
@ActiveProfiles("test")
@EnabledIfSystemProperty(named = "truereport.samples", matches = "true")
class ReportPdfSampleTest {

    @Autowired
    ReportPdfService pdfService;

    @Autowired
    ObjectStorage storage;

    @Autowired
    ObjectMapper objectMapper;

    @Test
    void generateBilingualSampleWithLongMixedTextAndTwentyPhotos() throws Exception {
        UUID workshopId = UUID.randomUUID();
        UUID versionId = UUID.randomUUID();
        List<String> evidenceIds = new ArrayList<>();
        List<EvidenceDerivative> derivatives = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            UUID evidenceId = UUID.randomUUID();
            evidenceIds.add(evidenceId.toString());
            byte[] jpeg = jpeg(i);
            String key = "sample/evidence-" + i + ".jpg";
            storage.put(key, jpeg, "image/jpeg");
            derivatives.add(new EvidenceDerivative(workshopId, versionId, evidenceId,
                    "PUBLIC_FULL", key, sha(jpeg), "image/jpeg", jpeg.length, 32, 32));
        }

        List<ReportSnapshot.ItemSnapshot> items = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            items.add(new ReportSnapshot.ItemSnapshot(
                    "SAMPLE-" + i,
                    "Inspection point " + (i + 1) + " with a deliberately long English label for wrapping",
                    "نقطة فحص " + (i + 1) + " مع عنوان عربي طويل لاختبار الالتفاف والاتجاه",
                    "Check this component carefully and record any visible condition.",
                    "افحص هذا المكون بعناية وسجل أي حالة مرئية.",
                    i % 3 == 0 ? "DEFECT_FOUND" : "NO_ISSUE_OBSERVED",
                    i % 3 == 0 ? (i == 0 ? "SAFETY_CRITICAL" : "MODERATE") : "",
                    "Long technician note: " + "تم فحص الجزء بعناية مع ملاحظات عربية وإنجليزية وأرقام 123456 و VIN ****3456. ".repeat(4)
                            + "Русский текст: проверено. 中文文本：已检查。",
                    "ar",
                    "",
                    i % 3 == 0 ? "Visible wear or damage recorded." : "",
                    List.of(evidenceIds.get(i))));
        }
        ReportSnapshot snapshot = new ReportSnapshot(
                "SAMPLE-REPORT-001", 1, "2026-11-04T10:30:00",
                "2026-11-04T10:30:00",
                new ReportSnapshot.Vehicle("Toyota", "Land Cruiser", 2022, "••••3456", 82902, "KM", "CAR"),
                new ReportSnapshot.Inspection("Full visual inspection", 3, "2026-11-04T10:30:00"),
                new ReportSnapshot.Workshop("Dubai Technical Inspection", "Al Quoz"),
                new ReportSnapshot.Technician("Ahmed Al Mansouri"),
                new ReportSnapshot.Coverage(20, 20, 20, 0, 0, 0),
                items.subList(0, 3),
                List.of(new ReportSnapshot.Category(
                        "Brakes, tyres and suspension / الفرامل والإطارات والتعليق",
                        "الفرامل والإطارات والتعليق", items)),
                List.of(),
                List.of("Visual inspection only; components were not dismantled."),
                "This is a visual, non-invasive inspection and not an official certificate.",
                "b7fb81fdbd284bde061e80be4542898ca850b834ccae735cf34bec5606aebf6e");
        String json = objectMapper.writeValueAsString(snapshot);
        ReportVersion version = new ReportVersion(UUID.randomUUID(), workshopId, 1,
                snapshot.reportNumber(), sha(json.getBytes(StandardCharsets.UTF_8)), json,
                sha(json.getBytes(StandardCharsets.UTF_8)), LocalDateTime.parse(snapshot.finalizedAt()));
        byte[] pdf = pdfService.render(version, derivatives);
        Path output = Path.of("..", "docs", "phase-6", "samples", "bilingual-report-sample.pdf");
        Files.createDirectories(output.getParent());
        Files.write(output, pdf);
        try (PDDocument document = Loader.loadPDF(pdf)) {
            org.apache.pdfbox.rendering.PDFRenderer renderer = new org.apache.pdfbox.rendering.PDFRenderer(document);
            for (int page : List.of(0, 1, document.getNumberOfPages() - 1)) {
                ImageIO.write(renderer.renderImage(page, 1.0f), "png",
                        output.resolveSibling("bilingual-report-sample-page-" + (page + 1) + ".png").toFile());
            }
            String text = new PDFTextStripper().getText(document).replaceAll("\\s+", " ");
            Files.writeString(output.resolveSibling("bilingual-report-sample.txt"), text,
                    StandardCharsets.UTF_8);
            assertThat(document.getNumberOfPages()).isGreaterThan(2);
            assertThat(text).contains("Vehicle inspection report", "SAMPLE-REPORT-001")
                    .doesNotContain("JTDBR32E720123456");
        }
    }

    private byte[] jpeg(int index) throws Exception {
        BufferedImage image = new BufferedImage(32, 32, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < 32; y++) {
            for (int x = 0; x < 32; x++) {
                image.setRGB(x, y, 0x112233 + index * 0x010101);
            }
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", output);
        return output.toByteArray();
    }

    private byte[] sha(byte[] value) throws Exception {
        return MessageDigest.getInstance("SHA-256").digest(value);
    }
}
