import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:workshop_admin_app/src/workshop_clock.dart';

export 'shared/job_reason_sheet.dart';

/// Picks the right localized value for API-provided bilingual content.
String localizedText(
  BuildContext context, {
  required String en,
  required String ar,
}) {
  final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
  final value = preferArabic ? ar : en;
  if (value.trim().isNotEmpty) {
    return value;
  }
  return en.trim().isNotEmpty ? en : ar;
}

/// Parses a raw ISO instant and returns the Asia/Dubai wall clock.
///
/// Thin alias for [WorkshopClock.wallTime]: the rule lives in exactly one
/// place, and this name is kept because callers read better with it.
DateTime? dubaiWallTime(String? raw) => WorkshopClock.wallTime(raw);

/// Locale-aware date+time; falls back to the raw value when unparseable.
String formatInstant(BuildContext context, String? raw) =>
    WorkshopClock.formatInstant(context, raw, fallback: raw?.trim() ?? '');

/// Locale-aware integer formatting, Western digits.
String formatNumber(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format(value);
}

String formatScore(BuildContext context, num? value) =>
    value == null ? '-' : formatNumber(context, value);

String formatBytes(BuildContext context, int bytes) =>
    '${formatNumber(context, bytes)} B';

/// Small inline warning/error panel.
class JobInlineError extends StatelessWidget {
  const JobInlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.danger;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(context.spacing.md),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(context.radii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: context.sizing.iconMd,
              color: pair.foreground,
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall?.copyWith(
                  color: pair.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
