package com.truereport.reports;

import com.truereport.jobs.PlatformJobStore.LinkRow;
import com.truereport.jobs.PlatformJobTokenService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * On-demand PDF renderer for platform jobs. Renders through the exact
 * Chromium/HTML path the public report uses, but deliberately ignores
 * {@code platform_public_links.pdf_download_enabled}: that flag only gates the
 * anonymous {@code /r/{token}/pdf} endpoint, while Workshop Admin downloads and
 * delivery attachments are authorized server-side.
 */
@Component
public class PlatformReportPdfRenderer {

    private static final Logger log = LoggerFactory.getLogger(PlatformReportPdfRenderer.class);

    private final PublicReportService publicReports;
    private final PlatformJobTokenService tokens;

    public PlatformReportPdfRenderer(PublicReportService publicReports,
                                     PlatformJobTokenService tokens) {
        this.publicReports = publicReports;
        this.tokens = tokens;
    }

    public Optional<byte[]> render(LinkRow link) {
        if (link == null || link.tokenEncrypted() == null || link.tokenEncrypted().isBlank()) {
            return Optional.empty();
        }
        try {
            String token = tokens.decrypt(link.tokenEncrypted());
            if (token == null || token.isBlank()) {
                return Optional.empty();
            }
            return publicReports.renderForToken(token);
        } catch (RuntimeException exception) {
            log.warn("Could not render platform report PDF for link {}: {}",
                    link.id(), exception.getMessage(), exception);
            return Optional.empty();
        }
    }
}
