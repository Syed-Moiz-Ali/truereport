package com.truereport.shared.jdbc;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;

/**
 * Zone-free JDBC time reads.
 *
 * <p>{@code ResultSet.getTimestamp(column)} builds a {@link java.sql.Timestamp}
 * from the connection zone and {@code toLocalDateTime()} renders it in the JVM
 * zone, shifting every wall-clock value. The database columns are zone-less
 * wall time, so read them as {@link LocalDateTime} directly.</p>
 */
public final class JdbcTime {

    private JdbcTime() {
    }

    public static LocalDateTime localDateTime(ResultSet rs, String column)
            throws SQLException {
        return rs.getObject(column, LocalDateTime.class);
    }
}
