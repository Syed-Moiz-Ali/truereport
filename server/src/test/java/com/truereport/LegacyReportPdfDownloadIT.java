package com.truereport;

import com.truereport.identity.User;
import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.reports.PublicShareLink;
import com.truereport.reports.PublicShareLinkRepository;
import com.truereport.reports.Report;
import com.truereport.reports.ReportRepository;
import com.truereport.reports.ReportVersion;
import com.truereport.reports.ReportVersionRepository;
import com.truereport.templates.TemplateVersion;
import com.truereport.templates.TemplateVersionRepository;
import com.truereport.templates.WorkshopTemplate;
import com.truereport.templates.WorkshopTemplateRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Legacy report PDF-download path: the same controller must keep updating the
 * legacy {@code public_share_links} row for unmigrated jobs.
 */
class LegacyReportPdfDownloadIT extends IntegrationTestBase {

    @Autowired
    WorkshopTemplateRepository templates;

    @Autowired
    TemplateVersionRepository templateVersions;

    @Autowired
    InspectionJobRepository inspectionJobs;

    @Autowired
    ReportRepository reports;

    @Autowired
    ReportVersionRepository reportVersions;

    @Autowired
    PublicShareLinkRepository links;

    @Test
    void legacyReportPdfDownloadStillTogglesTheLegacyLink() throws Exception {
        Login adminA = login("admin.a@test.local");
        User admin = fixture.adminA();
        UUID workshopId = fixture.workshopA().getId();

        WorkshopTemplate template = templates.save(new WorkshopTemplate(
                workshopId, "Legacy PDF " + UUID.randomUUID(), null, "FULL", "CAR",
                admin.getId()));
        TemplateVersion templateVersion = templateVersions.save(
                new TemplateVersion(template.getId(), workshopId, 1));
        templateVersion.publish(admin.getId(), LocalDateTime.now());
        templateVersions.save(templateVersion);

        InspectionJob job = new InspectionJob(workshopId,
                "LEGACY-PDF-" + UUID.randomUUID().toString().substring(0, 8),
                templateVersion.getId(), admin.getId(), "Legacy Customer", null, null,
                "Toyota", "Corolla", 2020, "JTDBR32E720123456", "LEGACY-1",
                "Legacy scope", null);
        job.setStatus("FINALIZED");
        inspectionJobs.save(job);

        Report report = reports.save(new Report(workshopId, job.getId()));
        ReportVersion version = reportVersions.save(new ReportVersion(
                report.getId(), workshopId, 1, "LEGACY-PDF-1", new byte[32], "{}",
                new byte[32], LocalDateTime.now()));
        PublicShareLink link = new PublicShareLink(workshopId, version.getId());
        link.setPdfDownloadEnabled(false);
        links.save(link);

        String path = "/api/v1/workshop/jobs/" + job.getId() + "/report/pdf-download";
        mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pdfDownloadEnabled").value(true));
        assertThat(links.findFirstByReportVersionIdOrderByCreatedAtDesc(version.getId())
                .orElseThrow().isPdfDownloadEnabled()).isTrue();

        mockMvc.perform(put(path)
                        .header("Authorization", "Bearer " + adminA.accessToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pdfDownloadEnabled").value(false));
        assertThat(links.findFirstByReportVersionIdOrderByCreatedAtDesc(version.getId())
                .orElseThrow().isPdfDownloadEnabled()).isFalse();
    }
}
