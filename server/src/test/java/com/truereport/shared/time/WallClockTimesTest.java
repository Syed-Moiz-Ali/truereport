package com.truereport.shared.time;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class WallClockTimesTest {

    @Test
    void naiveValueIsReturnedUnchanged() {
        assertThat(WallClockTimes.parse("2026-11-22T10:00:00"))
                .isEqualTo(LocalDateTime.parse("2026-11-22T10:00:00"));
    }

    @Test
    void utcInstantBecomesDubaiWallTime() {
        assertThat(WallClockTimes.parse("2026-11-22T06:00:00Z"))
                .isEqualTo(LocalDateTime.parse("2026-11-22T10:00:00"));
        assertThat(WallClockTimes.parse("2026-11-22T00:12:34.567Z"))
                .isEqualTo(LocalDateTime.parse("2026-11-22T04:12:34.567"));
    }

    @Test
    void dubaiOffsetIsUnchanged() {
        assertThat(WallClockTimes.parse("2026-11-22T10:00:00+04:00"))
                .isEqualTo(LocalDateTime.parse("2026-11-22T10:00:00"));
    }

    @Test
    void otherOffsetsAreConvertedToDubai() {
        // 03:00 at -05:00 is 08:00Z, which is 12:00 in Dubai.
        assertThat(WallClockTimes.parse("2026-11-22T03:00:00-05:00"))
                .isEqualTo(LocalDateTime.parse("2026-11-22T12:00:00"));
    }

    @Test
    void blankIsNull() {
        assertThat(WallClockTimes.parse(null)).isNull();
        assertThat(WallClockTimes.parse("  ")).isNull();
    }

    @Test
    void invalidValueThrows() {
        assertThatThrownBy(() -> WallClockTimes.parse("not-a-time"))
                .isInstanceOf(DateTimeParseException.class);
    }
}
