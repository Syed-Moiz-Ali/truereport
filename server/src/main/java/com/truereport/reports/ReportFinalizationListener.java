package com.truereport.reports;

import com.truereport.jobs.InspectionFinalizedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class ReportFinalizationListener {

    private final ReportService service;

    public ReportFinalizationListener(ReportService service) {
        this.service = service;
    }

    @EventListener
    public void onFinalized(InspectionFinalizedEvent event) {
        service.createForFinalized(event.job(), event.finalSnapshotJson(), event.finalSnapshotHash());
    }
}
