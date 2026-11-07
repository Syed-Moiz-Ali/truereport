package com.truereport.jobs.api;

/**
 * Aggregate job counts for the caller's workshop. Counts only — no PII.
 *
 * <p>{@code newScheduled} is the sum of {@code draft} and {@code scheduled}
 * (jobs not yet started). {@code finalizedToday} counts finalized jobs whose
 * {@code finalizedAt} falls on the current date in Asia/Dubai.
 */
public record JobCountsDto(
        long draft,
        long scheduled,
        long newScheduled,
        long assigned,
        long inProgress,
        long readyToFinalize,
        long finalized,
        long finalizedToday,
        long cancelled,
        long total
) {
}
