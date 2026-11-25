import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import '../../inspection_models.dart';
import '../../reference_ui.dart';
import '../../technician_providers.dart';
import 'deck/deck_footer.dart';
import 'deck/deck_header.dart';
import 'deck/deck_ledger.dart';
import 'deck/deck_sections.dart';

/// The vehicle workspace as a section ledger: the whole job's sections as
/// chips, the selected section in checklist order, and one footer action that
/// always names the real next step.
///
/// The assessment itself still opens on the item route. This surface answers
/// "what is left in this job and what do I do next", not "how do I assess this
/// one item".
class InspectionDeck extends ConsumerWidget {
  const InspectionDeck({
    required this.checklist,
    required this.jobId,
    required this.onCategory,
    required this.onFocus,
    required this.onOpen,
    required this.onSummary,
    required this.onBack,
    this.selectedCategory,
    this.focusedItemCode,
    this.banner,
    this.headerTrailing,
    super.key,
  });

  final Checklist checklist;

  /// Kept for call-site compatibility; item navigation stays with the
  /// workspace page, which already knows the job id.
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
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final statusLabel = jobStatusLabel(ref, checklist.job.status);
    final statusTone = jobStatusTone(ref, checklist.job.status);
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    final pendingSync = sync?.total ?? 0;
    final syncHasConflict = sync?.hasConflicts ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (categories.isEmpty) {
          return _chrome(
            context,
            t,
            wide: wide,
            statusLabel: statusLabel,
            statusTone: statusTone,
            pendingSync: pendingSync,
            syncHasConflict: syncHasConflict,
          );
        }

        final code = selectedCategory ?? categories.first.code;
        final category = categories.firstWhere(
          (value) => value.code == code,
          orElse: () => categories.first,
        );
        final items = [...checklist.itemsForCategory(category.code)]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final answered = items.where(_isAnswered).length;
        final sectionNext = _firstUnanswered(items);
        final allAssessed =
            checklist.items.isNotEmpty && checklist.items.every(_isAnswered);
        // A submitted job is read-only server-side (JOB_NOT_EDITABLE). Keep the
        // ledger open for reading, but never offer "Finish job" or an edit path.
        final status = checklist.job.status.toUpperCase();
        final editable =
            status == 'ASSIGNED' ||
            status == 'SCHEDULED' ||
            status == 'IN_PROGRESS' ||
            status == 'DRAFT' ||
            status.isEmpty;
        // When the section is finished, the action continues the job in the
        // next section instead of pretending the section is the whole job.
        final target = sectionNext ?? _firstUnanswered(checklist.items);

        final String primaryLabel;
        final IconData primaryIcon;
        final VoidCallback primaryAction;
        String? nextItem;
        if (!editable) {
          primaryLabel = t(TechnicianKeys.technicianDeckSummaryAction);
          primaryIcon = Icons.fact_check_outlined;
          primaryAction = onSummary;
        } else if (allAssessed) {
          primaryLabel = t(TechnicianKeys.technicianDeckFinishJob);
          primaryIcon = Icons.fact_check_outlined;
          primaryAction = onSummary;
        } else if (target != null) {
          // The verb is short; the item name lives on the footer's eyebrow line
          // so a long checklist sentence cannot truncate the action at 390 px.
          final continuing = answered > 0 || sectionNext == null;
          primaryLabel = continuing
              ? t(TechnicianKeys.technicianQueueActionContinue)
              : t(TechnicianKeys.technicianDeckCheckAction);
          nextItem = target.labelFor(language);
          primaryIcon = Icons.arrow_forward_rounded;
          primaryAction = () {
            onFocus(target);
            onOpen(target);
          };
        } else {
          // No assessable item exists (for example a job with no template
          // items); the summary remains the only safe destination.
          primaryLabel = t(TechnicianKeys.technicianContinueChecklist);
          primaryIcon = Icons.fact_check_outlined;
          primaryAction = onSummary;
        }

        final horizontal = wide ? 24.0 : 16.0;
        return Column(
          children: [
            DeckHeader(
              checklist: checklist,
              onBack: onBack,
              statusLabel: statusLabel,
              statusTone: statusTone,
              pendingSync: pendingSync,
              syncHasConflict: syncHasConflict,
              trailing: headerTrailing,
              wide: wide,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  horizontal,
                  0,
                  horizontal,
                  24,
                ),
                children: [
                  DeckCapped(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (banner != null) ...[
                          banner!,
                          const SizedBox(height: 12),
                        ],
                        DeckSections(
                          categories: categories,
                          checklist: checklist,
                          selected: category.code,
                          locale: locale,
                          onSelected: onCategory,
                        ),
                        const SizedBox(height: 12),
                        DeckLedger(
                          items: items,
                          language: language,
                          nextItemCode: sectionNext?.itemCode,
                          focusedItemCode: focusedItemCode,
                          wide: wide,
                          allAssessed: allAssessed,
                          onOpen: (item) {
                            onFocus(item);
                            onOpen(item);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DeckFooter(
              primaryLabel: primaryLabel,
              primaryIcon: primaryIcon,
              onPrimary: primaryAction,
              onSummary: onSummary,
              nextItem: nextItem,
            ),
          ],
        );
      },
    );
  }

  Widget _chrome(
    BuildContext context,
    UiStrings t, {
    required bool wide,
    required String statusLabel,
    required StatusTone statusTone,
    required int pendingSync,
    required bool syncHasConflict,
  }) {
    return Column(
      children: [
        DeckHeader(
          checklist: checklist,
          onBack: onBack,
          statusLabel: statusLabel,
          statusTone: statusTone,
          pendingSync: pendingSync,
          syncHasConflict: syncHasConflict,
          trailing: headerTrailing,
          wide: wide,
        ),
        if (banner != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: banner,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: DeckCapped(
              child: EmptyState(
                title: t(TechnicianKeys.technicianNoCategories),
                body: t(TechnicianKeys.technicianNoItems),
                icon: Icons.checklist_rounded,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

bool _isAnswered(ChecklistItem item) =>
    (item.assessment?.resultCode ?? '').trim().isNotEmpty;

ChecklistItem? _firstUnanswered(Iterable<ChecklistItem> items) {
  for (final item in items) {
    if (!_isAnswered(item)) {
      return item;
    }
  }
  return null;
}
