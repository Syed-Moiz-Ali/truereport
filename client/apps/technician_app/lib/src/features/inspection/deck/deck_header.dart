import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../../inspection_models.dart';
import '../../jobs/queue/jobs_queue_format.dart';

/// The deck's single measure. Header, sections, ledger and footer all cap at
/// this width and centre, so a desktop window never grows a dead side column.
const double deckContentMaxWidth = 900;

/// Deck type ramp. The redesign reuses the app's body face and only tunes size,
/// weight and tracking per role.
TextStyle deckText(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w400,
  double height = 1.45,
  Color? color,
  double tracking = 0,
  bool tabular = false,
}) {
  return context.texts.bodyMedium!.copyWith(
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color ?? context.colors.onSurface,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

/// Centres one band of the deck on [deckContentMaxWidth].
class DeckCapped extends StatelessWidget {
  const DeckCapped({
    required this.child,
    this.maxWidth = deckContentMaxWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Plate-shaped vehicle identity. The plate is how a technician locates a car
/// among several jobs, so it stays visible on the header's first line.
class DeckPlate extends StatelessWidget {
  const DeckPlate(this.value, {this.maxWidth = 168, super.key});

  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, minHeight: 32),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.radii.pill),
          border: Border.all(color: context.colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 13,
              decoration: BoxDecoration(
                color: context.brand.ink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: deckText(
                  context,
                  12,
                  weight: FontWeight.w700,
                  height: 16,
                  tracking: 0.6,
                  tabular: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small toned pill used for boolean flags (safety critical, multi-point) and
/// for the per-job sync note. Tones come from the shared tone palette only.
class DeckToneChip extends StatelessWidget {
  const DeckToneChip({
    required this.label,
    required this.tone,
    this.icon,
    this.small = false,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: small ? 8 : 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 13, color: pair.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: deckText(
                context,
                small ? 10 : 11,
                weight: FontWeight.w600,
                height: 14,
                color: pair.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The job header: identity, one state line, and the customer line.
///
/// State appears here and nowhere else in the deck. Sync state is a separate,
/// informational chip — it never replaces the job state.
class DeckHeader extends StatelessWidget {
  const DeckHeader({
    required this.checklist,
    required this.onBack,
    required this.statusLabel,
    this.statusTone = StatusTone.neutral,
    this.pendingSync = 0,
    this.syncHasConflict = false,
    this.trailing,
    this.wide = false,
    super.key,
  });

  final Checklist checklist;
  final VoidCallback onBack;

  /// Served job-state label (`jobStatusLabel`).
  final String statusLabel;
  final StatusTone statusTone;

  /// Waiting + failed + conflicted operations for this device, or 0.
  final int pendingSync;
  final bool syncHasConflict;

  /// Photo thumbnail, owned by the workspace page.
  final Widget? trailing;

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final job = checklist.job;
    // Year stays out of the header: make + model plus the plate already
    // identify the car, and the shorter string survives 390 px and 1.5x.
    final makeModel = [
      job.vehicleMake,
      job.vehicleModel,
    ].where((value) => value.trim().isNotEmpty).join(' ');
    final vehicle = makeModel.isNotEmpty ? makeModel : queueVehicleLabel(job);
    final plate = (job.vehiclePlate ?? '').trim();
    final reference = job.reference.trim();
    final customer = job.customerName.trim();
    final plateValue = plate.isNotEmpty ? plate : reference;
    final time = queueSlotLabel(job);
    final total = checklist.total > 0
        ? checklist.total
        : checklist.items.length;
    final rawDone = checklist.completed;
    final done = rawDone < 0 ? 0 : (rawDone > total ? total : rawDone);

    final statusLine = t(TechnicianKeys.technicianDeckStatusLine, {
      'status': statusLabel.isEmpty ? '—' : statusLabel,
      'time': time.isEmpty ? '—' : time,
      'progress': t(TechnicianKeys.technicianQueueItems, {
        'done': done,
        'total': total,
      }),
    });

    // The reference is only repeated on the meta line when the plate exists;
    // when the plate is missing the reference *is* the pill on line one.
    final meta = <String>[
      if (customer.isNotEmpty) customer,
      if (plate.isNotEmpty && reference.isNotEmpty) reference,
    ].join(' · ');

    final statusColor = context.statusColors.forTone(statusTone).foreground;

    return DeckCapped(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          wide ? 8 : 4,
          8,
          wide ? 24 : 12,
          4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              child: GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: deckText(
                            context,
                            18,
                            weight: FontWeight.w700,
                            height: 23,
                            tracking: -0.3,
                          ),
                        ),
                      ),
                      if (wide && plateValue.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        DeckPlate(plateValue, maxWidth: 220),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // On a phone the plate moves to its own line so the
                      // vehicle name keeps its full width instead of
                      // truncating to "Toyota Land Cru…".
                      if (!wide && plateValue.isNotEmpty)
                        DeckPlate(plateValue, maxWidth: 168),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 6),
                              child: ExcludeSemantics(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusLine,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: deckText(
                                  context,
                                  12.5,
                                  weight: FontWeight.w500,
                                  height: 18,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pendingSync > 0)
                        DeckToneChip(
                          label: t(
                            TechnicianKeys.technicianDeckOfflinePending,
                            {'count': pendingSync},
                          ),
                          tone: syncHasConflict
                              ? StatusTone.danger
                              : StatusTone.warning,
                          icon: Icons.cloud_off_rounded,
                        ),
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      key: const Key('inspection-job-reference'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: deckText(
                        context,
                        11.5,
                        height: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
