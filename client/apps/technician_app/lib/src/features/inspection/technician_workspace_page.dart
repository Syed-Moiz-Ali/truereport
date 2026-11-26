import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../inspection_models.dart';
import '../../reference_ui.dart';
import '../../technician_providers.dart';
import '../../ui_helpers.dart';
import '../jobs/queue/jobs_queue_format.dart';
import '../jobs/queue/queue_model.dart';
import 'clean_shared.dart';
import 'fieldwork/fieldwork_ui.dart';
import 'fieldwork/fieldwork_workspace.dart';
import 'vehicle_photo_gate.dart';

/// The inspection workspace in the Fieldwork language: the run sheet, the
/// current item and what follows. It never saves — the primary opens the
/// current item, and the item screen owns the verdict.
class TechnicianWorkspacePage extends ConsumerStatefulWidget {
  const TechnicianWorkspacePage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<TechnicianWorkspacePage> createState() =>
      _TechnicianWorkspacePageState();
}

class _TechnicianWorkspacePageState
    extends ConsumerState<TechnicianWorkspacePage> {
  String? _category;
  String? _focus;
  bool _continuedWithoutPhoto = false;
  bool _photoPromptOpen = false;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final checklistAsync = ref.watch(technicianChecklistProvider(widget.jobId));
    final photoAsync = ref.watch(vehiclePhotoProvider(widget.jobId));
    return checklistAsync.when(
      loading: () => AppScaffold(
        appBar: TechnicianAppBar(
          title: t(TechnicianKeys.technicianInspectionHub),
          showBack: true,
        ),
        body: const Padding(
          padding: EdgeInsetsDirectional.all(20),
          child: LoadingSkeleton(lines: 8),
        ),
      ),
      error: (error, _) => AppScaffold(
        appBar: TechnicianAppBar(
          title: t(TechnicianKeys.technicianInspectionHub),
          showBack: true,
        ),
        body: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: ErrorState(
            title: t(TechnicianKeys.error),
            body: t(TechnicianKeys.genericError),
            onRetry: () =>
                ref.invalidate(technicianChecklistProvider(widget.jobId)),
            retryLabel: t(TechnicianKeys.retryAction),
          ),
        ),
      ),
      data: (checklist) {
        final completed = checklist.completed > 0;
        return photoAsync.when(
          loading: () => completed
              ? _workspace(checklist, null, showBanner: false)
              : _photoLoading(context, t),
          // A photo-service failure never blocks the inspection; the banner
          // stays available so the technician can retry explicitly.
          error: (error, _) => _workspace(checklist, null, showBanner: true),
          data: (photo) {
            if (_photoPromptOpen) {
              return _gate(context, t);
            }
            if (photo == null) {
              if (!completed && !_continuedWithoutPhoto) {
                return _gate(context, t);
              }
              return _workspace(checklist, null, showBanner: true);
            }
            return _workspace(checklist, photo, showBanner: false);
          },
        );
      },
    );
  }

  Widget _gate(BuildContext context, UiStrings t) {
    return AppScaffold(
      appBar: TechnicianAppBar(
        title: t(TechnicianKeys.technicianInspectionHub),
        showBack: true,
      ),
      body: VehiclePhotoGate(
        jobId: widget.jobId,
        onDone: () => setState(() {
          _photoPromptOpen = false;
          _continuedWithoutPhoto = false;
        }),
        onContinueWithoutPhoto: () => setState(() {
          _photoPromptOpen = false;
          _continuedWithoutPhoto = true;
        }),
      ),
    );
  }

  Widget _photoLoading(BuildContext context, UiStrings t) {
    return AppScaffold(
      appBar: TechnicianAppBar(
        title: t(TechnicianKeys.technicianInspectionHub),
        showBack: true,
      ),
      body: const Padding(
        padding: EdgeInsetsDirectional.all(20),
        child: LoadingSkeleton(lines: 6),
      ),
    );
  }

  Widget _workspace(
    Checklist checklist,
    VehiclePhoto? photo, {
    required bool showBanner,
  }) {
    final t = UiStrings.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final job = checklist.job;
    final readOnly = verbFor(job) == QueueVerb.view;
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final ordered = _ordered(checklist);
    final results = ref.watch(enumsProvider('result')).value;
    final pending =
        ref
            .watch(pendingOperationsProvider)
            .asData
            ?.value
            .where((op) => op.jobId == widget.jobId && op.isPending)
            .isNotEmpty ??
        false;
    final online = ref.watch(connectivityProvider).value ?? true;

    final selected = _selectedCategory(categories, ordered);
    final sectionItems = selected == null
        ? const <ChecklistItem>[]
        : ([...checklist.itemsForCategory(selected.code)]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
    final current = _currentItem(ordered, sectionItems);
    final allAnswered =
        ordered.isNotEmpty &&
        ordered.every((item) => item.assessment?.resultCode != null);
    final sectionDone = sectionItems
        .where((item) => item.assessment?.resultCode != null)
        .length;

    final primaryLabel = readOnly
        ? t(TechnicianKeys.technicianDeckSummaryAction)
        : allAnswered
        ? t(TechnicianKeys.technicianQueueActionFinish)
        : checklist.completed > 0
        ? t(TechnicianKeys.technicianQueueActionContinue)
        : t(TechnicianKeys.startInspection);

    final syncLabel = pending
        ? t(TechnicianKeys.technicianSessionSyncPending)
        : !online
        ? t(TechnicianKeys.technicianSessionOffline)
        : null;

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: FieldworkWorkspace(
        copy: WorkspaceCopy(
          runSheetLabel: t(TechnicianKeys.technicianChecklistOrder),
          upNextLabel: t(TechnicianKeys.technicianSessionNext),
          upNextHeading: selected?.nameFor(language) ?? '',
          upNextSubheading: t(TechnicianKeys.technicianQueueItems, {
            'done': sectionDone,
            'total': sectionItems.length,
          }),
          upNextEmpty: allAnswered
              ? t(TechnicianKeys.technicianSessionAllAnswered, {
                  'total': checklist.total,
                })
              : t(TechnicianKeys.technicianNoItems),
          summaryLabel: t(TechnicianKeys.technicianDeckSummaryAction),
          openLabel: primaryLabel,
          allAnsweredTitle: t(TechnicianKeys.technicianSessionAllAnswered, {
            'total': checklist.total,
          }),
          allAnsweredBody: t(TechnicianKeys.technicianSummaryReadyBody),
          noCategoriesTitle: t(TechnicianKeys.technicianNoCategories),
          noCategoriesBody: t(TechnicianKeys.technicianNoItems),
          noItemsTitle: t(TechnicianKeys.technicianNoItems),
          noItemsBody: t(TechnicianKeys.technicianStartHint),
          noItemsHint: '',
          stepSemanticLabel: t(TechnicianKeys.technicianChecklistOrder),
          progressSemanticLabel: t(TechnicianKeys.technicianQueueItems, {
            'done': checklist.completed,
            'total': checklist.total,
          }),
          safetyLabel: t(TechnicianKeys.technicianSafetyCritical),
        ),
        header: WorkspaceHeader(
          title: t(TechnicianKeys.technicianInspectionHub),
          reference: job.reference,
          vehicle: queueVehicleLabel(job),
          plate: (job.vehiclePlate ?? '').trim(),
          statusLabel: jobStatusLabel(ref, job.status),
          statusTone: jobStatusTone(ref, job.status),
          slotLabel: queueSlotLabel(job),
          done: checklist.completed,
          total: checklist.total,
          syncLabel: syncLabel,
          syncTone: StatusTone.warning,
          syncIcon: pending
              ? Icons.sync_problem_rounded
              : Icons.cloud_off_rounded,
        ),
        stations: [
          for (final category in categories)
            _station(checklist, category, language),
        ],
        ticks: [
          for (var index = 0; index < ordered.length; index++)
            _tick(ordered[index], index, ordered.length, current, results, t),
        ],
        tickSemanticLabel: t(TechnicianKeys.technicianQueueItems, {
          'done': checklist.completed,
          'total': checklist.total,
        }),
        focus: allAnswered || current == null
            ? null
            : _focusData(current, checklist, selected, language, results, t),
        upNext: allAnswered
            ? const <WorkspaceNext>[]
            : _upNext(ordered, current, results, t, language),
        sectionItems: [
          for (final item in sectionItems)
            _sectionItem(item, current, results, t, language),
        ],
        selectedStationCode: selected?.code,
        sectionEmpty: !allAnswered && selected != null && sectionItems.isEmpty,
        readOnly: readOnly,
        banner: showBanner
            ? VehiclePhotoBanner(
                onAdd: () => setState(() => _photoPromptOpen = true),
              )
            : null,
        headerTrailing: photo == null
            ? null
            : VehiclePhotoThumb(jobId: widget.jobId, onRetake: _retakePhoto),
        onBack: () => Navigator.of(context).maybePop(),
        onStation: (code) => setState(() {
          _category = code;
          _focus = null;
        }),
        onTick: (code) => setState(() {
          _category = code;
          _focus = null;
        }),
        onOpenCurrent: () {
          if (current == null) {
            _openSummary();
            return;
          }
          _open(current);
        },
        onOpenItem: (next) {
          for (final item in ordered) {
            if (item.itemCode == next.itemCode) {
              _open(item);
              return;
            }
          }
        },
        onOpenSectionItem: (row) {
          for (final item in sectionItems) {
            if (item.itemCode == row.itemCode) {
              _open(item);
              return;
            }
          }
        },
        onSummary: _openSummary,
      ),
    );
  }

  List<ChecklistItem> _ordered(Checklist checklist) {
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return <ChecklistItem>[
      for (final category in categories)
        ...[...checklist.itemsForCategory(category.code)]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    ];
  }

  Category? _selectedCategory(
    List<Category> categories,
    List<ChecklistItem> ordered,
  ) {
    if (categories.isEmpty) {
      return null;
    }
    final explicit = _category;
    if (explicit != null) {
      for (final category in categories) {
        if (category.code == explicit) {
          return category;
        }
      }
    }
    // Resume at the section holding the first unanswered item.
    for (final item in ordered) {
      if (item.assessment?.resultCode == null) {
        for (final category in categories) {
          if (category.code == item.categoryCode) {
            return category;
          }
        }
      }
    }
    return categories.first;
  }

  ChecklistItem? _currentItem(
    List<ChecklistItem> ordered,
    List<ChecklistItem> sectionItems,
  ) {
    if (ordered.isEmpty) {
      return null;
    }
    final focus = _focus;
    if (focus != null) {
      for (final item in ordered) {
        if (item.itemCode == focus) {
          return item;
        }
      }
    }
    for (final item in sectionItems) {
      if (item.assessment?.resultCode == null) {
        return item;
      }
    }
    return sectionItems.isEmpty ? null : sectionItems.first;
  }

  WorkspaceStation _station(
    Checklist checklist,
    Category category,
    String language,
  ) {
    final items = checklist.itemsForCategory(category.code).toList();
    final done = items
        .where((item) => item.assessment?.resultCode != null)
        .length;
    return WorkspaceStation(
      code: category.code,
      label: category.nameFor(language),
      icon: categoryIconFor(category.iconCode),
      done: done,
      total: items.length,
    );
  }

  WorkspaceSectionItem _sectionItem(
    ChecklistItem item,
    ChecklistItem? current,
    List<ReferenceRecord>? results,
    UiStrings t,
    String language,
  ) {
    final code = item.assessment?.resultCode;
    return WorkspaceSectionItem(
      itemCode: item.itemCode,
      number: item.sortOrder,
      label: item.labelFor(language),
      statusLabel: code == null
          ? t(TechnicianKeys.notChecked)
          : resultLabel(results, code),
      statusTone: code == null ? StatusTone.neutral : resultTone(results, code),
      safety: item.safetyCritical,
      current: current?.itemCode == item.itemCode,
    );
  }

  FieldworkTick _tick(
    ChecklistItem item,
    int index,
    int total,
    ChecklistItem? current,
    List<ReferenceRecord>? results,
    UiStrings t,
  ) {
    final answered = item.assessment?.resultCode != null;
    final state = answered
        ? resultLabel(results, item.assessment!.resultCode!)
        : t(TechnicianKeys.notChecked);
    final buffer =
        StringBuffer(
            t(TechnicianKeys.technicianSessionItemOf, {
              'number': item.sortOrder,
              'total': total,
            }),
          )
          ..write(' · ')
          ..write(state);
    if (item.safetyCritical) {
      buffer
        ..write(' · ')
        ..write(t(TechnicianKeys.technicianSafetyCritical));
    }
    return FieldworkTick(
      label: buffer.toString(),
      categoryCode: item.categoryCode,
      answered: answered,
      current: current?.itemCode == item.itemCode,
      safety: item.safetyCritical,
    );
  }

  WorkspaceFocus _focusData(
    ChecklistItem item,
    Checklist checklist,
    Category? category,
    String language,
    List<ReferenceRecord>? results,
    UiStrings t,
  ) {
    final requirement = EvidenceRequirement.forResult(
      item,
      item.assessment?.resultCode,
    );
    final requiredFields = item.issueFields
        .where((field) => field.required)
        .length;
    final resultCode = item.assessment?.resultCode;
    return WorkspaceFocus(
      number: item.sortOrder,
      total: checklist.total,
      categoryLabel: category?.nameFor(language) ?? item.categoryCode,
      label: item.labelFor(language),
      instruction: item.instructionFor(language) ?? '',
      spec: item.standardSpecFor(language) ?? '',
      safety: item.safetyCritical,
      safetyLabel: t(TechnicianKeys.technicianSafetyCritical),
      resultLabel: resultCode == null ? null : resultLabel(results, resultCode),
      resultTone: resultTone(results, resultCode),
      facts: [
        if (item.measurementBands.isNotEmpty || item.measurementUnit != null)
          FieldworkFact(
            label: t(TechnicianKeys.technicianMeasurement),
            icon: Icons.straighten_rounded,
          ),
        if (requiredFields > 0)
          FieldworkFact(
            label: t(TechnicianKeys.technicianRequiredCount, {
              'count': requiredFields,
            }),
            icon: Icons.tune_rounded,
            tone: StatusTone.warning,
          ),
        if (item.allowFreeTextNote && requirement.minNotesChars > 0)
          FieldworkFact(
            label: t(TechnicianKeys.technicianNotes),
            icon: Icons.notes_rounded,
          ),
      ],
    );
  }

  List<WorkspaceNext> _upNext(
    List<ChecklistItem> ordered,
    ChecklistItem? current,
    List<ReferenceRecord>? results,
    UiStrings t,
    String language,
  ) {
    final list = <WorkspaceNext>[];
    final start = current == null
        ? 0
        : ordered.indexWhere((item) => item.itemCode == current.itemCode) + 1;
    for (var index = start; index < ordered.length; index++) {
      final item = ordered[index];
      if (item.assessment?.resultCode != null) {
        continue;
      }
      list.add(
        WorkspaceNext(
          itemCode: item.itemCode,
          number: item.sortOrder,
          label: item.labelFor(language),
          metaLabel: item.safetyCritical
              ? t(TechnicianKeys.technicianSafetyCritical)
              : t(TechnicianKeys.notChecked),
          safety: item.safetyCritical,
        ),
      );
      if (list.length == 6) {
        break;
      }
    }
    return list;
  }

  void _openSummary() {
    context.push('/jobs/${widget.jobId}/summary');
  }

  Future<void> _retakePhoto() async {
    try {
      await ref.read(technicianApiProvider).deleteVehiclePhoto(widget.jobId);
    } on Object {
      // A failed delete must not trap the technician; the new init replaces the
      // old photo on the server anyway.
    }
    ref.invalidate(vehiclePhotoProvider(widget.jobId));
    ref.invalidate(vehiclePhotoContentProvider(widget.jobId));
    if (!mounted) return;
    setState(() => _photoPromptOpen = true);
  }

  Future<void> _open(ChecklistItem item) async {
    await context.push(
      '/jobs/${widget.jobId}/items/${Uri.encodeComponent(item.itemCode)}',
    );
    if (mounted) {
      setState(() => _focus = null);
    }
  }
}
