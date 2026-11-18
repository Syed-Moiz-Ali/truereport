import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_style.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_states.dart';

/// What the hero is currently able to say.
enum DashboardHeroState { loading, ready, empty, failed }

/// Direction B's hero: one enormous total, the unit label beside it, and the
/// single sentence that makes the number personal.
///
/// Truth rules:
/// - the numeral comes only from the counts endpoint (`null` never renders as 0);
/// - `empty` means the endpoint said 0, not that the call failed;
/// - `failed` shows no numeral at all.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    required this.state,
    required this.scale,
    required this.compact,
    required this.newJobLabel,
    required this.onNewJob,
    this.totalText,
    this.eyebrow,
    this.label,
    this.sentence,
    this.emptyTitle,
    this.emptyBody,
    this.errorMessage,
    this.retryLabel,
    this.onRetry,
    super.key,
  });

  final DashboardHeroState state;
  final DashboardScale scale;

  /// True below 600 px: the primary action drops under the hero text.
  final bool compact;

  /// Already locale-formatted by the caller; never derived here.
  final String? totalText;

  /// Workshop name. Absent when there is no session.
  final String? eyebrow;

  /// "jobs on the floor" — already localized and already singularized.
  final String? label;

  /// "4 are waiting for your decision", or the calm zero state.
  final String? sentence;

  final String? emptyTitle;
  final String? emptyBody;
  final String? errorMessage;
  final String? retryLabel;
  final VoidCallback? onRetry;

  final String newJobLabel;
  final VoidCallback onNewJob;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;

    final headline = switch (state) {
      DashboardHeroState.loading => DashboardHeroSkeletonBlock(
        height: scale.totalSize,
      ),
      DashboardHeroState.failed => null,
      DashboardHeroState.empty => Text(
        emptyTitle ?? '',
        style: WorkshopDisplay.dashboardEmptyTitle(context),
      ),
      DashboardHeroState.ready => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // Tabular figures and an LTR-pinned numeral: Arabic must not
            // reorder "24" against its label.
            totalText ?? '',
            textDirection: TextDirection.ltr,
            style: scale.totalStyle(context),
          ),
          SizedBox(width: spacing.md),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: scale.totalSize * 0.16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label ?? '', style: ws.sectionTitle),
                  if (sentence != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      sentence!,
                      style: ws.meta.copyWith(
                        color: ws.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    };

    final body = switch (state) {
      DashboardHeroState.failed => DashboardErrorLine(
        message: errorMessage ?? '',
        retryLabel: retryLabel ?? '',
        onRetry: onRetry ?? () {},
      ),
      DashboardHeroState.empty => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          headline!,
          const SizedBox(height: 6),
          Text(emptyBody ?? '', style: ws.meta.copyWith(color: ws.muted)),
        ],
      ),
      _ => headline!,
    };

    final primary = _PrimaryAction(
      label: newJobLabel,
      onTap: onNewJob,
      expand: compact,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: ws.eyebrow.copyWith(letterSpacing: 0.9, color: ws.muted),
          ),
          SizedBox(height: spacing.lg),
        ],
        if (compact) ...[
          body,
          SizedBox(height: spacing.lg),
          primary,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: body),
              SizedBox(width: spacing.xl),
              Padding(
                padding: EdgeInsets.only(bottom: scale.totalSize * 0.12),
                child: primary,
              ),
            ],
          ),
      ],
    );
  }
}

/// Localized decimal grouping without touching `intl` directly (the screen file
/// already owns `formatNumber`; this keeps the hero self-contained for tests).
String formatDashboardCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

class DashboardHeroSkeletonBlock extends StatelessWidget {
  const DashboardHeroSkeletonBlock({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: height * 1.5,
          height: height * 0.8,
          decoration: BoxDecoration(
            color: ws.border,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(height: spacing.sm),
        Container(
          width: 168,
          height: 13,
          decoration: BoxDecoration(
            color: ws.canvas,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

/// The page's only filled button. On phone it fills the width (spec §6).
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return WorkshopButton(
      label: label,
      icon: Icons.add,
      expand: expand,
      onPressed: onTap,
    );
  }
}
