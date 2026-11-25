import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/shared/technician_intl.dart';

import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';
import '../queue_model.dart';

/// Plain view data for one deck card. The page resolves every label, tone and
/// verb from providers; the board itself never touches status codes.
class DeckJob {
  const DeckJob({
    required this.id,
    required this.vehicle,
    required this.plate,
    required this.customer,
    required this.reference,
    required this.time,
    required this.statusLabel,
    required this.tone,
    required this.done,
    required this.total,
    required this.verb,
    required this.nextUp,
  });

  final String id;
  final String vehicle;
  final String plate;
  final String customer;
  final String reference;
  final String time;
  final String statusLabel;
  final StatusTone tone;
  final int done;
  final int total;
  final QueueVerb verb;
  final String? nextUp;

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

/// The deck: stacked peeks behind one soft white front card.
///
/// Peeks read NEXT / THEN with the vehicle and time behind the front card;
/// tapping any card selects it. The deck must read as a deck in a still
/// image, so the stack is static — only the front content crossfades on
/// selection (≤ 240 ms, reduced-motion aware).
class DeckBoard extends StatelessWidget {
  const DeckBoard({
    required this.jobs,
    required this.frontId,
    required this.onSelect,
    super.key,
  });

  /// Time-ascending bucket contents, at least one job.
  final List<DeckJob> jobs;
  final String frontId;
  final ValueChanged<DeckJob> onSelect;

  @override
  Widget build(BuildContext context) {
    assert(jobs.isNotEmpty);
    final t = UiStrings.of(context);
    final index = jobs.indexWhere((job) => job.id == frontId);
    final front = index < 0 ? jobs.first : jobs[index];
    final at = index < 0 ? 0 : index;
    final next = jobs.length > 1 ? jobs[(at + 1) % jobs.length] : null;
    final then = jobs.length > 2 ? jobs[(at + 2) % jobs.length] : null;
    // Peeks are fixed-height strips pinned to the top; the front card lays
    // out below them with a 26 px overlap so the stack reads as a deck.
    // In symmetric insets the stack mirrors safely in RTL.
    const peekHeight = 54.0;
    const peekStep = 28.0;
    final reveal =
        (then != null ? peekStep : 0.0) + (next != null ? peekStep : 0.0);
    return AnimatedSwitcher(
      duration: context.motionDuration(const Duration(milliseconds: 220)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Stack(
        key: ValueKey('deck-front-$frontId'),
        children: [
          if (then != null)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              height: peekHeight,
              child: _PeekBar(
                label: t(TechnicianKeys.technicianDeckThen).toUpperCase(),
                job: then,
                onSelect: () => onSelect(then),
              ),
            ),
          if (next != null)
            Positioned(
              top: then != null ? peekStep : 0,
              left: 8,
              right: 8,
              height: peekHeight,
              child: _PeekBar(
                label: t(TechnicianKeys.technicianDeckNext).toUpperCase(),
                job: next,
                onSelect: () => onSelect(next),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: reveal),
            child: _FrontCard(job: front, onSelect: () => onSelect(front)),
          ),
        ],
      ),
    );
  }
}

class _PeekBar extends StatelessWidget {
  const _PeekBar({
    required this.label,
    required this.job,
    required this.onSelect,
  });

  final String label;
  final DeckJob job;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '${job.vehicle}, ${job.time}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: Container(
          height: 54,
          padding: const EdgeInsetsDirectional.only(
            start: 20,
            end: 20,
            top: 10,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Text(label, style: queueEyebrow(context)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.vehicle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: queueText(
                    context,
                    14,
                    weight: FontWeight.w700,
                    height: 18,
                    tracking: -0.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (job.time.isNotEmpty)
                Text(
                  job.time,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  style: queueText(
                    context,
                    13,
                    weight: FontWeight.w600,
                    height: 18,
                    tabular: true,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrontCard extends StatelessWidget {
  const _FrontCard({required this.job, required this.onSelect});

  final DeckJob job;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final percent = (job.fraction * 100).round();
    return Semantics(
      button: true,
      selected: true,
      label: '${job.vehicle}, ${job.statusLabel}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: context.shadows.floating,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  QueueStatusChip(label: job.statusLabel, tone: job.tone),
                  const Spacer(),
                  if (job.time.isNotEmpty) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.time,
                      textDirection: TextDirection.ltr,
                      style: queueText(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        height: 18,
                        tabular: true,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(job.vehicle, style: queueDeckVehicle(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (job.plate.isNotEmpty) QueuePlate(job.plate),
                  Text(
                    job.customer,
                    style: queueText(
                      context,
                      13,
                      height: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (job.nextUp != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 2),
                        child: Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 16,
                          color: context.brand.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t(TechnicianKeys.technicianNextUp).toUpperCase(),
                              style: queueEyebrow(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job.nextUp!,
                              style: queueText(
                                context,
                                15,
                                weight: FontWeight.w600,
                                height: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t(TechnicianKeys.technicianQueueItems, {
                        'done': job.done,
                        'total': job.total,
                      }),
                      style: queueText(
                        context,
                        14,
                        weight: FontWeight.w700,
                        height: 20,
                        tabular: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatPercentLocalized(percent, locale),
                    textDirection: TextDirection.ltr,
                    style: queueText(
                      context,
                      14,
                      weight: FontWeight.w700,
                      height: 20,
                      tabular: true,
                      color: context.brand.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (job.done > 0 && job.total > 0)
                QueueProgressBar(value: job.done, total: job.total)
              else
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      QueueMetrics.radiusChip,
                    ),
                  ),
                ),
              if (job.reference.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  job.reference,
                  textDirection: TextDirection.ltr,
                  style: queueText(
                    context,
                    12.5,
                    height: 18,
                    tabular: true,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered text link under the deck. The page wires it to the existing
/// clear-search/reset behaviour; it never opens a new screen.
class DeckSeeAllLink extends StatelessWidget {
  const DeckSeeAllLink({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: t(TechnicianKeys.technicianDeckSeeAll),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    t(TechnicianKeys.technicianDeckSeeAll),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: queueText(
                      context,
                      14,
                      weight: FontWeight.w700,
                      height: 20,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
