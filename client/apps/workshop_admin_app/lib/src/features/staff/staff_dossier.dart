import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';

/// Document atoms for the staff create and member pages.
///
/// The pages read as one numbered document: a page bar, numbered section
/// heads, label/value facts, a status pill and a password strength read-out.
/// Every value comes from the workshop tokens — no new palette or radii.
extension StaffDossierTokens on WorkshopTokens {
  TextStyle get dossierDisplay => pageTitle.copyWith(
    fontSize: 34,
    letterSpacing: -0.8,
    height: 1.15,
    color: ink,
  );

  TextStyle get dossierSection => eyebrow.copyWith(color: ink);
}

/// Pushed-page bar: back affordance, page title, optional trailing state.
class StaffPageBar extends StatelessWidget {
  const StaffPageBar({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    semanticLabel: l10n.commonBack,
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

/// Numbered section heading: `01  STATUS`.
class StaffSectionHead extends StatelessWidget {
  const StaffSectionHead({
    required this.number,
    required this.title,
    this.trailing,
    super.key,
  });

  final String number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Row(
      children: [
        Text(
          number,
          style: ws.eyebrow.copyWith(
            color: ws.accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: ws.dossierSection),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// `Label            value` row inside the details section.
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
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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

/// Account state: dot + label + tone. Never colour alone.
class StaffStatusPill extends StatelessWidget {
  const StaffStatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final label = staffStatusLabel(context, status);
    final color = staffStatusColor(ws, status);
    final background = switch (status) {
      'ACTIVE' => ws.successSoft,
      'PENDING' => ws.warningSoft,
      'DISABLED' => ws.dangerSoft,
      _ => ws.canvas,
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: ws.eyebrow.copyWith(color: color, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
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
    final l10n = AppLocalizations.of(context);
    final grade = staffPasswordGrade(password);
    if (grade == StaffPasswordGrade.empty) {
      return const SizedBox.shrink();
    }
    final (filled, color, label) = switch (grade) {
      StaffPasswordGrade.weak => (1, ws.danger, l10n.passwordStrengthWeak),
      StaffPasswordGrade.fair => (2, ws.warning, l10n.passwordStrengthFair),
      StaffPasswordGrade.good => (3, ws.accent, l10n.passwordStrengthGood),
      StaffPasswordGrade.strong => (4, ws.success, l10n.passwordStrengthStrong),
      StaffPasswordGrade.empty => (0, ws.border, ''),
    };
    return Semantics(
      label: '${l10n.passwordStrength}: $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < filled ? color : ws.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.passwordStrength} · $label',
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ],
      ),
    );
  }
}
