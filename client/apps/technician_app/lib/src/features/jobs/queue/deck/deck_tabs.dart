import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../jobs_queue_style.dart';
import 'deck_sets.dart';

/// The deck set switcher: Today / Upcoming / Unfinished with counts.
///
/// The tabs re-bucket the already-loaded page; they never fetch. Selected is
/// a white pill with ink text, counts ride in bubbles. Cancelled jobs never
/// appear in any bucket.

/// Copy for a [DeckTab]. The mapping lives here so the bucketing stays pure.
String deckTabLabel(UiStrings t, DeckTab tab) {
  switch (tab) {
    case DeckTab.today:
      return t(TechnicianKeys.technicianQueueSectionToday);
    case DeckTab.upcoming:
      return t(TechnicianKeys.technicianQueueSectionUpcoming);
    case DeckTab.unfinished:
      return t(TechnicianKeys.technicianQueueSectionUnfinished);
  }
}

class DeckTabs extends StatelessWidget {
  const DeckTabs({
    required this.today,
    required this.upcoming,
    required this.unfinished,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final int today;
  final int upcoming;
  final int unfinished;
  final DeckTab selected;
  final ValueChanged<DeckTab> onSelect;

  int _count(DeckTab tab) {
    switch (tab) {
      case DeckTab.today:
        return today;
      case DeckTab.upcoming:
        return upcoming;
      case DeckTab.unfinished:
        return unfinished;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            for (final tab in DeckTab.values)
              Expanded(
                child: _Segment(
                  label: deckTabLabel(UiStrings.of(context), tab),
                  count: _count(tab),
                  selected: tab == selected,
                  onSelect: () => onSelect(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelect;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final foreground = widget.selected
        ? colors.onSurface
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.label}, ${widget.count}',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onSelect();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: context.motionDuration(const Duration(milliseconds: 140)),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: widget.selected
                  ? colors.surfaceLowest
                  : _hovered
                  ? colors.surfaceContainerLow
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
              border: Border.all(
                color: _focused ? colors.focus : Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.selected ? context.shadows.buttonSubtle : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: queueText(
                      context,
                      13,
                      weight: FontWeight.w700,
                      height: 18,
                      color: foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? brand.container
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(
                      QueueMetrics.radiusChip,
                    ),
                  ),
                  child: Text(
                    '${widget.count}',
                    textDirection: TextDirection.ltr,
                    style: queueText(
                      context,
                      12,
                      weight: FontWeight.w700,
                      height: 16,
                      tabular: true,
                      color: widget.selected
                          ? brand.onContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
