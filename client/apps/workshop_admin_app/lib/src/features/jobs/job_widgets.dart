import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

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

/// Parses a raw ISO instant and returns the Asia/Dubai (UTC+4) wall clock.
DateTime? dubaiWallTime(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) {
    return null;
  }
  final hasOffset = RegExp(r'([Zz]|[+-]\d{2}:?\d{2})$').hasMatch(raw.trim());
  final utc = hasOffset
      ? parsed.toUtc()
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.add(const Duration(hours: 4));
}

/// Locale-aware date+time; falls back to the raw value when unparseable.
String formatInstant(BuildContext context, String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) {
    return '';
  }
  final wall = dubaiWallTime(value);
  if (wall == null) {
    return value;
  }
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(wall);
}

/// Locale-aware integer formatting, Western digits.
String formatNumber(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format(value);
}

String formatScore(BuildContext context, num? value) =>
    value == null ? '-' : formatNumber(context, value);

String formatBytes(BuildContext context, int bytes) =>
    '${formatNumber(context, bytes)} B';

/// Compact label/value row used in summary cards.
class JobKeyValue extends StatelessWidget {
  const JobKeyValue({
    required this.label,
    required this.value,
    this.valueDirection,
    super.key,
  });

  final String label;
  final String value;
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textDirection: valueDirection,
              style: context.texts.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple card wrapper with a responsive inner column.
class JobPanel extends StatelessWidget {
  const JobPanel({
    required this.child,
    this.title,
    this.icon,
    super.key,
  });

  final Widget child;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: context.sizing.iconLg,
                    color: context.colors.onSurfaceVariant,
                  ),
                  SizedBox(width: context.spacing.sm),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: context.texts.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

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

/// Reason entry sheet used by unpublish, revoke, cancel and reject flows.
/// Returns the trimmed reason, or null when dismissed.
Future<String?> showJobReasonSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  var showError = false;
  try {
    return await showAppBottomSheet<String>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: title),
              AppTextField(
                controller: controller,
                label: label,
                maxLines: 3,
                errorText: showError ? l10n.commonReasonRequired : null,
              ),
              SizedBox(height: context.spacing.lg),
              AppButton(
                label: confirmLabel,
                onPressed: () {
                  if (controller.text.trim().isEmpty) {
                    setSheetState(() => showError = true);
                    return;
                  }
                  Navigator.of(context).pop(controller.text.trim());
                },
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}
