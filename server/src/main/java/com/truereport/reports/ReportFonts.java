package com.truereport.reports;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Base64;

@Component
public class ReportFonts {

    public String fontCss() {
        return "@font-face{font-family:'TR Arabic';src:url(data:font/ttf;base64," + data("fonts/NotoNaskhArabic-Regular.ttf")
                + ") format('truetype');font-display:block}"
                + "@font-face{font-family:'TR Sans';src:url(data:font/ttf;base64," + data("fonts/NotoSans-Regular.ttf")
                + ") format('truetype');font-display:block}"
                + "@font-face{font-family:'TR CJK';src:url(data:font/otf;base64," + data("fonts/NotoSansSC-Regular.otf")
                + ") format('opentype');font-display:block}";
    }

    private String data(String path) {
        try {
            ClassPathResource resource = new ClassPathResource("public-report/" + path);
            return Base64.getEncoder().encodeToString(resource.getInputStream().readAllBytes());
        } catch (IOException exception) {
            throw new IllegalStateException("Bundled font is missing: " + path, exception);
        }
    }
}
