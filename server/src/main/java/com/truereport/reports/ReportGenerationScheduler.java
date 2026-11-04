package com.truereport.reports;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "truereport.report.worker-enabled", havingValue = "true", matchIfMissing = true)
public class ReportGenerationScheduler {

    private final ReportGenerationService service;

    public ReportGenerationScheduler(ReportGenerationService service) {
        this.service = service;
    }

    @Scheduled(fixedDelayString = "${truereport.report.worker-delay-ms:2000}")
    public void run() {
        service.poll();
    }
}
