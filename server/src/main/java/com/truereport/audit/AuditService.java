package com.truereport.audit;

import com.truereport.shared.web.RequestIdFilter;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AuditService {

    private final AuditEventRepository repository;

    public AuditService(AuditEventRepository repository) {
        this.repository = repository;
    }

    public void record(UUID workshopId, UUID actorUserId, String actorRole, String action,
                       String entityType, UUID entityId, String reasonCode, String metadataJson) {
        repository.save(new AuditEvent(
                workshopId,
                actorUserId,
                actorRole,
                action,
                entityType,
                entityId,
                MDC.get(RequestIdFilter.MDC_KEY),
                reasonCode,
                metadataJson
        ));
    }

    public void recordAuth(UUID userId, String action, String reasonCode) {
        record(null, userId, null, action, "USER", userId, reasonCode, null);
    }
}
