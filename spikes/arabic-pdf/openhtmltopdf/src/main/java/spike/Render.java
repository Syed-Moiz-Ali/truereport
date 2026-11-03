package spike;

import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Entities;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class Render {
    public static void main(String[] args) throws Exception {
        Path htmlPath = Paths.get(args[0]).toAbsolutePath();
        Path outPath = Paths.get(args[1]).toAbsolutePath();
        String html = Files.readString(htmlPath, StandardCharsets.UTF_8);

        Document doc = Jsoup.parse(html);
        doc.outputSettings()
                .syntax(Document.OutputSettings.Syntax.xml)
                .escapeMode(Entities.EscapeMode.xhtml)
                .charset("UTF-8");
        html = doc.outerHtml();
        html = html.replace("</head>",
                "<style>@page { @bottom-center { content: \"TR-2026-0001 | v1 | Page \" counter(page) \" of \" counter(pages); font-family: Arial; font-size: 8pt; color: #555; } }</style></head>");

        long start = System.nanoTime();
        try (OutputStream os = new FileOutputStream(outPath.toFile())) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.useFont(new File("C:/Windows/Fonts/arial.ttf"), "Arial");
            builder.useFont(new File("C:/Windows/Fonts/STSONG.TTF"), "STSong");
            builder.withHtmlContent(html, htmlPath.getParent().toUri().toString());
            builder.toStream(os);
            builder.run();
        }
        long ms = (System.nanoTime() - start) / 1_000_000;
        long bytes = Files.size(outPath);
        long used = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
        System.out.println("{\"engine\":\"OpenHTMLtoPDF 1.0.10 / PDFBox\",\"ms\":" + ms + ",\"bytes\":" + bytes + ",\"usedMemoryMb\":" + (used / 1024 / 1024) + "}");
    }
}
