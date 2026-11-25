import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../inspection_models.dart';
import '../../reference_ui.dart';
import '../../shared/technician_intl.dart';
import '../../technician_providers.dart';
import '../../ui_helpers.dart';
import '../jobs/queue/deck/deck_primary.dart';
import '../jobs/queue/jobs_queue_format.dart';
import '../jobs/queue/jobs_queue_primitives.dart';
import '../jobs/queue/jobs_queue_style.dart';
import '../jobs/queue/queue_model.dart';

/// The detail step as a section ledger in the DECK language: header, a
/// 30-tick progress strip, category pills, one hairline-divided item surface
/// and a single primary plus a secondary Summary.
///
/// The assessment itself still opens on the item route — this surface answers
/// "what is left and what do I start next". Routes, providers, the offline
/// queue and every callback stay exactly the jobs flow.
class InspectionDeck extends ConsumerStatefulWidget {
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

  /// Compact action shown in the header (for example the photo thumbnail).
  final Widget? headerTrailing;

  @override
  ConsumerState<InspectionDeck> createState() => _InspectionDeckState();
}

class _InspectionDeckState extends ConsumerState<InspectionDeck> {
  /// Resume selection, computed once per screen: the category holding the
  /// first unanswered item, or the first category when everything is
  /// answered. An explicit [InspectionDeck.selectedCategory] (the user tapped
  /// a pill or a tick) always wins over this sticky default.
  String? _autoCategory;

