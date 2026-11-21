package com.truereport.shared.jdbc;

import org.junit.jupiter.api.Test;

import java.sql.ResultSet;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Guards the zone-free read path: a DATETIME must be read as
 * {@code LocalDateTime}, never through {@code getTimestamp}, which applies the
 * connection/JVM zone and shifts wall-clock values.
 */
class JdbcTimeTest {

    @Test
    void readsLocalDateTimeWithoutTimestampConversion() throws Exception {
        ResultSet rs = mock(ResultSet.class);
        LocalDateTime stored = LocalDateTime.parse("2026-11-21T12:00:00");
        when(rs.getObject("scheduled_at", LocalDateTime.class)).thenReturn(stored);

        assertThat(JdbcTime.localDateTime(rs, "scheduled_at")).isEqualTo(stored);
        verify(rs, never()).getTimestamp(anyString());
        verify(rs, never()).getTimestamp(anyString(), any());
    }

    @Test
    void nullColumnStaysNull() throws Exception {
        ResultSet rs = mock(ResultSet.class);
        when(rs.getObject("completed_at", LocalDateTime.class)).thenReturn(null);

        assertThat(JdbcTime.localDateTime(rs, "completed_at")).isNull();
    }
}
