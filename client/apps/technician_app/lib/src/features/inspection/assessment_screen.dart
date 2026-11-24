import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_sheet.dart';
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/features/inspection/option_labels.dart';
import 'package:technician_app/src/features/inspection/photo_markup_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';
import 'package:uuid/uuid.dart';

/// One checklist item, built as "Verdict first": the item, its result, the
/// evidence a result needs, and one pinned action that moves to the next item.
///
/// The assessment logic (validity, offline queue, evidence requirement, score
/// bands, issue fields) is unchanged from the previous screen; the presentation
/// is this file's own.
class TechnicianItemPage extends ConsumerWidget {
  const TechnicianItemPage({
    required this.jobId,
    required this.itemCode,
    super.key,
  });

  final String jobId;
  final String itemCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final checklistAsync = ref.watch(technicianChecklistProvider(jobId));
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: checklistAsync.when(
        loading: () => const _ScreenShell(child: LoadingSkeleton(lines: 8)),
        error: (error, _) => _ScreenShell(
          child: ErrorState(
            title: t(TechnicianKeys.error),
            body: t(TechnicianKeys.technicianItemLoadFailed),
            retryLabel: t(TechnicianKeys.retryAction),
            onRetry: () => ref.invalidate(technicianChecklistProvider(jobId)),
          ),
        ),
        data: (checklist) {
          final item = checklist.item(itemCode);
          if (item == null) {
            return _ScreenShell(
              child: EmptyState(
                title: t(TechnicianKeys.technicianItemNotFoundTitle),
                body: t(TechnicianKeys.technicianItemNotFound),
                icon: Icons.search_off_rounded,
              ),
            );
          }
          return Column(
            children: [
              _ScreenBar(checklist: checklist, item: item),
              Expanded(
                child: _AssessmentForm(
                  key: ValueKey(
                    '$jobId-${item.itemCode}-${item.assessment?.version ?? 0}',
                  ),
                  jobId: jobId,
                  item: item,
                  eyebrow: _eyebrow(
                    checklist,
                    item,
                    Localizations.localeOf(context).languageCode,
                  ),
                  nextItemCode: _nextItem(checklist, item)?.itemCode,
                  nextItemLabel: _nextItem(
                    checklist,
                    item,
                  )?.labelFor(Localizations.localeOf(context).languageCode),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "EXTERIOR · 02 / 07" — where this item sits, the same numbering the
  /// section ledger uses.
  String _eyebrow(Checklist checklist, ChecklistItem item, String language) {
    final category = checklist.categories.firstWhere(
      (value) => value.code == item.categoryCode,
      orElse: () => Category(
        code: item.categoryCode,
        nameEn: item.categoryCode,
        nameAr: item.categoryCode,
        iconCode: null,
        sortOrder: 0,
      ),
    );
    final items = [...checklist.itemsForCategory(item.categoryCode)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = items.indexWhere((value) => value.itemCode == item.itemCode);
    return '${category.nameFor(language).toUpperCase()} · '
        '${'${index + 1}'.padLeft(2, '0')} / '
        '${'${items.length}'.padLeft(2, '0')}';
  }

  /// The next stop after this item: the next unanswered item in the same
  /// section, then the next unanswered item anywhere in the job.
  ChecklistItem? _nextItem(Checklist checklist, ChecklistItem current) {
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final ordered = <ChecklistItem>[
      for (final category in categories)
        ...[...checklist.itemsForCategory(category.code)]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    ];
    if (ordered.isEmpty) {
      return null;
    }
    final start = ordered.indexWhere(
      (value) => value.itemCode == current.itemCode,
    );
    final from = start < 0 ? -1 : start;
    for (var step = 1; step <= ordered.length; step++) {
      final candidate = ordered[(from + step) % ordered.length];
      if (candidate.itemCode == current.itemCode) {
        break;
      }
      if (candidate.assessment?.resultCode == null) {
        return candidate;
      }
    }
    return null;
  }
}

/// The shared frame for loading, error and not-found states.
class _ScreenShell extends StatelessWidget {
  const _ScreenShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: child,
        ),
      ),
    );
  }
}

/// Vehicle context and the job's progress, on the same measure as the body.
class _ScreenBar extends StatelessWidget {
  const _ScreenBar({required this.checklist, required this.item});

  final Checklist checklist;
  final ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final job = checklist.job;
    final language = Localizations.localeOf(context).languageCode;
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
      if (job.vehicleYear != null) '${job.vehicleYear}',
    ].where((value) => value.isNotEmpty).join(' ');
    final plate = (job.vehiclePlate ?? '').trim();
    final reference = job.reference.trim();
    final showReference =
        reference.isNotEmpty && plate.isNotEmpty && plate != reference;
    final sectionItems = checklist.itemsForCategory(item.categoryCode);
    final sectionDone = sectionItems
        .where((value) => value.assessment?.resultCode != null)
        .length;
    final category = checklist.categories.firstWhere(
      (value) => value.code == item.categoryCode,
      orElse: () => Category(
        code: item.categoryCode,
        nameEn: item.categoryCode,
        nameAr: item.categoryCode,
        iconCode: null,
        sortOrder: 0,
      ),
    );
    final fraction = checklist.total <= 0
        ? 0.0
        : (checklist.completed / checklist.total).clamp(0.0, 1.0);

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back_rounded, size: 21),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vehicle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _Plate(plate.isNotEmpty ? plate : reference),
                            if (showReference) ...[
                              const SizedBox(width: 8),
                              Text(
                                reference,
                                key: const Key('inspection-item-reference'),
                                maxLines: 1,
                                style: context.texts.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      '${checklist.completed}/${checklist.total}',
                      style: context.texts.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 5,
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
              const SizedBox(height: 5),
              Text(
                '$sectionDone of ${sectionItems.length} in '
                '${category.nameFor(language)} · '
                '${t(TechnicianKeys.technicianItemsAssessed, {'done': checklist.completed, 'total': checklist.total})}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
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
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: context.brand.ink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: context.texts.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentForm extends ConsumerStatefulWidget {
  const _AssessmentForm({
    required this.jobId,
    required this.item,
    required this.eyebrow,
    this.nextItemCode,
    this.nextItemLabel,
    super.key,
  });

  final String jobId;
  final ChecklistItem item;
  final String eyebrow;
  final String? nextItemCode;
  final String? nextItemLabel;

  @override
  ConsumerState<_AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends ConsumerState<_AssessmentForm> {
  final _score = TextEditingController();
  final _notesEn = TextEditingController();
  final _notesAr = TextEditingController();
  final Map<String?, TextEditingController> _measurements = {};
  final Map<String, Map<String?, String>> _optionValues = {};
  final Map<String, Map<String?, Set<String>>> _multiValues = {};
  final Map<String, Map<String?, TextEditingController>> _fieldControllers = {};
  final _service = EvidenceCaptureService();
  late final EvidenceUploadQueue _queue;
  Map<String, ApiFieldError> _fieldErrors = {};
  String? _result;
  String? _error;

  /// Null until the technician opens or closes the folded details; the first
  /// build decides from how many folded fields the item actually requires.
  bool? _detailsOpen;
  String? _evidenceError;
  bool _resultManuallyChosen = false;
  bool _scoreManuallyEdited = false;
  bool _saving = false;
  bool _saved = false;
  bool _showValidation = false;
  ChecklistItem get item => widget.item;
  String get jobId => widget.jobId;
  List<String?> get _measurementIndexes =>
      item.multiPoint ? item.multiPointIndexes.cast<String?>() : [null];
  @override
  void initState() {
    super.initState();
    _queue = EvidenceUploadQueue(
      api: ref.read(technicianApiProvider),
      store: ref.read(offlineStoreProvider),
      jobId: widget.jobId,
      itemCode: widget.item.itemCode,
      deviceId: DeviceIdentity.deviceId,
    )..state.addListener(_onQueueChanged);
    _result = item.assessment?.resultCode;
    _score.text = item.assessment?.score?.toString() ?? '';
    _notesEn.text = item.assessment?.notesEn ?? '';
    _notesAr.text = item.assessment?.notesAr ?? '';
    for (final index in _measurementIndexes) {
      final controller = TextEditingController();
      final value = _assessmentMeasurement(index);
      if (value != null) {
        controller.text = _formatNumber(value);
      }
      controller.addListener(_handleMeasurementChanged);
      _measurements[index] = controller;
    }
    for (final value in item.assessment?.issueValues ?? const <IssueValue>[]) {
      final field = item.field(value.fieldCode);
      if (field == null || value.fieldCode == 'MEASUREMENT') {
        continue;
      }
      if (value.optionValueCode != null) {
        if (_isMulti(field)) {
          _multiValues
              .putIfAbsent(field.fieldCode, () => {})
              .putIfAbsent(value.valueIndex, () => <String>{})
              .add(value.optionValueCode!);
        } else {
          _optionValues.putIfAbsent(
            field.fieldCode,
            () => {},
          )[value.valueIndex] = value.optionValueCode!;
        }
      }
      if (value.numericValue != null || value.textValue != null) {
        final controller = _controller(field, value.valueIndex);
        controller.text = value.numericValue != null
            ? _formatNumber(value.numericValue!)
            : value.textValue ?? '';
      }
    }
    _recomputeSuggestion(applyResult: _result == null, notify: false);
  }

  void _onQueueChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _queue.state.removeListener(_onQueueChanged);
    _queue.dispose();
    _score.dispose();
    _notesEn.dispose();
    _notesAr.dispose();
    for (final controller in _measurements.values) {
      controller.dispose();
    }
    for (final map in _fieldControllers.values) {
      for (final controller in map.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  double? _assessmentMeasurement(String? index) {
    for (final measurement in item.assessment?.measurements ?? const []) {
      if (measurement.fieldCode == 'MEASUREMENT' &&
          measurement.valueIndex == index) {
        return measurement.numericValue;
      }
    }
    return null;
  }

  String _formatNumber(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
  double? _measurementFor(String? index) {
    final text = _measurements[index]?.text.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text.replaceAll(',', '.'));
  }

  void _handleMeasurementChanged() {
    _recomputeSuggestion(applyResult: !_resultManuallyChosen);
  }

  void _recomputeSuggestion({required bool applyResult, bool notify = true}) {
    final values = _measurementIndexes
        .map(_measurementFor)
        .whereType<double>()
        .toList(growable: false);
    final band = worstBandForValues(item, values);
    _suggestedResult = band?.resultCode;
    _suggestedScore = band?.defaultScore;
    if (applyResult && band != null) {
      _result = band.resultCode;
    }
    if (!_scoreManuallyEdited && band != null) {
      final score =
          scoreBandForResult(item, band.resultCode)?.defaultScore ??
          band.defaultScore;
      _score.text = '$score';
    }
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _selectResult(String code) {
    setState(() {
      _result = code;
      _resultManuallyChosen = true;
      _scoreManuallyEdited = false;
      final band = scoreBandForResult(item, code);
      if (band != null) {
        _score.text = '${band.defaultScore}';
      }
      // A result can make folded fields required (for example severity on an
      // attention finding). Never hide a field the technician now owes.
      if (_requiredDetailCount() > 0) {
        _detailsOpen = true;
      }
    });
  }

  bool _isMulti(IssueField field) =>
      field.inputType == 'MULTI_SELECT' ||
      field.allowMultiple ||
      field.options.length > 1 && field.inputType == 'MULTI_SELECT';
  bool _isIndexed(IssueField field) =>
      item.multiPoint &&
      (_isMulti(field) ||
          field.inputType == 'NUMBER' ||
          field.inputType == 'MULTI_SELECT' ||
          field.fieldCode == 'LOCATION');
  List<String?> _indexesFor(IssueField field) =>
      _isIndexed(field) ? item.multiPointIndexes.cast<String?>() : [null];
  List<IssueOption> _optionsFor(IssueField field) {
    final options = field.options
        .where((option) => field.isAllowed(option.code))
        .toList(growable: false);
    if (field.inputType == 'BOOLEAN' && options.isEmpty) {
      return const [
        IssueOption(code: 'YES', labelEn: '', labelAr: '', sortOrder: 0),
        IssueOption(code: 'NO', labelEn: '', labelAr: '', sortOrder: 1),
      ];
    }
    return options;
  }

  String _booleanLabel(UiStrings t, String code) =>
      code == 'YES' ? t(TechnicianKeys.commonYes) : t(TechnicianKeys.commonNo);
  bool _dependencySatisfied(IssueField field, String? index) {
    final parentCode = field.dependsOnFieldCode;
    if (parentCode == null || parentCode.isEmpty) {
      return true;
    }
    final parent = item.field(parentCode);
    if (parent == null) {
      return true;
    }
    final parentIndex = _isIndexed(parent) ? index : null;
    if (_isMulti(parent)) {
      return _multiValues[parentCode]?[parentIndex]?.contains(
            field.dependsOnValueCode,
          ) ??
          false;
    }
    return _optionValues[parentCode]?[parentIndex] == field.dependsOnValueCode;
  }

  bool _requiredFor(IssueField field) => field.requiredForStatuses.isEmpty
      ? field.required
      : field.requiredForStatuses.contains(_result);
  bool _isMissing(IssueField field, String? index) {
    if (!_requiredFor(field)) {
      return false;
    }
    if (_isMulti(field)) {
      return _multiValues[field.fieldCode]?[index]?.isEmpty ?? true;
    }
    switch (field.inputType) {
      case 'NUMBER':
        return (_fieldControllers[field.fieldCode]?[index]?.text.trim() ?? '')
            .isEmpty;
      case 'TEXT':
        return (_fieldControllers[field.fieldCode]?[index]?.text.trim() ?? '')
            .isEmpty;
      case 'BOOLEAN':
      case 'SELECT':
      case 'MULTI_SELECT':
        return (_optionValues[field.fieldCode]?[index] ?? '').isEmpty;
      default:
        return false;
    }
  }

  bool get _measurementRequired => item.measurementBands.isNotEmpty;
  bool get _measurementsComplete =>
      !_measurementRequired ||
      _measurementIndexes.every((index) => _measurementFor(index) != null);
  ScoreBand? get _selectedScoreBand => scoreBandForResult(item, _result);
  int? get _scoreValue => int.tryParse(_score.text.trim());
  bool get _scoreValid {
    final band = _selectedScoreBand;
    final value = _scoreValue;
    if (band == null || value == null) {
      return true;
    }
    return value >= band.minScore && value <= band.maxScore;
  }

  EvidenceRequirement get _evidenceRequirement =>
      EvidenceRequirement.forResult(item, _result);
  bool _evidenceSatisfied(List<Evidence> evidence) {
    final requirement = _evidenceRequirement;
    final photos = evidence.where((e) => e.isPhoto).length;
    final videos = evidence.where((e) => e.isVideo).length;
    final documents = evidence.where((e) => e.isDocument).length;
    return photos >= requirement.minPhotos &&
        videos >= requirement.minVideos &&
        (!requirement.requiresDocument || documents > 0);
  }

  ({String label, StatusTone tone, IconData icon}) _evidenceStage(
    UiStrings t,
    EvidenceUploadState upload,
    bool evidenceOk,
  ) {
    return switch (upload.stage) {
      EvidenceUploadStage.capturing => (
        label: t(TechnicianKeys.technicianEvidenceStateCapturing),
        tone: StatusTone.info,
        icon: Icons.photo_camera_outlined,
      ),
      EvidenceUploadStage.uploading => (
        label: t(TechnicianKeys.technicianEvidenceStateUploading),
        tone: StatusTone.info,
        icon: Icons.cloud_upload_outlined,
      ),
      EvidenceUploadStage.queued => (
        label: t(TechnicianKeys.technicianEvidenceStateQueued),
        tone: StatusTone.warning,
        icon: Icons.cloud_off_outlined,
      ),
      EvidenceUploadStage.failed => (
        label: t(TechnicianKeys.technicianEvidenceStateFailed),
        tone: StatusTone.danger,
        icon: Icons.error_outline,
      ),
      EvidenceUploadStage.cancelled => (
        label: t(TechnicianKeys.technicianEvidenceCancelled),
        tone: StatusTone.neutral,
        icon: Icons.cancel_outlined,
      ),
      EvidenceUploadStage.complete || EvidenceUploadStage.idle =>
        evidenceOk
            ? (
                label: t(TechnicianKeys.technicianEvidenceStateComplete),
                tone: StatusTone.success,
                icon: Icons.check_circle_outline,
              )
            : (
                label: t(TechnicianKeys.technicianEvidenceStateRequired),
                tone: StatusTone.warning,
                icon: Icons.pending_outlined,
              ),
    };
  }

  Future<void> _flushQueuedEvidence() async {
    if (_queue.isBusy) {
      return;
    }
    final report = await ref.read(syncServiceProvider).syncAll();
    ref.invalidate(syncQueueStatusProvider);
    if (!mounted) {
      return;
    }
    if (report.synced > 0 || report.conflicts > 0) {
      _invalidateEvidence();
      showAppSnackBar(
        context,
        message: report.conflicts > 0
            ? UiStrings.of(context)(
                TechnicianKeys.technicianSyncConflictsCount,
                {'count': report.conflicts},
              )
            : UiStrings.of(context)(TechnicianKeys.technicianSyncApplied, {
                'count': report.synced,
              }),
      );
    }
  }

  bool _formValid(List<Evidence> evidence) {
    if (_result == null || _result!.isEmpty) {
      return false;
    }
    if (!_measurementsComplete || !_scoreValid) {
      return false;
    }
    if (!_evidenceSatisfied(evidence)) {
      return false;
    }
    for (final field in item.issueFields) {
      if (field.fieldCode == 'MEASUREMENT' ||
          (field.inputType == 'TEXT' && !field.allowFreeText)) {
        continue;
      }
      for (final index in _indexesFor(field)) {
        if (!_dependencySatisfied(field, index)) {
          continue;
        }
        if (_isMissing(field, index)) {
          return false;
        }
      }
    }
    return true;
  }

  TextEditingController _controller(IssueField field, String? index) {
    return _fieldControllers
        .putIfAbsent(field.fieldCode, () => {})
        .putIfAbsent(index, () => TextEditingController());
  }

  Future<void> _save(List<Evidence> evidence, {bool advance = false}) async {
    final t = UiStrings.of(context);
    setState(() {
      _showValidation = true;
      _error = null;
      _fieldErrors = {};
    });
    if (!_formValid(evidence)) {
      setState(() => _error = t(TechnicianKeys.technicianIssueFieldRequired));
      return;
    }
    final request = AssessmentRequest(
      baseVersion: item.assessment?.version ?? 0,
      clientRevision: DateTime.now().millisecondsSinceEpoch,
      resultCode: _result!,
      score: _scoreValue,
      severityCode: _severityCode(),
      notesEn: item.allowFreeTextNote ? _notesEn.text.trim() : null,
      notesAr: item.allowFreeTextNote ? _notesAr.text.trim() : null,
      issueValues: _issueValues(),
      measurements: _measurementsPayload(),
    );
    setState(() => _saving = true);
    try {
      await ref
          .read(technicianApiProvider)
          .saveAssessment(
            jobId,
            item.itemCode,
            request,
            idempotencyKey: const Uuid().v7(),
          );
      ref.invalidate(technicianChecklistProvider(jobId));
      ref.invalidate(technicianSummaryProvider(jobId));
      ref.invalidate(technicianJobSummaryProvider(jobId));
      ref.invalidate(technicianJobPageProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saved = true;
      });
      showAppSnackBar(context, message: t(TechnicianKeys.technicianItemSaved));
      if (advance) {
        _advanceToNext();
      }
    } on Object catch (failure) {
      if (!mounted) {
        return;
      }
      if (isNetworkFailure(failure)) {
        await _queueOffline(request);
        if (!mounted) {
          return;
        }
        setState(() {
          _saving = false;
          _saved = true;
        });
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianOfflineQueued),
        );
        if (advance) {
          _advanceToNext();
        }
      } else {
        final fields = fieldErrorsByCode(failure);
        final lang = Localizations.localeOf(context).languageCode;
        final messages = fields.values
            .map((error) => error.messageFor(lang))
            .where((message) => message.isNotEmpty)
            .toList(growable: false);
        setState(() {
          _saving = false;
          _fieldErrors = fields;
          _error = messages.isEmpty
              ? t(TechnicianKeys.commonActionFailed)
              : messages.join('\n');
        });
      }
    }
  }

  /// Moves to the next unanswered item, or leaves the item when this was the
  /// last one — the footer's primary action.
  void _advanceToNext() {
    if (!mounted) {
      return;
    }
    final next = widget.nextItemCode;
    if (next == null) {
      Navigator.of(context).maybePop();
      return;
    }
    context.pushReplacement(
      '/jobs/${widget.jobId}/items/${Uri.encodeComponent(next)}',
    );
  }

  Future<void> _queueOffline(AssessmentRequest request) async {
    final store = ref.read(offlineStoreProvider);
    await store.saveCleanAssessmentLocally(
      jobId: jobId,
      itemCode: item.itemCode,
      request: request,
      assessment: {
        'itemCode': item.itemCode,
        'resultCode': request.resultCode,
        'score': request.score,
        'severityCode': request.severityCode,
        'notesEn': request.notesEn,
        'notesAr': request.notesAr,
        'state': 'LOCAL_ONLY',
        'clientRevision': request.clientRevision,
        'serverRevision': 0,
        'version': request.baseVersion,
        'issueValues': request.issueValues
            .map((value) => value.toJson())
            .toList(growable: false),
        'measurements': request.measurements
            .map((value) => value.toJson())
            .toList(growable: false),
        'evidence': const <dynamic>[],
      },
      idempotencyKey: 'assessment-${item.itemCode}-${request.clientRevision}',
    );
    ref.invalidate(syncQueueStatusProvider);
  }

  String? _severityCode() {
    final field = item.field('SEVERITY');
    if (field == null) {
      return null;
    }
    if (_isMulti(field)) {
      for (final values
          in _multiValues[field.fieldCode]?.values ?? const <Set<String>>[]) {
        if (values.isNotEmpty) {
          return values.first;
        }
      }
    }
    for (final value
        in _optionValues[field.fieldCode]?.values ?? const <String>[]) {
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  List<IssueValue> _issueValues() {
    final values = <IssueValue>[];
    for (final field in item.issueFields) {
      if (field.fieldCode == 'MEASUREMENT') {
        continue;
      }
      if (field.inputType == 'TEXT' && !field.allowFreeText) {
        continue;
      }
      for (final index in _indexesFor(field)) {
        if (!_dependencySatisfied(field, index)) {
          continue;
        }
        if (_isMulti(field)) {
          for (final code
              in _multiValues[field.fieldCode]?[index] ?? const {}) {
            values.add(
              IssueValue(
                fieldCode: field.fieldCode,
                valueIndex: index,
                optionValueCode: code,
                numericValue: null,
                unitCode: null,
                textValue: null,
              ),
            );
          }
          continue;
        }
        final controller = _fieldControllers[field.fieldCode]?[index];
        switch (field.inputType) {
          case 'NUMBER':
            final number = double.tryParse(
              controller?.text.trim().replaceAll(',', '.') ?? '',
            );
            if (number != null) {
              values.add(
                IssueValue(
                  fieldCode: field.fieldCode,
                  valueIndex: index,
                  optionValueCode: null,
                  numericValue: number,
                  unitCode: field.unitSetCode,
                  textValue: null,
                ),
              );
            }
          case 'TEXT':
            final text = controller?.text.trim() ?? '';
            if (text.isNotEmpty) {
              values.add(
                IssueValue(
                  fieldCode: field.fieldCode,
                  valueIndex: index,
                  optionValueCode: null,
                  numericValue: null,
                  unitCode: null,
                  textValue: text,
                ),
              );
            }
          default:
            final code = _optionValues[field.fieldCode]?[index] ?? '';
            if (code.isNotEmpty) {
              values.add(
                IssueValue(
                  fieldCode: field.fieldCode,
                  valueIndex: index,
                  optionValueCode: code,
                  numericValue: null,
                  unitCode: null,
                  textValue: null,
                ),
              );
            }
        }
      }
    }
    return values;
  }

  List<Measurement> _measurementsPayload() {
    final values = <Measurement>[];
    final unit = item.measurementUnit;
    for (final index in _measurementIndexes) {
      final value = _measurementFor(index);
      if (value != null) {
        values.add(
          Measurement(
            fieldCode: 'MEASUREMENT',
            valueIndex: index,
            numericValue: value,
            unitCode: unit,
          ),
        );
      }
    }
    return values;
  }

  Future<void> _captureEvidence(String type) async {
    final t = UiStrings.of(context);
    if (_queue.isBusy) {
      return;
    }
    final request = await showEvidenceCaptureSheet(
      context,
      evidenceType: type,
      evidenceTypes:
          ref.read(enumsProvider('evidence-type')).value ??
          const <ReferenceRecord>[],
    );
    if (request == null || !mounted) {
      return;
    }
    setState(() => _evidenceError = null);
    _queue.markCapturing(type);
    try {
      final existing = await _existingSha256();
      final captured = await _capture(type, request, existing);
      if (captured == null) {
        _queue.clearCapturing();
        return;
      }
      final result = await _queue.enqueue(
        captured,
        captionEn: request.captionEn,
        captionAr: null,
        existingSha256: existing,
      );
      if (!mounted) {
        return;
      }
      await _handleEvidenceResult(result);
    } on EvidenceCaptureException catch (error) {
      _queue.clearCapturing();
      if (!mounted) {
        return;
      }
      setState(() => _evidenceError = _evidenceFailureLabel(t, error.failure));
    } on Object catch (error) {
      _queue.clearCapturing();
      if (!mounted) {
        return;
      }
      setState(() => _evidenceError = _serverEvidenceError(t, error));
    }
  }

  Future<CapturedEvidence?> _capture(
    String type,
    EvidenceCaptureRequest request,
    List<String> existingSha256,
  ) {
    return switch (type) {
      'PHOTO' => _service.capturePhoto(source: request.source),
      'VIDEO' => _service.recordVideo(
        source: request.source,
        capturePoster: request.capturePoster,
        existingSha256: existingSha256,
      ),
      _ => _service.pickDocument(),
    };
  }

  Future<List<String>> _existingSha256() async {
    final evidence =
        ref
            .read(
              technicianEvidenceListProvider((
                jobId: jobId,
                itemCode: item.itemCode,
              )),
            )
            .value ??
        const <Evidence>[];
    final local = await ref
        .read(offlineStoreProvider)
        .evidenceForItem(jobId, item.itemCode);
    return <String>[
      ...evidence.map((value) => value.sha256).whereType<String>(),
      ...local
          .where((value) => value.state != 'RECEIVED')
          .map((value) => value.sha256),
    ];
  }

  Future<void> _handleEvidenceResult(EvidenceUploadResult result) async {
    final t = UiStrings.of(context);
    switch (result.outcome) {
      case EvidenceUploadOutcome.uploaded:
        _invalidateEvidence();
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianEvidenceUploaded),
        );
      case EvidenceUploadOutcome.queued:
        _invalidateEvidence();
        ref.invalidate(syncQueueStatusProvider);
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianOfflineQueued),
        );
      case EvidenceUploadOutcome.invalid:
        setState(
          () => _evidenceError = _evidenceFailureLabel(t, result.failure!),
        );
      case EvidenceUploadOutcome.failed:
        setState(() => _evidenceError = _serverEvidenceError(t, result.error!));
      case EvidenceUploadOutcome.cancelled:
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianEvidenceCancelled),
        );
    }
  }

  void _invalidateEvidence() {
    ref.invalidate(
      technicianEvidenceListProvider((jobId: jobId, itemCode: item.itemCode)),
    );
    ref.invalidate(technicianChecklistProvider(jobId));
    ref.invalidate(technicianSummaryProvider(jobId));
    ref.invalidate(syncQueueStatusProvider);
  }

  Future<void> _retryEvidence() async {
    final result = await _queue.retryLast();
    if (!mounted) {
      return;
    }
    await _handleEvidenceResult(result);
  }

  void _cancelEvidence() {
    _queue.cancel();
    if (mounted) {
      showAppSnackBar(
        context,
        message: UiStrings.of(context)(
          TechnicianKeys.technicianEvidenceCancelled,
        ),
      );
    }
  }

  String _evidenceFailureLabel(UiStrings t, EvidenceValidationFailure failure) {
    return switch (failure) {
      EvidenceValidationFailure.tooShort => t(
        TechnicianKeys.technicianVideoTooShort,
      ),
      EvidenceValidationFailure.tooLong => t(
        TechnicianKeys.technicianVideoTooLong,
      ),
      EvidenceValidationFailure.tooLarge => t(
        TechnicianKeys.technicianFileTooLarge,
      ),
      EvidenceValidationFailure.resolutionTooLow => t(
        TechnicianKeys.technicianPhotoResolutionTooLow,
      ),
      EvidenceValidationFailure.unsupportedPhotoType => t(
        TechnicianKeys.technicianPhotoTypeUnsupported,
      ),
      EvidenceValidationFailure.unsupportedVideoType => t(
        TechnicianKeys.technicianVideoTypeUnsupported,
      ),
      EvidenceValidationFailure.unsupportedDocumentType => t(
        TechnicianKeys.technicianDocumentTypeUnsupported,
      ),
      EvidenceValidationFailure.cameraRequired => t(
        TechnicianKeys.technicianCameraRequired,
      ),
      EvidenceValidationFailure.durationUnavailable => t(
        TechnicianKeys.technicianVideoDurationUnavailable,
      ),
      EvidenceValidationFailure.duplicate => t(
        TechnicianKeys.technicianEvidenceDuplicate,
      ),
      EvidenceValidationFailure.empty ||
      EvidenceValidationFailure.invalidHash ||
      EvidenceValidationFailure.unsupportedType => t(
        TechnicianKeys.technicianEvidenceFailed,
      ),
    };
  }

  String _serverEvidenceError(UiStrings t, Object error) {
    if (error is AppFailure && error.code == 'DUPLICATE_EVIDENCE') {
      return t(TechnicianKeys.technicianEvidenceDuplicate);
    }
    final fields = fieldErrorsByCode(error);
    final lang = Localizations.localeOf(context).languageCode;
    final message = fields.values
        .map((value) => value.messageFor(lang))
        .where((value) => value.isNotEmpty)
        .join('\n');
    return message.isEmpty
        ? t(TechnicianKeys.technicianEvidenceFailed)
        : message;
  }

  Future<void> _deleteEvidence(Evidence evidence) async {
    final t = UiStrings.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: t(TechnicianKeys.technicianDeleteEvidence),
      message: t(TechnicianKeys.technicianDeleteEvidence),
      confirmLabel: t(TechnicianKeys.commonConfirm),
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      if (evidence.id.startsWith('local-')) {
        await ref
            .read(offlineStoreProvider)
            .deleteLocalEvidence(evidence.id.substring('local-'.length));
        _invalidateEvidence();
        return;
      }
      await ref
          .read(technicianApiProvider)
          .deleteEvidence(jobId, item.itemCode, evidence.id);
      _invalidateEvidence();
    } on Object {
      if (mounted) {
        setState(
          () => _evidenceError = t(TechnicianKeys.technicianEvidenceFailed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final language = Localizations.localeOf(context).languageCode;
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        _flushQueuedEvidence();
      }
    });
    final evidenceAsync = ref.watch(
      technicianEvidenceListProvider((jobId: jobId, itemCode: item.itemCode)),
    );
    final resultRecords = ref.watch(enumsProvider('result')).value;
    final evidenceTypes = ref.watch(enumsProvider('evidence-type')).value;
    final evidence = evidenceAsync.asData?.value ?? const <Evidence>[];
    final requirement = _evidenceRequirement;
    final photos = evidence.where((value) => value.isPhoto).length;
    final videos = evidence.where((value) => value.isVideo).length;
    final documents = evidence.where((value) => value.isDocument).length;
    final evidenceOk = _evidenceSatisfied(evidence);
    final upload = _queue.state.value;
    final stage = _evidenceStage(t, upload, evidenceOk);
    final requiredDetails = _requiredDetailCount();
    final detailsOpen = _detailsOpen ?? requiredDetails > 0;
    final resultLabel_ = _result == null
        ? t(TechnicianKeys.notChecked)
        : resultLabel(resultRecords, _result!);
    final hint = _result == null
        ? t(TechnicianKeys.technicianSelectResult)
        : !evidenceOk
        ? t(TechnicianKeys.technicianEvidenceRequired)
        : widget.nextItemLabel == null
        ? t(TechnicianKeys.technicianAllCaughtUp)
        : '${t(TechnicianKeys.technicianNextUp)}: ${widget.nextItemLabel}';

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 24),
                children: [
                  _VerdictCard(
                    eyebrow: widget.eyebrow,
                    label: item.labelFor(language),
                    instruction: item.instructionFor(language),
                    spec: item.standardSpecFor(language),
                    unit: _measurementUnit,
                    safety: item.safetyCritical,
                    multi: item.multiPoint,
                    resultLabel: resultLabel_,
                    resultCode: _result,
                    suggested: _suggestedResult == null
                        ? null
                        : '${t(TechnicianKeys.technicianSuggestedResult)}: '
                              '${resultLabel(resultRecords, _suggestedResult!)}'
                              '${_suggestedScore == null ? '' : ' · ${t(TechnicianKeys.technicianScore)} $_suggestedScore'}',
                    codes: item.resultOptions,
                    onSelect: _selectResult,
                    error: _fieldErrors['resultCode']?.messageFor(language),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    _Note(message: _error!, tone: StatusTone.danger),
                  ],
                  if (_saved) ...[
                    const SizedBox(height: 10),
                    _Note(
                      message: t(TechnicianKeys.technicianItemSaved),
                      tone: StatusTone.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _EvidenceCard(
                    stageLabel: stage.label,
                    stageTone: stage.tone,
                    stageIcon: stage.icon,
                    photos: photos,
                    videos: videos,
                    documents: documents,
                    minPhotos: requirement.minPhotos,
                    minVideos: requirement.minVideos,
                    requiresDocument: requirement.requiresDocument,
                    evidenceOk: evidenceOk,
                    busy: _queue.isBusy,
                    upload: upload,
                    evidenceTypes: evidenceTypes,
                    evidence: evidence,
                    error: _evidenceError,
                    onCapture: _captureEvidence,
                    onCancel: _cancelEvidence,
                    onRetry: _retryEvidence,
                    onDelete: _deleteEvidence,
                    onMark: (value) =>
                        _canMark(value) ? () => _markDamage(value) : null,
                    loadBytes: _evidenceBytes,
                  ),
                  const SizedBox(height: 12),
                  _DetailsCard(
                    open: detailsOpen,
                    requiredCount: requiredDetails,
                    onToggle: () => setState(() => _detailsOpen = !detailsOpen),
                    measurement:
                        (item.measurementUnit != null ||
                            item.measurementBands.isNotEmpty)
                        ? Column(
                            children: [
                              for (final index in _measurementIndexes) ...[
                                AppTextField(
                                  controller: _measurements[index]!,
                                  label: index == null
                                      ? t(TechnicianKeys.technicianMeasurement)
                                      : '${t(TechnicianKeys.technicianMeasurement)} · $index',
                                  labelAbove: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  suffixText: _measurementUnit,
                                  errorText:
                                      _showValidation &&
                                          _measurementRequired &&
                                          _measurementFor(index) == null
                                      ? t(
                                          TechnicianKeys
                                              .technicianMeasurementRequired,
                                        )
                                      : _measurementError(index, language),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          )
                        : null,
                    score: _selectedScoreBand == null
                        ? null
                        : AppTextField(
                            controller: _score,
                            label: t(TechnicianKeys.technicianScore),
                            labelAbove: true,
                            keyboardType: TextInputType.number,
                            helperText: t(TechnicianKeys.technicianScoreHint, {
                              'min': _selectedScoreBand!.minScore,
                              'max': _selectedScoreBand!.maxScore,
                            }),
                            errorText: !_scoreValid
                                ? t(TechnicianKeys.technicianScoreOutOfRange, {
                                    'min': _selectedScoreBand!.minScore,
                                    'max': _selectedScoreBand!.maxScore,
                                  })
                                : _fieldErrors['score']?.messageFor(language),
                            onChanged: (_) {
                              _scoreManuallyEdited = true;
                              setState(() {});
                            },
                          ),
                    issueFields: item.issueFields.isEmpty
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t(TechnicianKeys.technicianIssueDetailsHint),
                                style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _IssueFields(
                                item: item,
                                result: _result,
                                language: language,
                                fieldErrors: _fieldErrors,
                                showValidation: _showValidation,
                                optionValues: _optionValues,
                                multiValues: _multiValues,
                                controllers: _fieldControllers,
                                dependencySatisfied: _dependencySatisfied,
                                indexesFor: _indexesFor,
                                isMulti: _isMulti,
                                optionsFor: _optionsFor,
                                requiredFor: _requiredFor,
                                missing: _isMissing,
                                onOptionChanged: (field, index, code) {
                                  setState(() {
                                    _optionValues.putIfAbsent(
                                      field.fieldCode,
                                      () => {},
                                    )[index] = code;
                                  });
                                },
                                onMultiChanged: (field, index, code, selected) {
                                  setState(() {
                                    final map = _multiValues.putIfAbsent(
                                      field.fieldCode,
                                      () => {},
                                    );
                                    final values = map.putIfAbsent(
                                      index,
                                      () => <String>{},
                                    );
                                    if (selected) {
                                      values.add(code);
                                    } else {
                                      values.remove(code);
                                    }
                                  });
                                },
                                controllerFor: _controller,
                                booleanLabel: _booleanLabel,
                              ),
                            ],
                          ),
                    notes: item.allowFreeTextNote
                        ? Column(
                            children: [
                              AppTextField(
                                controller: _notesEn,
                                label: t(TechnicianKeys.technicianCaptionsEn),
                                labelAbove: true,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 10),
                              AppTextField(
                                controller: _notesAr,
                                label: t(TechnicianKeys.technicianCaptionsAr),
                                labelAbove: true,
                                maxLines: 3,
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          )
                        : null,
                    notesHint:
                        item.allowFreeTextNote &&
                            _evidenceRequirement.minNotesChars > 0
                        ? t(TechnicianKeys.technicianNotesHint, {
                            'count': _evidenceRequirement.minNotesChars,
                          })
                        : null,
                  ),
                ],
              ),
            ),
            _ActionBar(
              summary: resultLabel_,
              hint: hint,
              saving: _saving,
              primaryLabel: widget.nextItemCode == null
                  ? t(TechnicianKeys.technicianSaveAndFinish)
                  : t(TechnicianKeys.technicianSaveAndNext),
              onPressed: () => _save(evidence, advance: true),
            ),
          ],
        ),
      ),
    );
  }

