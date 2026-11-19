import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// The jobs module uses the same pill control language as templates: full
/// rounded buttons, chips and badges. Re-exported under job-facing names so
/// this feature does not read as "template" code at the call site.
typedef JobPillButton = TemplatePillButton;
typedef JobPillChip = TemplatePillChip;
typedef JobPillVariant = TemplatePillVariant;

/// Lifecycle badge for a clean job.
class JobStatusPill extends StatelessWidget {
  const JobStatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final (Color bg, Color fg) = switch (status) {
      'PUBLISHED' => (ws.successSoft, ws.success),
      'APPROVED' => (ws.successSoft, ws.success),
      'PENDING_REVIEW' => (ws.warningSoft, ws.warning),
      'IN_PROGRESS' => (ws.accentSoft, ws.accent),
      'ASSIGNED' => (ws.canvas, ws.ink),
      'SCHEDULED' => (ws.canvas, ws.ink),
      'CANCELLED' || 'REJECTED' => (ws.dangerSoft, ws.danger),
      _ => (ws.canvas, ws.muted),
    };
    return Semantics(
      label: jobStatusLabel(l10n, status),
      child: Container(
        height: 24,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              jobStatusLabel(l10n, status),
              style: ws.eyebrow.copyWith(color: fg, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

String jobStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'DRAFT' => l10n.draft,
  'SCHEDULED' => l10n.statusScheduled,
  'ASSIGNED' => l10n.statusAssigned,
  'IN_PROGRESS' => l10n.statusInProgress,
  'PENDING_REVIEW' => l10n.jobsStatusPendingReview,
  'APPROVED' => l10n.jobsStatusApproved,
  'PUBLISHED' => l10n.jobsStatusPublished,
  'REJECTED' => l10n.jobsStatusRejected,
  'CANCELLED' => l10n.statusCancelled,
  'FINALIZED' => l10n.statusFinalized,
  _ => status,
};

/// The lifecycle as a pill rail: past stages tinted, current stage inked,
/// later stages muted. Mirrors the server order, no invented stages.
///
/// Below 640 px the rail wraps onto as many rows as it needs instead of
/// scrolling sideways, so the current stage can never sit off-screen. The
/// connectors only exist in the single-row rail; a wrapped row would otherwise
/// trail a line into empty space.
class JobStageRail extends StatelessWidget {
  const JobStageRail({required this.status, super.key});

  final String status;

  static const stages = <String>[
    'DRAFT',
    'SCHEDULED',
    'ASSIGNED',
    'IN_PROGRESS',
    'PENDING_REVIEW',
    'APPROVED',
    'PUBLISHED',
  ];

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final current = stages.indexOf(status);

    Widget stage(int i) => Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: i < current
            ? ws.accentSoft
            : i == current
            ? ws.ink
            : ws.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: i == current ? ws.ink : ws.border),
      ),
      child: Center(
        child: Text(
          jobStatusLabel(l10n, stages[i]),
          style: ws.meta.copyWith(
            fontSize: 11.5,
            color: i < current
                ? ws.accent
                : i == current
                ? ws.canvas
                : ws.muted,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (var i = 0; i < stages.length; i++) stage(i)],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  stage(i),
                  if (i < stages.length - 1)
                    Container(width: 12, height: 1, color: ws.border),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Round job mark used in table rows.
class JobGlyph extends StatelessWidget {
  const JobGlyph({this.size = 34, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ws.accentSoft, shape: BoxShape.circle),
        child: Icon(
          Icons.fact_check_outlined,
          size: size * 0.46,
          color: ws.accent,
        ),
      ),
    );
  }
}
