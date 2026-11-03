package com.truereport.publicweb;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * Neutral public pages for Phase 2. No report data, tokens or internal identifiers are rendered.
 * The real report renderer is Phase 6 work.
 */
@RestController
public class PublicReportController {

    private static final String NEUTRAL_HTML = """
            <!doctype html>
            <html lang="en" dir="ltr">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <meta name="robots" content="noindex, nofollow">
              <meta name="referrer" content="no-referrer">
              <title>Report unavailable</title>
              <style>
                :root { color-scheme: light; }
                body { margin:0; min-height:100vh; display:grid; place-items:center;
                       font:16px/1.55 Arial, sans-serif; background:#f7fafa; color:#17212b; }
                main { max-width:34rem; padding:2rem; background:#fff; border:1px solid #d5e3e6;
                       border-radius:12px; text-align:center; }
                h1 { font-size:1.35rem; margin:0 0 .5rem; color:#0b3b4a; }
                p { margin:0; color:#4d6670; }
              </style>
            </head>
            <body>
              <main>
                <h1>This link is unavailable</h1>
                <p>The report cannot be displayed. Please contact the workshop that issued it.</p>
              </main>
            </body>
            </html>
            """;

    @GetMapping("/r/unavailable")
    public ResponseEntity<String> unavailable() {
        return response(HttpStatus.OK);
    }

    @GetMapping("/r/{token}")
    public ResponseEntity<String> invalidToken(@PathVariable String token) {
        // Never echo the token or confirm whether it exists.
        return response(HttpStatus.NOT_FOUND);
    }

    private ResponseEntity<String> response(HttpStatus status) {
        return ResponseEntity.status(status)
                .contentType(MediaType.TEXT_HTML)
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .header("X-Robots-Tag", "noindex, nofollow")
                .header("Referrer-Policy", "no-referrer")
                .header("X-Content-Type-Options", "nosniff")
                .header("Content-Security-Policy",
                        "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'")
                .body(NEUTRAL_HTML);
    }
}