  bool _canMark(Evidence evidence) =>
      evidence.isPhoto &&
      (evidence.id.startsWith('local-') || evidence.status != 'PENDING');

  /// How many folded fields this item actually requires, so the
  /// disclosure can say so and start open when it matters.
  int _requiredDetailCount() {
    var count = 0;
    if (_measurementRequired) {
      count++;
    }
    if (item.allowFreeTextNote && _evidenceRequirement.minNotesChars > 0) {
      count++;
    }
    for (final field in item.issueFields) {
      if (!_requiredFor(field)) {
        continue;
      }
      if (_indexesFor(field)
          .any((index) => _dependencySatisfied(field, index))) {
        count++;
      }
    }
    return count;
  }

  /// Raw bytes for one evidence file: the offline copy while it is still
  /// queued, otherwise the uploaded content.
  Future<Uint8List?> _evidenceBytes(Evidence evidence) async {
    if (evidence.id.startsWith('local-')) {
      final local = await ref
          .read(offlineStoreProvider)
          .evidenceForItem(jobId, item.itemCode);
      final id = evidence.id.substring('local-'.length);
      for (final row in local) {
        if (row.id == id) {
          return row.bytes;
        }
      }
      return null;
    }
    final bytes = await ref
        .read(technicianApiProvider)
        .evidenceContent(jobId, item.itemCode, evidence.id);
    return Uint8List.fromList(bytes);
  }

