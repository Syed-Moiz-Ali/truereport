import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../../inspection_models.dart';
import '../../../ui_helpers.dart';
import 'deck_header.dart';

/// The selected section as a ledger: every item, in checklist order, with its
/// state visible at a glance.
///
/// One column under 840 px, two columns above it; the row itself is always the
/// tap target (no chevron), and the focused item keeps the 3 px start marker.
class DeckLedger extends StatelessWidget {
  const DeckLedger({
    required this.items,
    required this.language,
    required this.nextItemCode,
    required this.focusedItemCode,
    required this.wide,
    required this.allAssessed,
    required this.onOpen,
    super.key,
  });

  final List<ChecklistItem> items;
  final String language;
  final String? nextItemCode;
  final String? focusedItemCode;

  /// Row detail (spec/unit, multi-point pill) is kept from 760 px up.
  final bool wide;

  /// True only when every item in every section already has a result.
  final bool allAssessed;

  final ValueChanged<ChecklistItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    if (items.isEmpty) {
      // "All caught up" is scoped to a section that has no items left and only
      // renders when the whole job is complete; it is never a global claim
      // while other sections still have work.
      return EmptyState(
        title: t(TechnicianKeys.technicianNoItems),
        body: allAssessed
            ? t(TechnicianKeys.technicianAllCaughtUp)
            : t(TechnicianKeys.technicianStartHint),
        icon: Icons.checklist_rounded,
      );
    }

    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 840 ? 2 : 1;
        final rows = (items.length + columns - 1) ~/ columns;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var row = 0; row < rows; row++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var column = 0; column < columns; column++)
                        Expanded(child: _cell(row * columns + column)),
                    ],
                  ),
                  if (row != rows - 1)
                    Divider(
                      height: 1,
                      color: colors.outlineVariant,
                      indent: 14,
                      endIndent: 14,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cell(int index) {
    if (index >= items.length) {
      return const SizedBox.shrink();
    }
    final item = items[index];
    return _LedgerRow(
      key: ValueKey<String>(item.itemCode),
      item: item,
      number: index + 1,
      language: language,
      wide: wide,
      current: item.itemCode == (focusedItemCode ?? nextItemCode),
      onTap: () => onOpen(item),
    );
  }
}

class _LedgerRow extends ConsumerStatefulWidget {
  const _LedgerRow({
    required this.item,
    required this.number,
    required this.language,
    required this.wide,
    required this.current,
    required this.onTap,
    super.key,
  });

  final ChecklistItem item;
  final int number;
  final String language;
  final bool wide;
  final bool current;
  final VoidCallback onTap;

  @override
  ConsumerState<_LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends ConsumerState<_LedgerRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final item = widget.item;
    final results = ref.watch(enumsProvider('result')).value;
    final result = item.assessment?.resultCode;
    // An unanswered item is the default state, so it carries no chip: thirty
    // identical "Not checked" pills were most of the ledger's visual noise.
    final stateLabel = result == null ? null : resultLabel(results, result);
    final stateTone = result == null
        ? StatusTone.neutral
        : resultTone(results, result);

    final background = _hovered
        ? colors.surfaceContainerLow
        : Colors.transparent;

    return Semantics(
      button: true,
      label:
          '${item.labelFor(widget.language)}, '
          '${stateLabel ?? t(TechnicianKeys.notChecked)}',
      child: FocusableActionDetector(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
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
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      border: Border.all(color: colors.focus, width: 2),
                    )
                  : null,
              decoration: BoxDecoration(
                color: background,
                border: BorderDirectional(
                  start: BorderSide(
                    color: widget.current
                        ? context.brand.ink
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsetsDirectional.fromSTEB(11, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: Text(
                        '${widget.number}'.padLeft(2, '0'),
                        textDirection: TextDirection.ltr,
                        style: deckText(
                          context,
                          11,
                          weight: FontWeight.w700,
                          height: 15,
                          tabular: true,
                          color: widget.current
                              ? context.brand.ink
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                item.labelFor(widget.language),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: deckText(
                                  context,
                                  14,
                                  weight: FontWeight.w600,
                                  height: 19,
                                ),
                              ),
                            ),
                            if (item.safetyCritical) ...[
                              const SizedBox(width: 6),
                              DeckToneChip(
                                label: t(
                                  TechnicianKeys.technicianSafetyCritical,
                                ),
                                tone: StatusTone.danger,
                                icon: Icons.health_and_safety_outlined,
                                small: true,
                              ),
                            ],
                          ],
                        ),
                        if (stateLabel != null ||
                            item.multiPoint ||
                            widget.wide) ...[
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (stateLabel != null)
                                _ResultChip(
                                  label: stateLabel,
                                  tone: stateTone,
                                  small: !widget.wide,
                                ),
                              if (item.multiPoint)
                                (widget.wide
                                    ? DeckToneChip(
                                        label: t(
                                          TechnicianKeys.technicianMultiPoint,
                                        ),
                                        tone: StatusTone.info,
                                        icon: Icons.grid_on_outlined,
                                        small: true,
                                      )
                                    : Tooltip(
                                        message: t(
                                          TechnicianKeys.technicianMultiPoint,
                                        ),
                                        child: Icon(
                                          Icons.grid_on_outlined,
                                          size: 13,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      )),
                              if (widget.wide) _detailLine(context, t, item),
                            ],
                          ),
                        ],
                      ],
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

  /// The measurement standard and unit, kept on one quiet line where width
  /// allows it. The phone keeps the label and the state.
  Widget _detailLine(BuildContext context, UiStrings t, ChecklistItem item) {
    final spec = item.standardSpecFor(widget.language)?.trim() ?? '';
    final unit = item.measurementUnit;
    final text = spec.isNotEmpty
        ? spec
        : unit != null
        ? '${t(TechnicianKeys.technicianUnit)}: $unit'
        : '';
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: deckText(
          context,
          11,
          height: 15,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.tone,
    this.small = false,
  });

  final String label;
  final StatusTone tone;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Container(
      constraints: BoxConstraints(minHeight: small ? 24 : 28),
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: pair.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: deckText(
              context,
              small ? 10.5 : 11.5,
              weight: FontWeight.w700,
              height: 14,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
