package com.truereport.reports.api;

import com.truereport.reports.PublicReportService;
import com.truereport.reports.ReportMessages;
import jakarta.annotation.security.PermitAll;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.CacheControl;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Controller
@PermitAll
public class PublicReportController {

    private final PublicReportService service;

    public PublicReportController(PublicReportService service) {
        this.service = service;
    }

    @GetMapping({"/r/unavailable", "/report/unavailable"})
    public ModelAndView unavailable(@RequestParam(defaultValue = "en") String lang) {
        String language = "ar".equals(lang) ? "ar" : "en";
        Map<String, Object> model = new LinkedHashMap<>();
        model.put("labels", ReportMessages.labels(language));
        model.put("lang", language);
        model.put("dir", language.equals("ar") ? "rtl" : "ltr");
        return new ModelAndView("report/unavailable", model);
    }

    @GetMapping({"/r/{token}", "/report/{token}"})
    public ModelAndView page(@PathVariable String token,
                             @RequestParam(defaultValue = "en") String lang,
                             HttpServletResponse response) {
        String language = "ar".equals(lang) ? "ar" : "en";
        PublicReportService.Resolution resolution = service.resolve(token, language);
        response.setStatus(PublicReportService.statusFor(resolution.status()).value());
        Map<String, Object> model = new LinkedHashMap<>();
        model.put("labels", ReportMessages.labels(language));
        model.put("lang", language);
        model.put("dir", language.equals("ar") ? "rtl" : "ltr");
        if (resolution.status() == PublicReportService.Status.ACTIVE) {
            model.put("r", resolution.resolved().page());
            model.put("token", token);
            return new ModelAndView("report/public-report", model);
        }
        if (resolution.status() == PublicReportService.Status.TEMPORARY) {
            return new ModelAndView("report/temporarily-unavailable", model);
        }
        return new ModelAndView("report/unavailable", model);
    }

    @GetMapping({"/r/{token}/photo/{derivativeId}", "/report/{token}/photo/{derivativeId}"})
    public ResponseEntity<byte[]> photo(@PathVariable String token, @PathVariable UUID derivativeId) {
        return service.photo(token, derivativeId)
                .map(photo -> ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(photo.mime()))
                        .cacheControl(CacheControl.noStore())
                        .body(photo.bytes()))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping({"/r/{token}/pdf", "/report/{token}/pdf"})
    public ResponseEntity<byte[]> pdf(@PathVariable String token) {
        return service.pdf(token)
                .map(bytes -> ResponseEntity.ok()
                        .contentType(MediaType.APPLICATION_PDF)
                        .cacheControl(CacheControl.noStore())
                        .header(HttpHeaders.CONTENT_DISPOSITION,
                                ContentDisposition.attachment()
                                        .filename("inspection-report.pdf").build().toString())
                        .body(bytes))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