  /// Opens the markup editor, then uploads the marked photo as ordinary
  /// photo evidence so the report shows the damage circled.
  Future<void> _markDamage(Evidence evidence) async {
    final t = UiStrings.of(context);
    if (_queue.isBusy) {
      return;
    }
    setState(() => _evidenceError = null);
    final language = Localizations.localeOf(context).languageCode;
    try {
      final bytes = await _evidenceBytes(evidence);
      if (!mounted) {
        return;
      }
      if (bytes == null) {
        setState(
          () => _evidenceError = t(TechnicianKeys.technicianEvidenceFailed),
        );
        return;
      }
      final marked = await Navigator.of(context).push<MarkedPhoto>(
        MaterialPageRoute(
          builder: (context) => PhotoMarkupPage(
            photoBytes: bytes,
            title: item.labelFor(language),
          ),
        ),
      );
      if (marked == null || !mounted) {
        return;
      }
      _queue.markCapturing('PHOTO');
      final existing = await _existingSha256();
      final caption = evidence.captionEn?.trim() ?? '';
      final markedCaption = caption.isEmpty
          ? t(TechnicianKeys.technicianMarkupCaption)
          : '$caption Â· ${t(TechnicianKeys.technicianMarkupCaption)}';
      final captured = CapturedEvidence(
        type: 'PHOTO',
        bytes: marked.bytes,
        mime: 'image/jpeg',
        capturedAt: DateTime.now().toUtc().toIso8601String(),
        captureSource: evidence.captureSource ?? 'CAMERA',
        width: marked.width,
        height: marked.height,
      );
      final result = await _queue.enqueue(
        captured,
        captionEn: markedCaption,
        captionAr: null,
        existingSha256: existing,
      );
      if (!mounted) {
        return;
      }
      await _handleEvidenceResult(result);
      if (!mounted) {
        return;
      }
      if (result.outcome == EvidenceUploadOutcome.uploaded ||
          result.outcome == EvidenceUploadOutcome.queued) {
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianMarkupSaved),
        );
      }
    } on Object catch (error) {
      _queue.clearCapturing();
      if (!mounted) {
        return;
      }
      setState(() => _evidenceError = _serverEvidenceError(t, error));
    }
  }

  String? get _measurementUnit {
    if (item.measurementUnit != null) {
      return item.measurementUnit;
    }
    for (final band in item.measurementBands) {
      if (band.unitCode != null) {
        return band.unitCode;
      }
    }
    return null;
  }

  String? _measurementError(String? index, String language) {
    final value = _measurementFor(index);
    if (value == null) {
      return null;
    }
    final band = item.bandForValue(value);
    if (band == null) {
      return null;
    }
    return _fieldErrors['MEASUREMENT']?.messageFor(language);
  }

  String? _suggestedResult;
  int? _suggestedScore;
}