  List<Category> _categories(Checklist checklist) {
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  List<ChecklistItem> _ordered(Checklist checklist) {
    final items = [...checklist.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  ChecklistItem? _firstUnanswered(List<ChecklistItem> ordered) {
    for (final item in ordered) {
      if (item.assessment?.resultCode == null) {
        return item;
      }
    }
    return null;
  }

  String _effectiveCategory(
    List<Category> categories,
    List<ChecklistItem> ordered,
  ) {
    final explicit = widget.selectedCategory;
    if (explicit != null &&
        categories.any((category) => category.code == explicit)) {
      return explicit;
    }
    final auto = _autoCategory;
    if (auto != null && categories.any((category) => category.code == auto)) {
      return auto;
    }
    final computed =
        _firstUnanswered(ordered)?.categoryCode ?? categories.first.code;
    _autoCategory = computed;
    return computed;
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final checklist = widget.checklist;
    final categories = _categories(checklist);
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
    final ordered = _ordered(checklist);
    final code = _effectiveCategory(categories, ordered);
    final category = categories.firstWhere(
      (value) => value.code == code,
      orElse: () => categories.first,
    );
    final items = checklist.itemsForCategory(category.code).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final readOnly = verbFor(checklist.job) == QueueVerb.view;
    final next = _firstUnanswered(ordered);
    final currentCode = widget.focusedItemCode ?? next?.itemCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Column(
          children: [
            _Capped(
              maxWidth: _detailMaxWidth,
              child: _DetailHeader(
                job: checklist.job,
                jobId: widget.jobId,
                onBack: widget.onBack,
                trailing: widget.headerTrailing,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  wide ? 24 : 16,
                  8,
                  wide ? 24 : 16,
                  28,
                ),
                children: [
                  _Capped(
                    maxWidth: _detailMaxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.banner != null) ...[
                          widget.banner!,
                          const SizedBox(height: 12),
                        ],
                        _ProgressCard(
                          ordered: ordered,
                          currentCode: currentCode,
                          onJump: (item) =>
                              widget.onCategory(item.categoryCode),
                        ),
                        const SizedBox(height: 16),
                        _CategoryPills(
                          categories: categories,
                          checklist: checklist,
                          selected: category.code,
                          locale: locale,
                          onSelected: widget.onCategory,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              t(TechnicianKeys.technicianChecklistOrder),
                              style: queueEyebrow(context),
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
                          _ItemsCard(
                            items: items,
                            language: Localizations.localeOf(context)
                                .languageCode,
                            currentCode: currentCode,
                            readOnly: readOnly,
                            onOpen: (item) {
                              widget.onFocus(item);
                              widget.onOpen(item);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _DetailFooter(
              next: next,
              done: checklist.completed,
              total: checklist.total,
              readOnly: readOnly,
              onOpen: (item) {
                widget.onFocus(item);
                widget.onOpen(item);
              },
              onSummary: widget.onSummary,
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
          maxWidth: _detailMaxWidth,
          child: _DetailHeader(
            job: widget.checklist.job,
            jobId: widget.jobId,
            onBack: widget.onBack,
            trailing: widget.headerTrailing,
          ),
        ),
        if (widget.banner != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: widget.banner,
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

/// Readable measure for the detail step on every width.
const double _detailMaxWidth = 720;

/// Centres a band of the detail on the shared measure.
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

class _DetailHeader extends ConsumerWidget {
  const _DetailHeader({
    required this.job,
    required this.jobId,
    required this.onBack,
    this.trailing,
  });

  final JobSummary job;
  final String jobId;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final vehicle = queueVehicleLabel(job);
    final plate = (job.vehiclePlate ?? '').trim();
    final reference = job.reference.trim();
    final showReference =
        reference.isNotEmpty && plate.isNotEmpty && plate != reference;
    final time = queueSlotLabel(job);
    final pending = ref
        .watch(pendingOperationsProvider)
        .asData
        ?.value
        .where((op) => op.jobId == jobId && op.isPending);
    final online = ref.watch(connectivityProvider).value ?? true;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            child: GestureDetector(
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                ),
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
                  maxLines: 3,
                  style: queueText(
                    context,
                    28,
                    weight: FontWeight.w800,
                    height: 34,
                    tracking: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    QueuePlate(plate.isNotEmpty ? plate : reference),
                    if (showReference)
                      Text(
                        reference,
                        key: const Key('inspection-job-reference'),
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
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    QueueStatusChip(
                      label: jobStatusLabel(ref, job.status),
                      tone: jobStatusTone(ref, job.status),
                    ),
                    if (time.isNotEmpty) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      Text(
                        time,
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
                    if (pending != null && pending.isNotEmpty)
                      QueueStatusChip(
                        label: UiStrings.of(context)(
                          TechnicianKeys.technicianSyncPending,
                        ),
                        tone: StatusTone.warning,
                      )
                    else if (!online)
                      QueueStatusChip(
                        label: UiStrings.of(context)(
                          TechnicianKeys.technicianSyncOffline,
                        ),
                        tone: StatusTone.warning,
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

/// Progress as a tick strip: one tick per item in checklist order.
///
/// Answered ticks are ink, the current tick is tall, safety-critical items
/// carry a dot. Tapping a tick jumps to that item's category. Numbers ride
/// with their unit: "{done} of {total} items".
class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({
    required this.ordered,
    required this.currentCode,
    required this.onJump,
  });

  final List<ChecklistItem> ordered;
  final String? currentCode;
  final ValueChanged<ChecklistItem> onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final done = ordered
        .where((item) => item.assessment?.resultCode != null)
        .length;
    final total = ordered.length;
    final percent = total <= 0 ? 0 : ((done / total) * 100).round();
    final results = ref.watch(enumsProvider('result')).value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total > 0)
            Row(
              children: [
                for (var index = 0; index < ordered.length; index++)
                  _Tick(
                    item: ordered[index],
                    number: index + 1,
                    total: total,
                    current: ordered[index].itemCode == currentCode,
                    results: results,
                    onJump: onJump,
                  ),
              ],
            ),
          if (total > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  t(TechnicianKeys.technicianQueueItems, {
                    'done': done,
                    'total': total,
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
        ],
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({
    required this.item,
    required this.number,
    required this.total,
    required this.current,
    required this.results,
    required this.onJump,
  });

  final ChecklistItem item;
  final int number;
  final int total;
  final bool current;
  final List<ReferenceRecord>? results;
  final ValueChanged<ChecklistItem> onJump;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final answered = item.assessment?.resultCode != null;
    final state = answered
        ? resultLabel(results, item.assessment!.resultCode!)
        : t(TechnicianKeys.notChecked);
    final label =
        StringBuffer(
            t(TechnicianKeys.technicianSessionItemOf, {
              'number': number,
              'total': total,
            }),
          )
          ..write(' · ')
          ..write(state);
    if (item.safetyCritical) {
      label
        ..write(' · ')
        ..write(t(TechnicianKeys.technicianSafetyCritical));
    }
    final bar = answered || current
        ? context.brand.ink
        : colors.surfaceContainerHighest;
    return Expanded(
      child: Semantics(
        button: true,
        label: label.toString(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onJump(item),
          child: Container(
            height: 44,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: current ? 20 : 8,
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: item.safetyCritical
                        ? context.statusColors.danger.foreground
                        : Colors.transparent,
                    shape: BoxShape.circle,
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

/// The section switcher as wrapping pills: every served category with its own
/// "{done}/{total}". Nothing scrolls away clipped.
class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          Builder(
            builder: (context) {
              final items = checklist.itemsForCategory(category.code);
              final done = items
                  .where((item) => item.assessment?.resultCode != null)
                  .length;
              return QueueChip(
                label: '${category.nameFor(locale)} · $done/${items.length}',
                selected: category.code == selected,
                onPressed: () => onSelected(category.code),
              );
            },
          ),
      ],
    );
  }
}

/// One surface, every item of the section, hairline rows.
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.items,
    required this.language,
    required this.currentCode,
    required this.readOnly,
    required this.onOpen,
  });

  final List<ChecklistItem> items;
  final String language;
  final String? currentCode;
  final bool readOnly;
  final ValueChanged<ChecklistItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _ItemRow(
                item: items[index],
                language: language,
                current: items[index].itemCode == currentCode,
                tappable: !readOnly,
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

class _ItemRow extends ConsumerStatefulWidget {
  const _ItemRow({
    required this.item,
    required this.language,
    required this.current,
    required this.tappable,
    required this.onTap,
  });

  final ChecklistItem item;
  final String language;
  final bool current;
  final bool tappable;
  final VoidCallback onTap;

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;
    final result = item.assessment?.resultCode;
    final results = ref.watch(enumsProvider('result')).value;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final background = _hovered && widget.tappable
        ? colors.surfaceContainerLow
        : Colors.transparent;

    return Semantics(
      button: widget.tappable,
      label: item.labelFor(widget.language),
      child: FocusableActionDetector(
        enabled: widget.tappable,
        mouseCursor: widget.tappable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (widget.tappable) {
                widget.onTap();
              }
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: widget.tappable
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.tappable ? widget.onTap : null,
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 120),
              ),
              foregroundDecoration: _focused && widget.tappable
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
                    width: 28,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 3),
                      child: Text(
                        '${item.sortOrder}',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: queueText(
                          context,
                          13,
                          weight: FontWeight.w700,
                          height: 18,
                          tabular: true,
                          color: widget.current
                              ? context.brand.ink
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.labelFor(widget.language),
                          maxLines: 2,
                          style: queueText(
                            context,
                            16,
                            weight: FontWeight.w600,
                            height: 22,
                            tracking: -0.1,
                          ),
                        ),
                        if (result != null || item.safetyCritical) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (result != null)
                                QueueStatusChip(
                                  dense: true,
                                  label: resultLabel(results, result),
                                  tone: resultTone(results, result),
                                ),
                              if (item.safetyCritical)
                                QueueStatusChip(
                                  dense: true,
                                  label: UiStrings.of(context)(
                                    TechnicianKeys.technicianSafetyCritical,
                                  ),
                                  tone: StatusTone.danger,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.tappable) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: Icon(
                        rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pinned footer: ONE 56 px primary (Start / Continue / Finish from real
/// state, or Summary when read-only) plus a secondary Summary while work
/// remains. The old duplicate summary entry is gone.
class _DetailFooter extends StatelessWidget {
  const _DetailFooter({
    required this.next,
    required this.done,
    required this.total,
    required this.readOnly,
    required this.onOpen,
    required this.onSummary,
  });

  final ChecklistItem? next;
  final int done;
  final int total;
  final bool readOnly;
  final ValueChanged<ChecklistItem> onOpen;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final allAnswered = total > 0 && done >= total;
    final primaryLabel = readOnly
        ? t(TechnicianKeys.technicianDeckSummaryAction)
        : allAnswered
        ? t(TechnicianKeys.technicianQueueActionFinish)
        : done == 0
        ? t(TechnicianKeys.startInspection)
        : t(TechnicianKeys.technicianQueueActionContinue);
    final VoidCallback onPrimary = readOnly || allAnswered
        ? onSummary
        : () {
            final item = next;
            if (item == null) {
              onSummary();
            } else {
              onOpen(item);
            }
          };
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
      child: _Capped(
        maxWidth: _detailMaxWidth,
        child: Builder(
          builder: (context) {
            final showSummary = !readOnly && !allAnswered;
            // Side-by-side only while both labels fit; at large text scales the
            // pair stacks again rather than clipping either word.
            final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.2;
            final primary = DeckPrimaryButton(
              label: primaryLabel,
              onPressed: onPrimary,
            );
            if (!showSummary) {
              return primary;
            }
            if (stacked) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  primary,
                  const SizedBox(height: 8),
                  QueueButton(
                    label: t(TechnicianKeys.technicianDeckSummaryAction),
                    variant: QueueButtonVariant.soft,
                    expand: true,
                    onPressed: onSummary,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: primary),
                const SizedBox(width: 8),
                SizedBox(
                  width: 132,
                  child: QueueButton(
                    label: t(TechnicianKeys.technicianDeckSummaryAction),
                    variant: QueueButtonVariant.soft,
                    expand: true,
                    onPressed: onSummary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
