import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../inspection_models.dart';
import '../../ui_helpers.dart';

const double _radiusControl = 999;
const double _radiusCard = 16;

/// Width the deck is allowed to reach on a desktop window.
const double _deckMaxWidth = 1000;

TextStyle _text(
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

/// The vehicle workspace as a section ledger: the selected section, in
/// checklist order, with every item's state visible at once and the next
/// unchecked item pinned in the footer.
///
/// The assessment itself still opens on the item route — this surface answers
/// "what is left in this section and what do I start next", not "how do I
/// assess this one".
class InspectionDeck extends StatelessWidget {
  const InspectionDeck({
    required this.checklist,
    required this.jobId,
    required this.selectedCategory,
    required this.focusedItemCode,
    required this.onCategory,
    required this.onFocus,
    required this.onOpen,
    required this.onSummary,
    required this.onBack,
    this.banner,
    this.headerTrailing,
    super.key,
  });

  final Checklist checklist;
  final String jobId;
  final String? selectedCategory;
  final String? focusedItemCode;
  final ValueChanged<String> onCategory;
  final ValueChanged<ChecklistItem> onFocus;
  final ValueChanged<ChecklistItem> onOpen;
  final VoidCallback onSummary;
  final VoidCallback onBack;

  /// Inline note shown above the deck content (for example the missing-photo
  /// banner). Never blocks the deck.
  final Widget? banner;

  /// Compact action shown in the header, before the progress line.
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (categories.isEmpty) {
      return _chrome(
        context,
        t,
        child: EmptyState(
          title: t(TechnicianKeys.technicianNoCategories),
          body: t(TechnicianKeys.technicianNoItems),
          icon: Icons.checklist_rounded,
        ),
      );
    }
    final code = selectedCategory ?? categories.first.code;
    final category = categories.firstWhere(
      (value) => value.code == code,
      orElse: () => categories.first,
    );
    final items = [...checklist.itemsForCategory(category.code)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final answered = items
        .where((item) => item.assessment?.resultCode != null)
        .length;
    // The next stop is the first item without a result: a ledger should
    // continue in order, not jump to whatever was touched last.
    final nextIndex = items.indexWhere(
      (item) => item.assessment?.resultCode == null,
    );
    final next = nextIndex >= 0 ? items[nextIndex] : null;
    final sectionName = category.nameFor(locale);
    final language = Localizations.localeOf(context).languageCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Column(
          children: [
            _Capped(
              maxWidth: _deckMaxWidth,
              child: _TopBar(
                checklist: checklist,
                onBack: onBack,
                trailing: headerTrailing,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                wide ? 24 : 16,
                0,
                wide ? 24 : 16,
                10,
              ),
              child: _Capped(
                maxWidth: _deckMaxWidth,
                child: _ProgressLine(
                  done: answered,
                  total: items.length,
                  sectionName: sectionName,
                  overallDone: checklist.completed,
                  overallTotal: checklist.total,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  wide ? 24 : 16,
                  2,
                  wide ? 24 : 16,
                  28,
                ),
                children: [
                  _Capped(
                    maxWidth: _deckMaxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (banner != null) ...[
                          banner!,
                          const SizedBox(height: 12),
                        ],
                        _SectionTabs(
                          categories: categories,
                          checklist: checklist,
                          selected: category.code,
                          locale: locale,
                          onSelected: onCategory,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              t(TechnicianKeys.technicianChecklistOrder),
                              style: _eyebrow(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: context.colors.outlineVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: 18,
                            ),
                            child: EmptyState(
                              title: t(TechnicianKeys.technicianNoItems),
                              body: t(TechnicianKeys.technicianStartHint),
                              icon: Icons.checklist_rounded,
                            ),
                          )
                        else
                          _Ledger(
                            items: items,
                            language: language,
                            nextItemCode: next?.itemCode,
                            focusedItemCode: focusedItemCode,
                            wide: wide,
                            onOpen: (item) {
                              onFocus(item);
                              onOpen(item);
                            },
                          ),
                        const SizedBox(height: 14),
                        _SummaryRow(onTap: onSummary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _DeckFooter(
              next: next,
              sectionName: sectionName,
              onOpen: () {
                if (next != null) {
                  onFocus(next);
                  onOpen(next);
                }
              },
              onSummary: onSummary,
            ),
          ],
        );
      },
    );
  }

  Widget _chrome(BuildContext context, UiStrings t, {required Widget child}) {
    return Column(
      children: [
        _Capped(
          maxWidth: _deckMaxWidth,
          child: _TopBar(
            checklist: checklist,
            onBack: onBack,
            trailing: headerTrailing,
          ),
        ),
        if (banner != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: banner,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: child,
          ),
        ),
      ],
    );
  }
}

TextStyle _eyebrow(BuildContext context) => _text(
  context,
  11,
  weight: FontWeight.w700,
  height: 14,
  tracking: 0.9,
  color: context.colors.onSurfaceVariant,
);

/// Centres a band of the deck on the shared measure.
class _Capped extends StatelessWidget {
  const _Capped({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.checklist, required this.onBack, this.trailing});

  final Checklist checklist;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final job = checklist.job;
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
      if (job.vehicleYear != null) '${job.vehicleYear}',
    ].where((value) => value.isNotEmpty).join(' ');
    final plate = (job.vehiclePlate ?? '').trim();
    final reference = job.reference.trim();
    // The plate falls back to the reference, so only show the separate
    // reference label when the plate is actually present and different.
    final showReference =
        reference.isNotEmpty && plate.isNotEmpty && plate != reference;
    final customer = job.customerName.trim();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            child: GestureDetector(
              onTap: onBack,
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
                Text(
                  vehicle,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: _text(
                    context,
                    18,
                    weight: FontWeight.w700,
                    height: 23,
                    tracking: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Plate(plate.isNotEmpty ? plate : reference),
                    if (showReference)
                      Text(
                        reference,
                        key: const Key('inspection-job-reference'),
                        maxLines: 1,
                        style: _text(
                          context,
                          11.5,
                          weight: FontWeight.w500,
                          height: 16,
                          tracking: 0.3,
                          tabular: true,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (customer.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            context,
                            12.5,
                            height: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Section progress: one bar, and the two counts that matter.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.done,
    required this.total,
    required this.sectionName,
    required this.overallDone,
    required this.overallTotal,
  });

  final int done;
  final int total;
  final String sectionName;
  final int overallDone;
  final int overallTotal;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final fraction = overallTotal <= 0
        ? 0.0
        : (overallDone / overallTotal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_radiusControl),
          child: SizedBox(
            height: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: colors.surfaceContainerHighest),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: fraction,
                  child: ColoredBox(color: context.brand.ink),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${t(TechnicianKeys.technicianSectionProgress, {'done': done, 'total': total, 'section': sectionName})} · ${t(TechnicianKeys.technicianOverallProgress, {'done': overallDone, 'total': overallTotal})}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _text(
            context,
            11.5,
            weight: FontWeight.w500,
            height: 16,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The section switcher: underline tabs, so the deck reads as one document.
class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
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
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in categories) ...[
                _SectionTab(
                  category: category,
                  checklist: checklist,
                  locale: locale,
                  selected: category.code == selected,
                  onTap: () => onSelected(category.code),
                ),
                const SizedBox(width: 20),
              ],
            ],
          ),
        ),
        Container(height: 1, color: colors.outlineVariant),
      ],
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.category,
    required this.checklist,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final Checklist checklist;
  final String locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = checklist.itemsForCategory(category.code);
    final done = items
        .where((item) => item.assessment?.resultCode != null)
        .length;
    final colors = context.colors;
    final fg = selected ? colors.onSurface : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: category.nameFor(locale),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsetsDirectional.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? colors.onSurface : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.nameFor(locale),
                  style: _text(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    height: 17,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$done/${items.length}',
                  style: _text(
                    context,
                    11,
                    weight: FontWeight.w600,
                    height: 16,
                    tabular: true,
                    color: selected
                        ? colors.onSurfaceVariant
                        : colors.onSurfaceVariant.withValues(alpha: 0.75),
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

/// One card, every item of the section, in checklist order.
class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.items,
    required this.language,
    required this.nextItemCode,
    required this.focusedItemCode,
    required this.wide,
    required this.onOpen,
  });

  final List<ChecklistItem> items;
  final String language;
  final String? nextItemCode;
  final String? focusedItemCode;
  final bool wide;
  final ValueChanged<ChecklistItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radiusCard),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _LedgerRow(
                item: items[index],
                number: index + 1,
                language: language,
                wide: wide,
                current:
                    items[index].itemCode == (focusedItemCode ?? nextItemCode),
                onTap: () => onOpen(items[index]),
              ),
              if (index != items.length - 1)
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
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final background = _hovered
        ? colors.surfaceContainerLow
        : Colors.transparent;

    return Semantics(
      button: true,
      label: item.labelFor(widget.language),
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
                        style: _text(
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
                          children: [
                            if (!widget.wide && item.safetyCritical) ...[
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 13,
                                color: context.statusColors.danger.foreground,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                item.labelFor(widget.language),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _text(
                                  context,
                                  14,
                                  weight: FontWeight.w600,
                                  height: 19,
                                ),
                              ),
                            ),
                            if (!widget.wide && item.multiPoint) ...[
                              const SizedBox(width: 5),
                              Icon(
                                Icons.grid_on_outlined,
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        if (widget.wide) _rowDetail(context, t, item),
                        // On a phone the state moves under the label: a chip
                        // that stays inline would squeeze the item name, and
                        // the item name is what the technician scans for.
                        if (!widget.wide) ...[
                          const SizedBox(height: 5),
                          _ResultChip(
                            label: result == null
                                ? t(TechnicianKeys.notChecked)
                                : resultLabel(results, result),
                            tone: resultTone(results, result),
                            small: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.wide)
                    _ResultChip(
                      label: result == null
                          ? t(TechnicianKeys.notChecked)
                          : resultLabel(results, result),
                      tone: resultTone(results, result),
                    ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: widget.wide ? 4 : 2,
                    ),
                    child: Icon(
                      rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
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

  /// Flags and the measurement standard, on one quiet line. Only shown where
  /// there is room; the phone keeps the label and the state.
  Widget _rowDetail(BuildContext context, UiStrings t, ChecklistItem item) {
    final spec = item.standardSpecFor(widget.language)?.trim() ?? '';
    final unit = item.measurementUnit;
    final flags = <Widget>[
      if (item.safetyCritical)
        _ToneChip(
          label: t(TechnicianKeys.technicianSafetyCritical),
          tone: StatusTone.danger,
          icon: Icons.health_and_safety_outlined,
        ),
      if (item.multiPoint)
        _ToneChip(
          label: t(TechnicianKeys.technicianMultiPoint),
          tone: StatusTone.info,
          icon: Icons.grid_on_outlined,
        ),
    ];
    if (flags.isEmpty && spec.isEmpty && unit == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 5),
      child: Row(
        children: [
          for (final flag in flags) ...[flag, const SizedBox(width: 5)],
          if (spec.isNotEmpty)
            Flexible(
              child: Text(
                spec,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(
                  context,
                  11,
                  height: 15,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else if (unit != null)
            Flexible(
              child: Text(
                '${t(TechnicianKeys.technicianUnit)}: $unit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(
                  context,
                  11,
                  height: 15,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Persistent next action for the section.
class _DeckFooter extends StatelessWidget {
  const _DeckFooter({
    required this.next,
    required this.sectionName,
    required this.onOpen,
    required this.onSummary,
  });

  final ChecklistItem? next;
  final String sectionName;
  final VoidCallback onOpen;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final done = next == null;
    final label = done
        ? t(TechnicianKeys.technicianOpenSummary)
        : (next!.assessment?.resultCode == null
              ? t(TechnicianKeys.start)
              : t(TechnicianKeys.technicianContinueChecklist));
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: _Capped(
        maxWidth: _deckMaxWidth,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    done
                        ? sectionName.toUpperCase()
                        : t(TechnicianKeys.technicianNextUp).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      context,
                      9.5,
                      weight: FontWeight.w800,
                      height: 12,
                      tracking: 0.9,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done
                        ? t(TechnicianKeys.technicianAllCaughtUp)
                        : next!.labelFor(
                            Localizations.localeOf(context).languageCode,
                          ),
                    key: const Key('inspection-next-action'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      context,
                      14,
                      weight: FontWeight.w700,
                      height: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FooterButton(
              label: label,
              onPressed: done ? onSummary : onOpen,
              icon: done
                  ? Icons.fact_check_outlined
                  : Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 48,
        child: Material(
          color: context.brand.ink,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      context,
                      14,
                      weight: FontWeight.w700,
                      height: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      label: t(TechnicianKeys.technicianOpenSummary),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsetsDirectional.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(_radiusCard),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: context.brand.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t(TechnicianKeys.technicianOpenSummary),
                  style: _text(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    height: 18,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
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
          Text(
            value,
            style: _text(
              context,
              12,
              weight: FontWeight.w700,
              height: 16,
              tracking: 0.6,
              tabular: true,
            ),
          ),
        ],
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
      height: small ? 24 : 28,
      padding: EdgeInsetsDirectional.symmetric(horizontal: small ? 8 : 10),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(_radiusControl),
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
            style: _text(
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

class _ToneChip extends StatelessWidget {
  const _ToneChip({required this.label, required this.tone, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Container(
      height: 22,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(_radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: pair.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: _text(
              context,
              10,
              weight: FontWeight.w600,
              height: 14,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