// ============================================================ presentation

/// The field-level error the ported issue-field widget expects.\nclass _InlineError extends StatelessWidget {\n  const _InlineError({required this.message});\n\n  final String message;\n\n  @override\n  Widget build(BuildContext context) =>\n      _Note(message: message, tone: StatusTone.danger);\n}\n\n/// The field-level error the ported issue-field widget expects.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Note(message: message, tone: StatusTone.danger);
  }
}

/// The item, the standard it is judged against, and the verdict.
class _VerdictCard extends ConsumerWidget {
  const _VerdictCard({
    required this.eyebrow,
    required this.label,
    required this.instruction,
    required this.spec,
    required this.unit,
    required this.safety,
    required this.multi,
    required this.resultLabel,
    required this.resultCode,
    required this.suggested,
    required this.codes,
    required this.onSelect,
    required this.error,
  });

  final String eyebrow;
  final String label;
  final String? instruction;
  final String? spec;
  final String? unit;
  final bool safety;
  final bool multi;
  final String resultLabel;
  final String? resultCode;
  final String? suggested;
  final List<String> codes;
  final ValueChanged<String> onSelect;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final tones = context.statusColors;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _ResultPill(label: resultLabel, resultCode: resultCode),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: context.texts.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          if (instruction != null && instruction!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              instruction!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          if (spec != null && spec!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    spec!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (safety || multi || unit != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (safety)
                  _Flag(
                    label: t(TechnicianKeys.technicianSafetyCritical),
                    icon: Icons.health_and_safety_outlined,
                    tone: StatusTone.danger,
                  ),
                if (multi)
                  _Flag(
                    label: t(TechnicianKeys.technicianMultiPoint),
                    icon: Icons.grid_on_outlined,
                    tone: StatusTone.info,
                  ),
                if (unit != null)
                  _Flag(
                    label: '${t(TechnicianKeys.technicianUnit)}: $unit',
                    icon: Icons.speed_rounded,
                    tone: StatusTone.neutral,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            t(TechnicianKeys.technicianResult).toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _Verdicts(codes: codes, selected: resultCode, onSelect: onSelect),
          if (suggested != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 13,
                  color: tones.forTone(StatusTone.info).foreground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suggested!,
                    maxLines: 2,
                    style: context.texts.labelSmall?.copyWith(
                      color: tones.forTone(StatusTone.info).foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            _Note(message: error!, tone: StatusTone.danger),
          ],
        ],
      ),
    );
  }
}

/// Full-width verdict rows on a phone, three tiles where there is room.
class _Verdicts extends ConsumerWidget {
  const _Verdicts({
    required this.codes,
    required this.selected,
    required this.onSelect,
  });

