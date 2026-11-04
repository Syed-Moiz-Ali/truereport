package com.truereport.shared.retention;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneOffset;

/**
 * Conservative retention worker. It never touches finalized inspections, final
 * snapshots, reports or report versions. Periods are placeholders pending C2.
 */
@Service
public class RetentionService {

    private static final Logger log = LoggerFactory.getLogger(RetentionService.class);

    private final JdbcTemplate jdbc;
    private final boolean enabled;
    private final int revokedLinkDays;
    private final int deliveryDays;
    private final int softDeletedEvidenceDays;
    private final boolean deleteSoftDeletedEvidence;

    public RetentionService(JdbcTemplate jdbc,
                            @Value("${truereport.retention.enabled:false}") boolean enabled,
                            @Value("${truereport.retention.revoked-link-days:0}") int revokedLinkDays,
                            @Value("${truereport.retention.delivery-days:0}") int deliveryDays,
                            @Value("${truereport.retention.soft-deleted-evidence-days:0}")
                            int softDeletedEvidenceDays,
                            @Value("${truereport.retention.delete-soft-deleted-evidence:false}")
                            boolean deleteSoftDeletedEvidence) {
        this.jdbc = jdbc;
        this.enabled = enabled;
        this.revokedLinkDays = revokedLinkDays;
        this.deliveryDays = deliveryDays;
        this.softDeletedEvidenceDays = softDeletedEvidenceDays;
        this.deleteSoftDeletedEvidence = deleteSoftDeletedEvidence;
    }

    @Scheduled(cron = "${truereport.retention.cron:0 30 2 * * *}")
    @Transactional
    public void run() {
        if (!enabled) {
            return;
        }
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        int deliveryRows = 0;
        if (deliveryDays > 0) {
            LocalDateTime cutoff = now.minusDays(deliveryDays);
            jdbc.update("""
                    DELETE FROM delivery_webhook_events
                    WHERE delivery_request_id IN (
                        SELECT id FROM delivery_requests
                        WHERE created_at < ? AND status IN ('SENT','DELIVERED','FAILED','DEAD_LETTER')
                    )
                    """, cutoff);
            jdbc.update("""
                    DELETE FROM delivery_attempts
                    WHERE delivery_request_id IN (
                        SELECT id FROM delivery_requests
                        WHERE created_at < ? AND status IN ('SENT','DELIVERED','FAILED','DEAD_LETTER')
                    )
                    """, cutoff);
            deliveryRows = jdbc.update("""
                    DELETE FROM delivery_requests
                    WHERE created_at < ? AND status IN ('SENT','DELIVERED','FAILED','DEAD_LETTER')
                    """, cutoff);
        }
        int links = 0;
        if (revokedLinkDays > 0) {
            links = jdbc.update("""
                    DELETE FROM public_share_links
                    WHERE status = 'REVOKED' AND revoked_at < ?
                    """, now.minusDays(revokedLinkDays));
        }
        int clearedTokens = jdbc.update("""
                UPDATE evidence_assets
                SET upload_token_hash = NULL, upload_token_expires_at = NULL
                WHERE upload_status = 'PENDING' AND upload_token_expires_at < ?
                """, now);
        int softDeleted = 0;
        if (deleteSoftDeletedEvidence && softDeletedEvidenceDays > 0) {
            LocalDateTime cutoff = now.minusDays(softDeletedEvidenceDays);
            jdbc.update("""
                    DELETE FROM evidence_derivatives
                    WHERE evidence_asset_id IN (
                        SELECT id FROM evidence_assets
                        WHERE deleted_at IS NOT NULL AND deleted_at < ?
                          AND job_id NOT IN (SELECT id FROM inspection_jobs WHERE status = 'FINALIZED')
                    )
                    """, cutoff);
            softDeleted = jdbc.update("""
                    DELETE FROM evidence_assets
                    WHERE deleted_at IS NOT NULL AND deleted_at < ?
                      AND job_id NOT IN (SELECT id FROM inspection_jobs WHERE status = 'FINALIZED')
                    """, cutoff);
        }
        log.info("Retention run completed: links={}, deliveries={}, uploadTokens={}, softDeletedEvidence={}",
                links, deliveryRows, clearedTokens, softDeleted);
    }
}
