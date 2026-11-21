package com.truereport.shared.time;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;

/**
 * Wall-clock parsing for client timestamps.
 *
 * <p>Clients treat a zone-less value as Dubai wall time, and also send real
 * instants (for example {@code DateTime.now().toUtc().toIso8601String()}).
 * A naive value is returned unchanged; an instant is converted to Dubai wall
 * time. Never store a UTC {@link LocalDateTime} for a client timestamp.</p>
 */
public final class WallClockTimes {

    /** UAE is UTC+04 all year; there is no daylight-saving change. */
    public static final ZoneOffset DUBAI = ZoneOffset.ofHours(4);

    private WallClockTimes() {
    }

    /**
     * @return {@code null} for blank input; the same wall time for a naive
     *         value; Dubai wall time for an offset/instant value.
     * @throws DateTimeParseException when the value is neither form.
     */
    public static LocalDateTime parse(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String trimmed = value.trim();
        try {
            return LocalDateTime.parse(trimmed);
        } catch (DateTimeParseException naive) {
            return OffsetDateTime.parse(trimmed)
                    .atZoneSameInstant(DUBAI)
                    .toLocalDateTime();
        }
    }

    public static LocalDateTime dubaiNow() {
        return LocalDateTime.now(DUBAI);
    }
}