  // Presentation grouping only; labels and membership come from the API.
  // gate-allow: codes
  static const _primary = [
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
  ];

  final List<String> codes;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(enumsProvider('result')).value;
    final primary = [
      for (final code in _primary)
        if (codes.contains(code)) code,
    ];
    final rest = [
      for (final code in codes)
        if (!_primary.contains(code)) code,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var index = 0; index < primary.length; index++) ...[
                  Expanded(
                    child: _VerdictTile(
                      code: primary[index],
                      label: resultLabel(records, primary[index]),
                      selected: selected == primary[index],
                      onTap: () => onSelect(primary[index]),
                    ),
                  ),
                  if (index != primary.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final code in rest)
                    _VerdictChip(
                      label: resultLabel(records, code),
                      selected: selected == code,
                      onTap: () => onSelect(code),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VerdictTile extends ConsumerWidget {
  const _VerdictTile({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pair = context.statusColors.forTone(
      resultTone(ref.watch(enumsProvider('result')).value, code),
    );
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 74),
          decoration: BoxDecoration(
            color: selected ? pair.background : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? pair.foreground : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? pair.foreground.withValues(alpha: 0.12)
                      : colors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  resultIcon(code),
                  size: 17,
                  color: selected ? pair.foreground : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: selected ? pair.foreground : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppFilterChip(
      label: label,
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ResultPill extends ConsumerWidget {
  const _ResultPill({required this.label, required this.resultCode});

  final String label;
  final String? resultCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pair = resultCode == null
        ? context.statusColors.forTone(StatusTone.neutral)
        : context.statusColors.forTone(
            resultTone(ref.watch(enumsProvider('result')).value, resultCode!),
          );
    return Container(
      height: 26,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(999),
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
            style: context.texts.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Evidence: the counts a result needs, one tap to capture, and the media
/// strip. Photos are real thumbnails; tapping one opens the damage marker.
class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.stageLabel,
    required this.stageTone,
    required this.stageIcon,
    required this.photos,
    required this.videos,
    required this.documents,
    required this.minPhotos,
    required this.minVideos,
    required this.requiresDocument,
    required this.evidenceOk,
    required this.busy,
    required this.upload,
    required this.evidenceTypes,
    required this.evidence,
    required this.error,
    required this.onCapture,
    required this.onCancel,
    required this.onRetry,
    required this.onDelete,
    required this.onMark,
    required this.loadBytes,
  });

  final String stageLabel;
  final StatusTone stageTone;
  final IconData stageIcon;
  final int photos;
  final int videos;
  final int documents;
  final int minPhotos;
  final int minVideos;
  final bool requiresDocument;
  final bool evidenceOk;
  final bool busy;
  final EvidenceUploadState upload;
  final List<ReferenceRecord>? evidenceTypes;
  final List<Evidence> evidence;
  final String? error;
  final ValueChanged<String> onCapture;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final ValueChanged<Evidence> onDelete;
  final VoidCallback? Function(Evidence) onMark;
  final Future<Uint8List?> Function(Evidence) loadBytes;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 16,
                color: colors.onSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t(TechnicianKeys.technicianEvidenceCounts),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: stageLabel, tone: stageTone, icon: stageIcon),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoUp = constraints.maxWidth < 420;
              final width = twoUp
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: width,
                    child: _CaptureTile(
                      icon: Icons.photo_camera_rounded,
                      label: t(TechnicianKeys.technicianCapturePhoto),
                      count: '$photos / $minPhotos',
                      filled: true,
                      enabled: !busy,
                      onTap: () => onCapture('PHOTO'),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _CaptureTile(
                      icon: Icons.videocam_rounded,
                      label: t(TechnicianKeys.technicianCaptureVideo),
                      count: '$videos / $minVideos',
                      enabled: !busy,
                      onTap: () => onCapture('VIDEO'),
                    ),
                  ),
                  if (requiresDocument || !twoUp)
                    SizedBox(
                      width: width,
                      child: _CaptureTile(
                        icon: Icons.description_rounded,
                        label: t(TechnicianKeys.technicianCaptureDocument),
                        count: '$documents / ${requiresDocument ? 1 : 0}',
                        enabled: !busy,
                        onTap: () => onCapture('DOCUMENT'),
                      ),
                    ),
                ],
              );
            },
          ),
          if (upload.busy) ...[
            const SizedBox(height: 10),
            if (upload.stage == EvidenceUploadStage.uploading) ...[
              LinearProgressIndicator(
                value: upload.progress,
                semanticsLabel: t(TechnicianKeys.technicianUploadProgress),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      upload.progress == null
                          ? ''
                          : t(TechnicianKeys.technicianEvidencePercent, {
                              'percent': (upload.progress! * 100).round(),
                            }),
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancel,
                    child: Text(
                      t(TechnicianKeys.technicianEvidenceCancel),
                      style: context.texts.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                upload.stage == EvidenceUploadStage.capturing
                    ? t(TechnicianKeys.technicianEvidenceStateCapturing)
                    : t(TechnicianKeys.technicianEvidenceUploading, {
                        'type': evidenceTypeLabel(
                          evidenceTypes,
                          upload.type ?? 'PHOTO',
                        ),
                      }),
                style: context.texts.bodySmall,
              ),
          ],
          if (upload.stage == EvidenceUploadStage.queued) ...[
            const SizedBox(height: 10),
            _Note(
              message: t(TechnicianKeys.technicianEvidenceQueued),
              tone: StatusTone.warning,
            ),
          ],
          if (upload.stage == EvidenceUploadStage.failed &&
              upload.failure == null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: t(TechnicianKeys.technicianRetryUpload),
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.tonal,
              onPressed: onRetry,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            _Note(message: error!, tone: StatusTone.danger),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in evidence)
                _MediaTile(
                  evidence: value,
                  evidenceTypes: evidenceTypes,
                  loadBytes: () => loadBytes(value),
                  onMark: onMark(value),
                  onDelete: () => onDelete(value),
                ),
              _AddTile(
                label: t(TechnicianKeys.technicianCapturePhoto),
                enabled: !busy,
                onTap: () => onCapture('PHOTO'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                evidenceOk
                    ? Icons.check_circle_outline
                    : Icons.error_outline_rounded,
                size: 14,
                color: evidenceOk
                    ? context.statusColors.success.foreground
                    : context.statusColors.warning.foreground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  evidenceOk
                      ? t(TechnicianKeys.technicianEvidenceSatisfied)
                      : t(TechnicianKeys.technicianEvidenceRequired),
                  style: context.texts.labelSmall?.copyWith(
                    color: evidenceOk
                        ? context.statusColors.success.foreground
                        : context.statusColors.warning.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One file in the media strip: real thumbnail for photos, tap to mark up.
class _MediaTile extends ConsumerStatefulWidget {
  const _MediaTile({
    required this.evidence,
    required this.evidenceTypes,
    required this.loadBytes,
    required this.onMark,
    required this.onDelete,
  });

  final Evidence evidence;
  final List<ReferenceRecord>? evidenceTypes;
  final Future<Uint8List?> Function() loadBytes;
  final VoidCallback? onMark;
  final VoidCallback onDelete;

  @override
  ConsumerState<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends ConsumerState<_MediaTile> {
  static const double _size = 74;

  Uint8List? _bytes;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.evidence.isPhoto) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.loadBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _done = true;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final evidence = widget.evidence;
    // The status tone and label come from the served taxonomy, not a local
    // guess about which states are "done".
    final tone = evidenceStatusTone(ref, evidence.status);
    final statusPair = context.statusColors.forTone(tone);
    final statusIcon = switch (tone) {
      StatusTone.success => Icons.check_rounded,
      StatusTone.danger => Icons.error_outline_rounded,
      _ => Icons.schedule_rounded,
    };
    final pending = tone != StatusTone.success;
    final label = evidence.isPhoto
        ? t(TechnicianKeys.technicianMarkDamage)
        : evidenceTypeLabel(widget.evidenceTypes, evidence.type);

    return Semantics(
      button: widget.onMark != null,
      label: '$label · ${evidenceStatusLabel(ref, evidence.status)}',
      child: GestureDetector(
        onTap: widget.onMark,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _content(evidence, pending),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 4,
                bottom: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: statusPair.foreground,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 1.5),
                  ),
                  child: Icon(statusIcon, size: 11, color: Colors.white),
                ),
              ),
              PositionedDirectional(
                start: 2,
                top: 2,
                child: Semantics(
                  button: true,
                  label: t(TechnicianKeys.technicianDeleteEvidence),
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Evidence evidence, bool pending) {
    final colors = context.colors;
    if (evidence.isPhoto) {
      final bytes = _bytes;
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          cacheWidth: 240,
          gaplessPlayback: true,
        );
      }
      return Center(
        child: _done
            ? Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              )
            : SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onSurfaceVariant,
                ),
              ),
      );
    }
    final duration = evidence.durationMs;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            evidence.isVideo
                ? Icons.play_circle_outline_rounded
                : Icons.description_outlined,
            size: 22,
            color: context.brand.ink,
          ),
          if (evidence.isVideo && duration != null) ...[
            const SizedBox(height: 2),
            Text(
              '${(duration / 1000).round()}s',
              style: context.texts.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: context.brand.container.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.brand.ink.withValues(alpha: enabled ? 0.55 : 0.25),
              width: 1.4,
            ),
          ),
          child: Icon(
            Icons.add_a_photo_outlined,
            size: 22,
            color: context.brand.ink.withValues(alpha: enabled ? 1 : 0.4),
          ),
        ),
      ),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.filled = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? count;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = filled ? Colors.white : colors.onSurface;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: filled
                ? context.brand.ink.withValues(alpha: enabled ? 1 : 0.45)
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? context.brand.ink : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: fg,
                        height: 1.2,
                      ),
                    ),
                    if (count != null)
                      Text(
                        count!,
                        style: context.texts.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: filled
                              ? Colors.white70
                              : colors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.open,
    required this.requiredCount,
    required this.onToggle,
    required this.measurement,
    required this.score,
    required this.issueFields,
    required this.notes,
    required this.notesHint,
  });

  final bool open;
  final int requiredCount;
  final VoidCallback onToggle;
  final Widget? measurement;
  final Widget? score;
  final Widget? issueFields;
  final Widget? notes;
  final String? notesHint;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final groups = <Widget>[?measurement, ?score, ?issueFields, ?notes];
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: t(TechnicianKeys.details),
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t(TechnicianKeys.details),
                      style: context.texts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (requiredCount > 0)
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.statusColors.warning.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t(TechnicianKeys.technicianRequiredCount, {
                            'count': requiredCount,
                          }),
                          style: context.texts.labelSmall?.copyWith(
                            color: context.statusColors.warning.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open && groups.isNotEmpty) ...[
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < groups.length; index++) ...[
                    if (index > 0) ...[
                      const SizedBox(height: 14),
                      Divider(height: 1, color: colors.outlineVariant),
                      const SizedBox(height: 14),
                    ],
                    if (index == 2 && notesHint != null) ...[
                      Text(
                        notesHint!,
                        style: context.texts.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    groups[index],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The pinned action: what is missing, then the next stop.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.summary,
    required this.hint,
    required this.saving,
    required this.primaryLabel,
    required this.onPressed,
  });

  final String summary;
  final String hint;
  final bool saving;
  final String primaryLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          summary.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PrimaryAction(
                    label: primaryLabel,
                    showIcon: !compact,
                    saving: saving,
                    onPressed: onPressed,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A white card on the canvas — the only container this screen uses.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.label, required this.icon, required this.tone});

  final String label;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Container(
      height: 24,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: pair.foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: pair.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.message, required this.tone, this.icon});

  final String message;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? Icons.info_outline_rounded,
              size: 14,
              color: pair.foreground,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message,
                style: context.texts.labelSmall?.copyWith(
                  color: pair.foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData resultIcon(String code) => switch (code) {
  'NO_ISSUE_OBSERVED' => Icons.check_rounded,
  'ATTENTION_RECOMMENDED' => Icons.priority_high_rounded,
  'DEFECT_FOUND' => Icons.close_rounded,
  _ => Icons.circle_outlined,
};

class _IssueFields extends StatelessWidget {
  const _IssueFields({
    required this.item,
    required this.result,
    required this.language,
    required this.fieldErrors,
    required this.showValidation,
    required this.optionValues,
    required this.multiValues,
    required this.controllers,
    required this.dependencySatisfied,
    required this.indexesFor,
    required this.isMulti,
    required this.optionsFor,
    required this.requiredFor,
    required this.missing,
    required this.onOptionChanged,
    required this.onMultiChanged,
    required this.controllerFor,
    required this.booleanLabel,
  });
  final ChecklistItem item;
  final String? result;
  final String language;
  final Map<String, ApiFieldError> fieldErrors;
  final bool showValidation;
  final Map<String, Map<String?, String>> optionValues;
  final Map<String, Map<String?, Set<String>>> multiValues;
  final Map<String, Map<String?, TextEditingController>> controllers;
  final bool Function(IssueField field, String? index) dependencySatisfied;
  final List<String?> Function(IssueField field) indexesFor;
  final bool Function(IssueField field) isMulti;
  final List<IssueOption> Function(IssueField field) optionsFor;
  final bool Function(IssueField field) requiredFor;
  final bool Function(IssueField field, String? index) missing;
  final void Function(IssueField field, String? index, String code)
  onOptionChanged;
  final void Function(
    IssueField field,
    String? index,
    String code,
    bool selected,
  )
  onMultiChanged;
  final TextEditingController Function(IssueField field, String? index)
  controllerFor;
  final String Function(UiStrings t, String code) booleanLabel;
  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final fields = [...item.issueFields]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in fields) ...[
          if (field.fieldCode != 'MEASUREMENT' &&
              !(field.inputType == 'TEXT' && !field.allowFreeText))
            for (final index in indexesFor(field)) ...[
              if (dependencySatisfied(field, index))
                _IssueFieldInput(
                  field: field,
                  index: index,
                  language: language,
                  required: requiredFor(field),
                  selectedOptions: optionValues[field.fieldCode]?[index],
                  selectedMulti:
                      multiValues[field.fieldCode]?[index] ?? const {},
                  controller: controllerFor(field, index),
                  options: optionsFor(field),
                  isMulti: isMulti(field),
                  booleanLabel: booleanLabel,
                  errorText:
                      fieldErrors[field.fieldCode]?.messageFor(language) ??
                      (showValidation && missing(field, index)
                          ? t(TechnicianKeys.technicianIssueFieldRequired)
                          : null),
                  onOptionChanged: (code) =>
                      onOptionChanged(field, index, code),
                  onMultiChanged: (code, selected) =>
                      onMultiChanged(field, index, code, selected),
                ),
              SizedBox(height: context.spacing.sm),
            ],
        ],
      ],
    );
  }
}

