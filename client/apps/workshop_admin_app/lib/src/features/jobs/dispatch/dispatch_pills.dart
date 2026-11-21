import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// The jobs module uses the same pill control language as templates: full
/// rounded buttons, chips and badges. Re-exported under job-facing names so
/// this feature does not read as "template" code at the call site.
typedef JobPillButton = TemplatePillButton;
typedef JobPillChip = TemplatePillChip;
typedef JobPillVariant = TemplatePillVariant;

/// Compact lifecycle pill used in table rows and page bars.
///
/// Label and tone come from `statusesProvider('job')`; no local status table.
class JobStatusPill extends ConsumerWidget {
  const JobStatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final records = ref.watch(statusesProvider('job')).value;
    final text = referenceStatusText(records, status);
    final (fg, bg) = workshopPillColors(
      referenceStatusTone(records, status),
      ws,
    );
    return Semantics(
      label: text,
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
            Text(text, style: ws.eyebrow.copyWith(color: fg, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// The lifecycle as a pill rail: past stages tinted, current stage inked,
/// later stages muted. Mirrors the server order, no invented stages.
///
/// Below 640 px the rail wraps onto as many rows as it needs instead of
/// scrolling sideways, so the current stage can never sit off-screen. The
/// connectors only exist in the single-row rail; a wrapped row would otherwise
/// trail a line into empty space.
class JobStageRail extends ConsumerWidget {
  const JobStageRail({required this.status, super.key});

  final String status;

  // Stage rail sequence mirroring the server lifecycle; labels and tones
  // resolve through statusesProvider('job').
  // gate-allow: codes
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
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final records = ref.watch(statusesProvider('job')).value;
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
          referenceStatusText(records, stages[i]),
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
