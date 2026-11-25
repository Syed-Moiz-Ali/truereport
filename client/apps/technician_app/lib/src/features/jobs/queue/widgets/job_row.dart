import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../../../inspection_models.dart';
import '../jobs_queue_format.dart';
import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';
import '../queue_model.dart';

/// Copy for a [QueueVerb]. The mapping lives here (not in the pure model) so
/// `queue_model.dart` stays free of l10n and widgets.
String queueVerbLabel(UiStrings t, QueueVerb verb) {
  switch (verb) {
    case QueueVerb.start:
      return t(TechnicianKeys.start);
    case QueueVerb.continueJob:
      return t(TechnicianKeys.technicianQueueActionContinue);
    case QueueVerb.finish:
      return t(TechnicianKeys.technicianQueueActionFinish);
    case QueueVerb.view:
      return t(TechnicianKeys.technicianQueueActionView);
  }
}

/// One queue row: time · vehicle · plate + items · the state-derived verb.
///
/// The whole row is the tap target (78 px minimum); the verb is a label, not a
/// nested button, so there is exactly one action and one focus stop per job.
/// Status is deliberately absent: the filter carries it, and a status never
/// appears twice in the same view.
class JobRow extends StatefulWidget {
  const JobRow({
    required this.job,
    required this.verb,
    required this.onTap,
    this.selected = false,
    this.showDate = false,
    super.key,
  });

  final JobSummary job;
  final QueueVerb verb;
  final VoidCallback onTap;

  /// True when this row feeds the tablet preview pane.
  final bool selected;

  /// Unfinished work spans days, so the gutter prints the date above the time
  /// instead of a bare hour that could belong to any day.
  final bool showDate;

  @override
  State<JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<JobRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final brand = context.brand;
    final job = widget.job;
    final plate = (job.vehiclePlate ?? '').trim();
    final time = queueSlotLabel(job);
    final locale = Localizations.localeOf(context).toString();
    final moment = queueMoment(job);
    final dateLabel = widget.showDate && moment != null
        ? queueDateFormat(moment, locale, weekday: false)
        : '';
    final vehicle = queueVehicleLabel(job);
    final verbLabel = queueVerbLabel(t, widget.verb);
    final items = job.totalItems > 0
        ? t(TechnicianKeys.technicianQueueItems, {
            'done': job.completedItems,
            'total': job.totalItems,
          })
        : '';
    final background = widget.selected
        ? brand.container
        : _hovered
        ? colors.surfaceContainerLow
        : Colors.transparent;
    final semantics = <String>[
      verbLabel,
      if (dateLabel.isNotEmpty) dateLabel,
      if (time.isNotEmpty) time,
      vehicle,
      if (plate.isNotEmpty) plate,
      if (items.isNotEmpty) items,
    ].join(', ');

    return Semantics(
      button: true,
      selected: widget.selected,
      label: semantics,
      child: FocusableActionDetector(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 120),
              ),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 78),
              color: background,
              foregroundDecoration: widget.selected
                  ? BoxDecoration(
                      border: BorderDirectional(
                        start: BorderSide(color: brand.ink, width: 3),
                      ),
                    )
                  : _focused
                  ? BoxDecoration(
                      border: Border.all(color: colors.focus, width: 2),
                    )
                  : null,
              padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 12, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dateLabel.isNotEmpty) ...[
                          Text(
                            dateLabel,
                            textDirection: TextDirection.ltr,
                            maxLines: 1,
                            style: queueText(
                              context,
                              10,
                              weight: FontWeight.w700,
                              height: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 1),
                        ],
                        Text(
                          time.isEmpty ? '—' : time,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          style: queueText(
                            context,
                            14,
                            weight: FontWeight.w800,
                            height: 18,
                            tabular: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vehicle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: queueText(
                            context,
                            15,
                            weight: FontWeight.w700,
                            height: 20,
                            tracking: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (plate.isNotEmpty) QueuePlate(plate),
                            if (items.isNotEmpty)
                              Text(
                                items,
                                textDirection: TextDirection.ltr,
                                style: queueMeta(
                                  context,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: brand.container,
                      borderRadius: BorderRadius.circular(
                        QueueMetrics.radiusChip,
                      ),
                    ),
                    child: Text(
                      verbLabel,
                      maxLines: 1,
                      style: queueText(
                        context,
                        12.5,
                        weight: FontWeight.w700,
                        height: 16,
                        color: brand.onContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
