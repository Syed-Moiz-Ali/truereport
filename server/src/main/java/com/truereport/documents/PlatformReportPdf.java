package com.truereport.documents;

import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Minimal dependency-free PDF writer for generated Workshop Admin report
 * documents. It produces a valid single-page PDF with ASCII-safe text so the
 * generated English and Arabic artifacts can be stored and served immediately.
 */
@Component
public class PlatformReportPdf {

    public byte[] render(String title, List<String> lines) {
        List<String> safeLines = new ArrayList<>();
        safeLines.add(ascii(title));
        safeLines.add("");
        for (String line : lines) {
            safeLines.add(ascii(line));
        }

        StringBuilder content = new StringBuilder();
        content.append("BT\n/F1 13 Tf\n50 800 Td\n");
        for (int i = 0; i < safeLines.size(); i++) {
            if (i > 0) {
                content.append("0 -18 Td\n");
            }
            content.append('(').append(escape(safeLines.get(i))).append(") Tj\n");
        }
        content.append("ET\n");
        byte[] stream = content.toString().getBytes(StandardCharsets.ISO_8859_1);

        List<String> objects = List.of(
                "<< /Type /Catalog /Pages 2 0 R >>",
                "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
                "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
                        + "/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
                "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
                "<< /Length " + stream.length + " >>\nstream\n" + content + "endstream");

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        write(output, "%PDF-1.4\n");
        List<Integer> offsets = new ArrayList<>();
        for (int i = 0; i < objects.size(); i++) {
            offsets.add(output.size());
            write(output, (i + 1) + " 0 obj\n" + objects.get(i) + "\nendobj\n");
        }
        int xref = output.size();
        StringBuilder xrefTable = new StringBuilder("xref\n0 ").append(objects.size() + 1)
                .append("\n0000000000 65535 f \n");
        for (Integer offset : offsets) {
            xrefTable.append(String.format("%010d 00000 n \n", offset));
        }
        write(output, xrefTable.toString());
        write(output, "trailer\n<< /Size " + (objects.size() + 1) + " /Root 1 0 R >>\n");
        write(output, "startxref\n" + xref + "\n%%EOF\n");
        return output.toByteArray();
    }

    private static void write(ByteArrayOutputStream output, String value) {
        byte[] bytes = value.getBytes(StandardCharsets.ISO_8859_1);
        output.write(bytes, 0, bytes.length);
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
    }

    private static String ascii(String value) {
        if (value == null) {
            return "";
        }
        StringBuilder result = new StringBuilder(value.length());
        for (char character : value.toCharArray()) {
            if (character == '\n' || character == '\r' || character == '\t') {
                result.append(' ');
            } else if (character >= 32 && character <= 126) {
                result.append(character);
            } else {
                result.append('?');
            }
        }
        return result.toString();
    }
}
