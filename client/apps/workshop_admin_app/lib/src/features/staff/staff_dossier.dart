import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';

/// Pushed-page bar: back affordance, page title, optional trailing state.
///
/// Same 60 px geometry as the jobs document bar, so moving between the roster
/// and a member does not shift the eye.
class StaffPageBar extends StatelessWidget {
  const StaffPageBar({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      child: SizedBox(
        height: ws.topBarHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: Row(
                children: [
                  WorkshopIconButton(
                    icon: isRtl ? Icons.arrow_forward : Icons.arrow_back,
                    semanticLabel: t(WorkshopAdminKeys.commonBack),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ws.bodyStrong.copyWith(color: ws.ink),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `Label            value` row inside the details card.
class StaffFact extends StatelessWidget {
  const StaffFact({
    required this.label,
    required this.value,
    this.ltr = false,
    super.key,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: ws.meta.copyWith(color: ws.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: ws.body.copyWith(color: ws.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Account state: dot + label + tone, in the shared lifecycle pill.
class StaffStatusPill extends StatelessWidget {
  const StaffStatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) =>
      StaffStatusDot(status: status, pill: true);
}

/// Local password grading. UI-only: it never blocks a password the server
/// accepts, it only tells the admin what they typed.
enum StaffPasswordGrade { empty, weak, fair, good, strong }

StaffPasswordGrade staffPasswordGrade(String value) {
  if (value.isEmpty) {
    return StaffPasswordGrade.empty;
  }
  if (value.length < 12) {
    return StaffPasswordGrade.weak;
  }
  var score = 0;
  if (value.length >= 16) {
    score++;
  }
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
    score++;
  }
  if (RegExp(r'\d').hasMatch(value)) {
    score++;
  }
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    score++;
  }
  if (score <= 1) {
    return StaffPasswordGrade.fair;
  }
  if (score <= 2) {
    return StaffPasswordGrade.good;
  }
  return StaffPasswordGrade.strong;
}

/// Four-segment strength read-out with the localized label.
class StaffPasswordMeter extends StatelessWidget {
  const StaffPasswordMeter({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final grade = staffPasswordGrade(password);
    if (grade == StaffPasswordGrade.empty) {
      return const SizedBox.shrink();
    }
    final (filled, color, label) = switch (grade) {
      StaffPasswordGrade.weak => (
        1,
        ws.danger,
        t(WorkshopAdminKeys.passwordStrengthWeak),
      ),
      StaffPasswordGrade.fair => (
        2,
        ws.warning,
        t(WorkshopAdminKeys.passwordStrengthFair),
      ),
      StaffPasswordGrade.good => (
        3,
        ws.accent,
        t(WorkshopAdminKeys.passwordStrengthGood),
      ),
      StaffPasswordGrade.strong => (
        4,
        ws.success,
        t(WorkshopAdminKeys.passwordStrengthStrong),
      ),
      StaffPasswordGrade.empty => (0, ws.border, ''),
    };
    return Semantics(
      label: '${t(WorkshopAdminKeys.passwordStrength)}: $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < filled ? color : ws.border,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(ws.chipRadius / 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${t(WorkshopAdminKeys.passwordStrength)} · $label',
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ],
      ),
    );
  }
}
