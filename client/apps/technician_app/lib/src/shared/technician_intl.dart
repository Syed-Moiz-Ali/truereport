import 'package:intl/intl.dart';

/// Locale-aware number/date formatting for F2-B technician surfaces.
///
/// Views in this folder must never render raw ISO-8601 instants or ungrouped
/// ASCII numbers to users. All helpers take an explicit BCP-47 [localeName]
/// (pass `Localizations.localeOf(context).toString()` from the view) so the
/// output follows the active locale even where `Intl.defaultLocale` is not
/// wired to the widget tree.
///
/// Timestamp semantics match `docs/api/contracts.md` quirk 3 and
/// `WorkshopClock.wallTime`:
///
/// * **with** an offset (`Z`, `+04:00`) it is a real instant; convert it to
///   Asia/Dubai (UTC+4, no DST).
/// * **without** an offset it is already a Dubai wall time; do not add four
///   hours.
///
/// Both branches return a [DateTime] whose fields are the Dubai wall clock.
/// Anything that genuinely needs a UTC instant (evidence `capturedAt`, sync
/// timestamps that always carry `Z`) must parse it directly; do not reuse
/// [parseWallTime] for those.
///
/// Digit shaping: the technician app uses Western digits in Arabic (D-040),
/// matching `intl`'s bare `ar` locale. Arabic UI locales are normalized to `ar`
/// so numbers stay Western (`34,180`) rather than Arabic-Indic.
/// Number symbols are compiled into `intl`, so number helpers never need
/// async initialization. Date symbols load lazily: date helpers fall back to
/// English when date data was not initialized (call
/// `initializeDateFormatting` at app startup; tests do this in `setUpAll`),
/// so a view can never crash on locale data.
String _intlLocale(String? localeName) {
  final name = (localeName ?? Intl.getCurrentLocale()).trim();
  if (name.isEmpty) {
    return 'en';
  }
  final language = name.split(RegExp(r'[_-]')).first.toLowerCase();
  if (language == 'ar') {
    return 'ar';
  }
  return name;
}

/// Asia/Dubai is UTC+4 all year (no daylight saving).
const Duration technicianDubaiOffset = Duration(hours: 4);

/// Offset suffixes Dart's ISO-8601 parser understands: `Z` or `±HH:MM`
/// (with or without the colon).
final RegExp _offsetSuffix = RegExp(r'(?:[Zz]|[+-]\d{2}:?\d{2})$');

/// True when [raw] carries an explicit UTC offset.
bool timestampHasOffset(String raw) => _offsetSuffix.hasMatch(raw.trim());

/// Dubai wall-clock fields for [raw], or null when empty/unparseable.
///
/// Offset values are converted from their real instant; offset-less values
/// keep their fields unchanged because the server already stores the Dubai
/// wall time. This is the one helper technician surfaces may use for
/// scheduled/started timestamps.
DateTime? parseWallTime(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return null;
  }
  if (timestampHasOffset(text)) {
    return parsed.toUtc().add(technicianDubaiOffset);
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

/// Locale-shaped integer (grouping + locale digits, e.g. `34,180` vs `٣٤٬١٨٠`).
String formatCountLocalized(num value, String? localeName) =>
    NumberFormat.decimalPattern(_intlLocale(localeName)).format(value);

/// Locale-shaped `completed / total` pair.
String formatCountPairLocalized(num completed, num total, String? localeName) =>
    '${formatCountLocalized(completed, localeName)} / '
    '${formatCountLocalized(total, localeName)}';

/// Locale-shaped whole percent, keeping the ASCII `%` used by the Figma slot.
String formatPercentLocalized(num percent, String? localeName) =>
    '${formatCountLocalized(percent, localeName)}%';

/// Locale-shaped odometer (`48,210 KM` vs `٤٨٬٢١٠ KM`), mirroring F2-A
/// `formatOdometer` but bound to the view's active locale.
String formatOdometerLocalized(int? value, String? unit, String? localeName) {
  if (value == null) {
    return '';
  }
  final formatted = formatCountLocalized(value, localeName);
  return '$formatted ${(unit ?? 'KM').toUpperCase()}';
}

DateFormat _dateFormat(
  DateFormat Function(String locale) build,
  String? localeName,
) {
  final locale = _intlLocale(localeName);
  try {
    return build(locale);
  } on Exception {
    // Date data not initialized for [locale] (tests call
    // `initializeDateFormatting`; production startup should too). Fall back
    // to English rather than throwing from a view build.
    return build('en');
  }
}

/// Locale-shaped full date+time of a timestamp in the Dubai wall clock.
String formatInstantDubaiLocalized(String raw, String? localeName) {
  final wall = parseWallTime(raw);
  if (wall == null) {
    return '';
  }
  return _dateFormat(
    (locale) => DateFormat.yMMMd(locale).add_Hm(),
    localeName,
  ).format(wall);
}

/// Locale-shaped wall-clock time of a timestamp in the Dubai wall clock.
String formatTimeDubaiLocalized(String raw, String? localeName) {
  final wall = parseWallTime(raw);
  if (wall == null) {
    return '';
  }
  final time = _dateFormat(
    (locale) => DateFormat.Hm(locale),
    localeName,
  ).format(wall);
  return '$time UTC+4';
}
