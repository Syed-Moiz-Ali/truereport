import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';

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
  const JobPanel({required this.child, this.title, this.icon, super.key});

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
                Expanded(child: Text(title!, style: context.texts.titleMedium)),
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
///
/// The controller lives in [_JobReasonSheetState] so it is disposed with the
/// sheet's own widget tree, not when the route future completes: the sheet's
/// exit transition still builds the field after `pop()` (J8).
Future<String?> showJobReasonSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
}) {
  return showAppBottomSheet<String>(
    context,
    child: _JobReasonSheet(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
    ),
  );
}

class _JobReasonSheet extends StatefulWidget {
  const _JobReasonSheet({
    required this.title,
    required this.label,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String confirmLabel;

  @override
  State<_JobReasonSheet> createState() => _JobReasonSheetState();
}

class _JobReasonSheetState extends State<_JobReasonSheet> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: widget.title),
          AppTextField(
            controller: _controller,
            label: widget.label,
            maxLines: 3,
            errorText: _showError ? l10n.commonReasonRequired : null,
          ),
          SizedBox(height: context.spacing.lg),
          AppButton(
            label: widget.confirmLabel,
            onPressed: () {
              if (_controller.text.trim().isEmpty) {
                setState(() => _showError = true);
                return;
              }
              Navigator.of(context).pop(_controller.text.trim());
            },
            expand: true,
          ),
        ],
      ),
    );
  }
}
