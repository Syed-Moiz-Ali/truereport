import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:workshop_admin_app/src/workshop_clock.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';

/// Humanized schedule for a ledger row.
///
/// Today reads "Today, 9:00 AM"; any other day reads "Wed, 25 Nov · 4:20 PM".
/// The wall-clock rule is [WorkshopClock]'s (naive values are already Dubai
/// wall time); this file only chooses how to say it. Returns an empty string
/// when the server sent nothing, so the caller can omit the element instead of
/// printing a placeholder.
String dashboardSchedule(
  BuildContext context,
  String? raw, {
  String todayTemplate = 'Today, {date}',
}) {
  final wall = WorkshopClock.wallTime(raw);
  if (wall == null) {
    return '';
  }
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final sameDay =
      wall.year == now.year && wall.month == now.month && wall.day == now.day;
  final time = DateFormat.jm(locale).format(wall);
  if (sameDay) {
    return pinDigits(todayTemplate.replaceAll('{date}', time));
  }
  return pinDigits('${DateFormat.MMMEd(locale).format(wall)} · $time');
}

/// `reference · customer · technician · schedule`, omitting empty parts.
///
/// Never invents a placeholder: a missing technician shortens the line.
String dashboardJobMeta({
  required String reference,
  required String customer,
  String? technician,
  required String schedule,
}) {
  final parts = <String>[
    if (reference.trim().isNotEmpty) reference.trim(),
    if (customer.trim().isNotEmpty) customer.trim(),
    if ((technician ?? '').trim().isNotEmpty) technician!.trim(),
    if (schedule.trim().isNotEmpty) schedule.trim(),
  ];
  return parts.join('  ·  ');
}

/// Screen-reader sentence for one row. Separators are spoken as pauses.
String dashboardRowSemantics({
  required String title,
  required String reference,
  required String customer,
  String? technician,
  required String schedule,
  required String status,
  String? verb,
}) {
  final parts = <String>[
    title,
    if (reference.trim().isNotEmpty) reference.trim(),
    if (customer.trim().isNotEmpty) customer.trim(),
    if ((technician ?? '').trim().isNotEmpty) technician!.trim(),
    if (schedule.trim().isNotEmpty) schedule.trim(),
    status,
    if ((verb ?? '').isNotEmpty) verb!,
  ];
  return parts.join('. ');
}

/// `make model`, falling back to the customer name when the server has no
/// vehicle. Never renders a dash or a fake model.
String dashboardJobTitle({
  required String make,
  required String model,
  required String customer,
}) {
  final vehicle = '$make $model'.trim();
  return vehicle.isEmpty ? customer : vehicle;
}
/// Compact byte size for export volume: "820 KB", "24.6 MB".
String dashboardBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  }
  final mb = kb / 1024;
  if (mb < 1024) {
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }
  return '${(mb / 1024).toStringAsFixed(1)} GB';
}

/// "4 min ago" / "3 h ago" / "2 d ago", from three localized templates.
String dashboardRelative(
  DateTime? at, {
  required String minutes,
  required String hours,
  required String days,
}) {
  if (at == null) {
    return '';
  }
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 60) {
    final value = diff.inMinutes < 1 ? 1 : diff.inMinutes;
    return minutes.replaceAll('{count}', '$value');
  }
  if (diff.inHours < 24) {
    return hours.replaceAll('{count}', '${diff.inHours}');
  }
  return days.replaceAll('{count}', '${diff.inDays}');
}
