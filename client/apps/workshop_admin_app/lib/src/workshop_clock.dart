import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// The single time policy for every timestamp this app displays.
///
/// The wire is inconsistent (see `docs/api/contracts.md` quirk 3 and T1 in
/// `docs/data/inventory.md`): a user-picked schedule is stored as a **naive
/// `LocalDateTime`** (`2026-11-18T10:00`, no offset) while server-generated
/// instants may arrive with an offset (`2026-11-18T06:00Z`). Treating every
/// naive value as UTC — what this app used to do — published a job the user
/// scheduled at 10:00 as 14:00.
///
/// One documented rule, used everywhere:
///
/// * **with** an offset (`Z`, `+04:00`, `-01:00`) → it is a real instant;
///   convert it to Asia/Dubai (UTC+4, no DST).
/// * **without** an offset → it is already a Dubai wall time; **do not add
///   four hours**.
///
/// Both branches return a [DateTime] whose *fields* are the Dubai wall clock
/// (one is `isUtc`, one is local — that difference is irrelevant because
/// formatting reads the fields). Never call [DateTime.toLocal] or
/// [DateTime.toUtc] on the result.
///
/// The rule is explicitly testable in `test/workshop_clock_test.dart`:
/// `2026-11-18T10:00` renders 10:00 and `2026-11-18T06:00Z` renders 10:00.
abstract final class WorkshopClock {
  /// Offset suffixes Dart's ISO-8601 parser understands: `Z` or `±HH:MM`
  /// (with or without the colon).
  static final RegExp _offsetSuffix = RegExp(r'(?:[Zz]|[+-]\d{2}:?\d{2})$');

  /// Asia/Dubai is UTC+4 all year (no daylight saving).
  static const Duration dubaiOffset = Duration(hours: 4);

  /// True when [raw] carries an explicit UTC offset.
  static bool hasOffset(String raw) => _offsetSuffix.hasMatch(raw.trim());

  /// The Dubai wall-clock fields for [raw], or null when empty/unparseable.
  static DateTime? wallTime(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return null;
    }
    if (hasOffset(text)) {
      return parsed.toUtc().add(dubaiOffset);
    }
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  /// Locale-aware `date + time` (`yMd` + `Hm`).
  ///
  /// Returns [fallback] when the value is empty or unparseable, so a caller can
  /// choose between "render nothing" and "render the raw string". Never returns
  /// a silently invented time.
  static String formatInstant(
    BuildContext context,
    String? raw, {
    String fallback = '',
  }) {
    final wall = wallTime(raw);
    if (wall == null) {
      return fallback;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(wall);
  }

  /// Locale-aware date only (`yMd`); same fallback contract as
  /// [formatInstant].
  static String formatDate(
    BuildContext context,
    String? raw, {
    String fallback = '',
  }) {
    final wall = wallTime(raw);
    if (wall == null) {
      return fallback;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(wall);
  }
}