class _IssueFieldInput extends StatelessWidget {
  const _IssueFieldInput({
    required this.field,
    required this.index,
    required this.language,
    required this.required,
    required this.selectedOptions,
    required this.selectedMulti,
    required this.controller,
    required this.options,
    required this.isMulti,
    required this.booleanLabel,
    required this.errorText,
    required this.onOptionChanged,
    required this.onMultiChanged,
  });
  final IssueField field;
  final String? index;
  final String language;
  final bool required;
  final String? selectedOptions;
  final Set<String> selectedMulti;
  final TextEditingController controller;
  final List<IssueOption> options;
  final bool isMulti;
  final String Function(UiStrings t, String code) booleanLabel;
  final String? errorText;
  final ValueChanged<String> onOptionChanged;
  final void Function(String code, bool selected) onMultiChanged;
  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final label = index == null
        ? field.labelFor(language)
        : '${field.labelFor(language)} · $index';
    final title = required ? '$label *' : label;
    switch (field.inputType) {
      case 'NUMBER':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              label: title,
              labelAbove: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: (field.decimalPlaces ?? 0) > 0,
              ),
              suffixText: field.unitSetCode,
              errorText: errorText,
            ),
            if (field.minValue != null || field.maxValue != null) ...[
              SizedBox(height: context.spacing.xxs),
              Text(
                '${field.minValue ?? ''} – ${field.maxValue ?? ''}'
                '${field.unitSetCode == null ? '' : ' ${field.unitSetCode}'}',
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      case 'TEXT':
        return AppTextField(
          controller: controller,
          label: title,
          labelAbove: true,
          maxLines: 2,
          errorText: errorText,
        );
      case 'BOOLEAN':
      case 'SELECT':
      case 'MULTI_SELECT':
        final list = options;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.xxs),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                for (final option in list)
                  AppFilterChip(
                    label:
                        field.inputType == 'BOOLEAN' &&
                            (option.labelEn.isEmpty && option.labelAr.isEmpty)
                        ? booleanLabel(t, option.code)
                        : issueOptionLabel(t, option, language),
                    selected: isMulti
                        ? selectedMulti.contains(option.code)
                        : selectedOptions == option.code,
                    onSelected: (selected) {
                      if (isMulti) {
                        onMultiChanged(option.code, selected);
                      } else {
                        onOptionChanged(selected ? option.code : '');
                      }
                    },
                  ),
              ],
            ),
            if (errorText != null) _InlineError(message: errorText!),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// The app's primary action: brand ink, 14 px radius, 48 px tall. AppButton's
/// `large` variant paints the lighter emerald, which does not match the
/// primary actions on the rest of the technician surface.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
    this.showIcon = true,
    this.saving = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool showIcon;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final enabled = !saving;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: 48,
        child: Material(
          color: enabled
              ? context.brand.ink
              : context.brand.ink.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (saving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (showIcon && !saving) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
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
