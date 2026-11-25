import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../../inspection_models.dart';
import 'deck_header.dart';

/// Every section, always visible, as a wrapping chip set.
///
/// The old horizontal rail clipped section names at 390 and hid the sections
/// that did not fit. A [Wrap] has no scroll and no hidden state: the technician
/// can see the whole job's shape before choosing where to work.
class DeckSections extends StatelessWidget {
  const DeckSections({
    required this.categories,
    required this.checklist,
    required this.selected,
    required this.locale,
    required this.onSelected,
    super.key,
  });

  final List<Category> categories;
  final Checklist checklist;
  final String selected;
  final String locale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Six long section names stack into six full-width pills at 390 px
        // (~260 px of a 844 px screen). On a phone the sections collapse into
        // one labelled picker that opens a sheet listing every section and its
        // count — explicit, never a clipped rail.
        if (constraints.maxWidth < 600) {
          return _SectionPicker(
            categories: categories,
            checklist: checklist,
            selected: selected,
            locale: locale,
            onSelected: onSelected,
          );
        }
        final t = UiStrings.of(context);
        final chips = <Widget>[];
        for (final category in categories) {
          final counts = _SectionCounts.of(checklist, category);
          chips.add(
            _SectionChip(
              category: category,
              locale: locale,
              selected: category.code == selected,
              done: counts.done,
              total: counts.total,
              progressLabel: t(TechnicianKeys.technicianQueueItems, {
                'done': counts.done,
                'total': counts.total,
              }),
              onTap: () => onSelected(category.code),
            ),
          );
        }
        return Wrap(spacing: 8, runSpacing: 2, children: chips);
      },
    );
  }
}

/// Phone-sized section selector: one control, every section in the sheet.
class _SectionPicker extends StatelessWidget {
  const _SectionPicker({
    required this.categories,
    required this.checklist,
    required this.selected,
    required this.locale,
    required this.onSelected,
  });

  final List<Category> categories;
  final Checklist checklist;
  final String selected;
  final String locale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final brand = context.brand;
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    final current = categories.firstWhere(
      (category) => category.code == selected,
      orElse: () => categories.first,
    );
    final counts = _SectionCounts.of(checklist, current);
    return Semantics(
      button: true,
      label:
          '${t(TechnicianKeys.technicianDeckSections)}: '
          '${current.nameFor(locale)}, '
          '${t(TechnicianKeys.technicianQueueItems, {'done': counts.done, 'total': counts.total})}',
      child: InkWell(
        borderRadius: BorderRadius.circular(context.radii.pill),
        onTap: () => _open(context),
        child: Container(
          height: 48,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.radii.pill),
            border: Border.all(color: brand.ink.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  current.nameFor(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deckText(
                    context,
                    13.5,
                    weight: FontWeight.w700,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${counts.done}/${counts.total}',
                textDirection: TextDirection.ltr,
                style: deckText(
                  context,
                  11.5,
                  weight: FontWeight.w700,
                  height: 15,
                  tabular: true,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 4),
              child: Text(
                t(TechnicianKeys.technicianDeckSections),
                style: deckText(
                  sheetContext,
                  16,
                  weight: FontWeight.w700,
                  height: 21,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final category in categories)
                    _pickerRow(sheetContext, t, category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerRow(BuildContext context, UiStrings t, Category category) {
    final colors = context.colors;
    final counts = _SectionCounts.of(checklist, category);
    final isSelected = category.code == selected;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
      selected: isSelected,
      title: Text(
        category.nameFor(locale),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: deckText(
          context,
          14,
          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          height: 19,
        ),
      ),
      trailing: Text(
        t(TechnicianKeys.technicianQueueItems, {
          'done': counts.done,
          'total': counts.total,
        }),
        style: deckText(
          context,
          11.5,
          weight: FontWeight.w600,
          height: 15,
          color: colors.onSurfaceVariant,
        ),
      ),
      onTap: () {
        Navigator.of(context).maybePop();
        if (!isSelected) {
          onSelected(category.code);
        }
      },
    );
  }
}

class _SectionCounts {
  const _SectionCounts({required this.done, required this.total});

  final int done;
  final int total;

  static _SectionCounts of(Checklist checklist, Category category) {
    final items = checklist.itemsForCategory(category.code);
    var done = 0;
    for (final item in items) {
      if ((item.assessment?.resultCode ?? '').trim().isNotEmpty) {
        done += 1;
      }
    }
    return _SectionCounts(done: done, total: items.length);
  }
}

class _SectionChip extends StatefulWidget {
  const _SectionChip({
    required this.category,
    required this.locale,
    required this.selected,
    required this.done,
    required this.total,
    required this.progressLabel,
    required this.onTap,
  });

  final Category category;
  final String locale;
  final bool selected;
  final int done;
  final int total;
  final String progressLabel;
  final VoidCallback onTap;

  @override
  State<_SectionChip> createState() => _SectionChipState();
}

class _SectionChipState extends State<_SectionChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final name = widget.category.nameFor(widget.locale);
    final semantic = '$name, ${widget.progressLabel}';

    return Semantics(
      button: true,
      selected: widget.selected,
      label: semantic,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 140),
              ),
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: widget.selected ? brand.container : colors.surface,
                borderRadius: BorderRadius.circular(context.radii.pill),
                border: Border.all(
                  color: _focused
                      ? colors.focus
                      : widget.selected
                      ? brand.ink.withValues(alpha: 0.35)
                      : colors.outlineVariant,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: deckText(
                        context,
                        12.5,
                        weight: FontWeight.w700,
                        height: 16,
                        color: widget.selected
                            ? brand.onContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${widget.done}/${widget.total}',
                    textDirection: TextDirection.ltr,
                    style: deckText(
                      context,
                      11,
                      weight: FontWeight.w700,
                      height: 14,
                      tabular: true,
                      color: widget.selected
                          ? brand.onContainer
                          : colors.onSurfaceVariant,
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
