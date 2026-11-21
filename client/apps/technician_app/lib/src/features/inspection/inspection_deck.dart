import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../inspection_models.dart';
import '../../ui_helpers.dart';
import 'clean_shared.dart';

const double _radiusControl = 999;
const double _radiusCard = 16;

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

/// The vehicle workspace as an inspection deck: one focused item, a section
/// rail, and the next stops. The assessment itself opens on the item route.
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

  /// Compact action shown in the header, before the progress pill.
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
    final items = checklist.itemsForCategory(category.code);
    final checklistItems = [...items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final focused = _focused(checklistItems, focusedItemCode);
    final next = checklistItems
        .where((item) => item.itemCode != focused?.itemCode)
        .toList(growable: false);
    final language = Localizations.localeOf(context).languageCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final content = ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            wide ? 24 : 16,
            8,
            wide ? 24 : 16,
            32,
          ),
          children: [
            if (banner != null) ...[banner!, const SizedBox(height: 14)],
            if (!wide) ...[
              _SectionChips(
                categories: categories,
                checklist: checklist,
                selected: category.code,
                locale: locale,
                onSelected: onCategory,
              ),
              const SizedBox(height: 14),
            ],
            if (focused != null) ...[
              Text(
                '${t(TechnicianKeys.technicianInspection).toUpperCase()} · '
                '${category.nameFor(language).toUpperCase()}',
                style: _eyebrow(context),
              ),
              const SizedBox(height: 8),
              _FocusedItemCard(
                item: focused,
                language: language,
                t: t,
                onOpen: () => onOpen(focused),
              ),
            ],
            if (next.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    t(TechnicianKeys.technicianNextUp).toUpperCase(),
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
              _NextItems(
                items: next,
                language: language,
                t: t,
                onFocus: onFocus,
                onOpen: onOpen,
              ),
            ],
            const SizedBox(height: 18),
            _SummaryStrip(onTap: onSummary),
          ],
        );
        if (!wide) {
          return Column(
            children: [
              _TopBar(
                checklist: checklist,
                onBack: onBack,
                trailing: headerTrailing,
              ),
              Expanded(child: content),
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                _TopBar(
                  checklist: checklist,
                  onBack: onBack,
                  trailing: headerTrailing,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 200,
                        child: _CategoryRail(
                          categories: categories,
                          checklist: checklist,
                          selected: category.code,
                          locale: locale,
                          onSelected: onCategory,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chrome(BuildContext context, UiStrings t, {required Widget child}) {
    return Column(
      children: [
        _TopBar(checklist: checklist, onBack: onBack, trailing: headerTrailing),
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

  ChecklistItem? _focused(List<ChecklistItem> items, String? code) {
    if (items.isEmpty) {
      return null;
    }
    if (code != null) {
      for (final item in items) {
        if (item.itemCode == code) {
          return item;
        }
      }
    }
    for (final item in items) {
      if (item.assessment?.resultCode == null) {
        return item;
      }
    }
    return items.first;
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
          const SizedBox(width: 8),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          _ProgressPill(value: checklist.completed, total: checklist.total),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.value, required this.total});

  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_radiusControl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        '$value/$total',
        style: _text(
          context,
          12.5,
          weight: FontWeight.w700,
          height: 16,
          tabular: true,
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
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
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
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 24),
      children: [
        Text(
          UiStrings.of(context)(TechnicianKeys.technicianInspectionModules)
              .toUpperCase(),
          style: _eyebrow(context),
        ),
        const SizedBox(height: 8),
        for (final category in categories)
          _RailTile(
            category: category,
            checklist: checklist,
            selected: category.code == selected,
            locale: locale,
            onTap: () => onSelected(category.code),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsetsDirectional.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            UiStrings.of(context)(TechnicianKeys.technicianStartHint),
            style: _text(
              context,
              12,
              height: 17,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.category,
    required this.checklist,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  final Category category;
  final Checklist checklist;
  final bool selected;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = checklist.itemsForCategory(category.code);
    final done = items
        .where((item) => item.assessment?.resultCode != null)
        .length;
    return Semantics(
      button: true,
      selected: selected,
      label: category.nameFor(locale),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          margin: const EdgeInsetsDirectional.only(bottom: 2),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? context.brand.container : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                categoryIconFor(category.iconCode),
                size: 16,
                color: selected
                    ? context.brand.onContainer
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.nameFor(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    context,
                    13,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 17,
                    color: selected
                        ? context.brand.onContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$done/${items.length}',
                style: _text(
                  context,
                  11.5,
                  weight: FontWeight.w600,
                  height: 15,
                  tabular: true,
                  color: selected
                      ? context.brand.onContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionChips extends StatelessWidget {
  const _SectionChips({
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
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final items = checklist.itemsForCategory(category.code);
          final done = items
              .where((item) => item.assessment?.resultCode != null)
              .length;
          final isSelected = category.code == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label: category.nameFor(locale),
            child: GestureDetector(
              onTap: () => onSelected(category.code),
              child: Container(
                height: 30,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? context.brand.container : colors.surface,
                  borderRadius: BorderRadius.circular(_radiusControl),
                  border: Border.all(
                    color: isSelected
                        ? context.brand.ink.withValues(alpha: 0.28)
                        : colors.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      category.nameFor(locale),
                      style: _text(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        height: 16,
                        color: isSelected
                            ? context.brand.onContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$done/${items.length}',
                      style: _text(
                        context,
                        11,
                        weight: FontWeight.w600,
                        height: 14,
                        tabular: true,
                        color: isSelected
                            ? context.brand.onContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FocusedItemCard extends ConsumerWidget {
  const _FocusedItemCard({
    required this.item,
    required this.language,
    required this.t,
    required this.onOpen,
  });

  final ChecklistItem item;
  final String language;
  final UiStrings t;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultRecords = ref.watch(enumsProvider('result')).value;
    final colors = context.colors;
    final result = item.assessment?.resultCode;
    final instruction = item.instructionFor(language);
    final spec = item.standardSpecFor(language);
    return Container(
      padding: const EdgeInsetsDirectional.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.labelFor(language),
                  style: _text(
                    context,
                    17,
                    weight: FontWeight.w700,
                    height: 23,
                    tracking: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ResultChip(
                label: result == null
                    ? t(TechnicianKeys.notChecked)
                    : resultLabel(resultRecords, result),
                tone: resultTone(resultRecords, result),
              ),
            ],
          ),
          if (instruction != null && instruction.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              instruction,
              style: _text(
                context,
                13.5,
                height: 19,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (spec != null && spec.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      spec,
                      style: _text(
                        context,
                        12.5,
                        height: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
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
              if (item.measurementUnit != null)
                _ToneChip(
                  label:
                      '${t(TechnicianKeys.technicianUnit)}: ${item.measurementUnit}',
                  tone: StatusTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _PillButton(
            label: result == null
                ? t(TechnicianKeys.start)
                : t(TechnicianKeys.technicianContinueChecklist),
            icon: Icons.arrow_forward_rounded,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _NextItems extends StatelessWidget {
  const _NextItems({
    required this.items,
    required this.language,
    required this.t,
    required this.onFocus,
    required this.onOpen,
  });

  final List<ChecklistItem> items;
  final String language;
  final UiStrings t;
  final ValueChanged<ChecklistItem> onFocus;
  final ValueChanged<ChecklistItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visible = items.take(4).toList(growable: false);
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
            for (var index = 0; index < visible.length; index++) ...[
              _NextRow(
                item: visible[index],
                language: language,
                t: t,
                onTap: () {
                  onFocus(visible[index]);
                  onOpen(visible[index]);
                },
              ),
              if (index != visible.length - 1)
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

class _NextRow extends ConsumerWidget {
  const _NextRow({
    required this.item,
    required this.language,
    required this.t,
    required this.onTap,
  });

  final ChecklistItem item;
  final String language;
  final UiStrings t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultRecords = ref.watch(enumsProvider('result')).value;
    final colors = context.colors;
    final result = item.assessment?.resultCode;
    return Semantics(
      button: true,
      label: item.labelFor(language),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: result == null
                      ? colors.outline
                      : context.statusColors
                            .forTone(resultTone(resultRecords, result))
                            .foreground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.labelFor(language),
                  style: _text(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                result == null
                    ? t(TechnicianKeys.notChecked)
                    : resultLabel(resultRecords, result),
                style: _text(
                  context,
                  11.5,
                  height: 15,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
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

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.onTap});

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

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
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
              11.5,
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
      height: 26,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(_radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: pair.foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: _text(
              context,
              11,
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

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: context.brand.ink,
        borderRadius: BorderRadius.circular(_radiusControl),
        child: InkWell(
          borderRadius: BorderRadius.circular(_radiusControl),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: _text(
                  context,
                  14.5,
                  weight: FontWeight.w700,
                  height: 18,
                  color: Colors.white,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
