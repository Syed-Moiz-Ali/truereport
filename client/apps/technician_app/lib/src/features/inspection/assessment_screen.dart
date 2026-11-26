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
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/features/inspection/option_labels.dart';
import 'package:technician_app/src/features/inspection/photo_markup_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';
import 'package:uuid/uuid.dart';

import '../jobs/queue/jobs_queue_primitives.dart';
import '../jobs/queue/jobs_queue_style.dart';
import '../jobs/queue/queue_model.dart';
import 'assessment/evidence_section.dart';
import 'assessment/evidence_strip.dart';
import 'assessment/evidence_viewer.dart';
import 'assessment/item_footer.dart';
import 'assessment/item_header.dart';
import 'assessment/mark_prompt.dart';
import 'assessment/result_options.dart';

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
              Expanded(
                child: _AssessmentForm(
                  key: ValueKey(
                    '$jobId-${item.itemCode}-${item.assessment?.version ?? 0}',
                  ),
                  jobId: jobId,
                  item: item,
                  readOnly: verbFor(checklist.job) == QueueVerb.view,
                  eyebrow: _eyebrow(
                    checklist,
                    item,
                    Localizations.localeOf(context).languageCode,
                    t,
                  ),
                  nextItemCode: _nextItem(checklist, item)?.itemCode,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "ITEM 6 OF 30 · Brakes" — global position plus the section name.
  String _eyebrow(
    Checklist checklist,
    ChecklistItem item,
    String language,
    UiStrings t,
  ) {
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
    return '${t(TechnicianKeys.technicianSessionItemOf, {'number': item.sortOrder, 'total': checklist.total}).toUpperCase()} · ${category.nameFor(language)}';
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
class _AssessmentForm extends ConsumerStatefulWidget {
  const _AssessmentForm({
    required this.jobId,
    required this.item,
    required this.eyebrow,
    required this.readOnly,
    this.nextItemCode,
    super.key,
  });

  final String jobId;
  final ChecklistItem item;
  final String eyebrow;
  final bool readOnly;
  final String? nextItemCode;

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

  /// The shared capture service, resolved from the provider so tests can
  /// substitute it (the real one would open the platform camera).
  EvidenceCaptureService get _service =>
      ref.read(evidenceCaptureServiceProvider);
  late final EvidenceUploadQueue _queue;
  Map<String, ApiFieldError> _fieldErrors = {};
  String? _result;
  String? _error;

  /// Auto-save arming: set whenever the technician changes an answer or adds
  /// evidence this session. A pre-answered item opened for review never
  /// auto-saves on mount.
  /// Auto-save arming: set whenever the technician changes an answer or adds
  /// evidence this session. A pre-answered item opened for review never
  /// auto-saves on mount.
  bool _autoSaveArmed = false;

  /// The fresh photo awaiting the mark question, with its in-memory bytes so
  /// marking never needs to reload it.
  ({Uint8List bytes, String caption})? _markCandidate;

  /// Sha of the in-flight upload attempt, so the strip can badge the matching
  /// tile as uploading; the last failed attempt's sha for the failed badge.
  /// Both clear when the next capture starts.
  String? _activeSha;
  String? _uploadingSha;
  String? _failedSha;

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
    _autoSaveArmed = true;
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
    final changed = code != _result;
    setState(() {
      _result = code;
      _resultManuallyChosen = true;
      _scoreManuallyEdited = false;
      if (changed) {
        _autoSaveArmed = true;
      }
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

  /// Captures straight from the camera: no source sheet, no caption sheet.
  /// Photo and video go through the existing capture service and queue;
  /// documents open the file picker directly.
  Future<void> _captureDirect(String type) async {
    final t = UiStrings.of(context);
    if (_queue.isBusy) {
      return;
    }
    setState(() {
      _evidenceError = null;
      _failedSha = null;
    });
    _queue.markCapturing(type);
    try {
      final existing = await _existingSha256();
      final CapturedEvidence? captured = switch (type) {
        // gate-allow: behaviour — evidence type selects the capture call.
        'PHOTO' => await _service.capturePhoto(),
        'VIDEO' => await _service.recordVideo(existingSha256: existing),
        _ => await _service.pickDocument(),
      };
      if (captured == null) {
        _queue.clearCapturing();
        return;
      }
      _activeSha = sha256Hex(captured.bytes);
      _uploadingSha = _activeSha;
      final result = await _queue.enqueue(
        captured,
        captionEn: null,
        captionAr: null,
        existingSha256: existing,
      );
      if (!mounted) {
        return;
      }
      await _handleEvidenceResult(result);
      if (type == 'PHOTO' &&
          (result.outcome == EvidenceUploadOutcome.uploaded ||
              result.outcome == EvidenceUploadOutcome.queued)) {
        if (!mounted) {
          return;
        }
        setState(() {
          _markCandidate = (bytes: captured.bytes, caption: '');
        });
      }
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
        _uploadingSha = null;
        _autoSaveArmed = true;
        _invalidateEvidence();
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianEvidenceUploaded),
        );
      case EvidenceUploadOutcome.queued:
        _uploadingSha = null;
        _autoSaveArmed = true;
        _invalidateEvidence();
        ref.invalidate(syncQueueStatusProvider);
        showAppSnackBar(
          context,
          message: t(TechnicianKeys.technicianOfflineQueued),
        );
      case EvidenceUploadOutcome.invalid:
        _uploadingSha = null;
        _failedSha = _activeSha;
        setState(
          () => _evidenceError = _evidenceFailureLabel(t, result.failure!),
        );
      case EvidenceUploadOutcome.failed:
        _uploadingSha = null;
        _failedSha = _activeSha;
        setState(() => _evidenceError = _serverEvidenceError(t, result.error!));
      case EvidenceUploadOutcome.cancelled:
        _uploadingSha = null;
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
    _failedSha = null;
    _uploadingSha = _activeSha;
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

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
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
    final upload = _queue.state.value;
    final requiredDetails = _requiredDetailCount();
    final detailsOpen = _detailsOpen ?? requiredDetails > 0;
    final readOnly = widget.readOnly;
    final minNotes = requirement.minNotesChars;
    final showNotes = !readOnly && item.allowFreeTextNote && minNotes > 0;

    // Auto-save through the existing path as soon as the chosen result's
    // rule is met, then advance. A pre-answered item opened for review
    // never fires on mount: only this session's choices arm it.
    if (!readOnly &&
        !_saving &&
        _autoSaveArmed &&
        _result != null &&
        _formValid(evidence)) {
      _autoSaveArmed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final fresh =
            ref
                .read(
                  technicianEvidenceListProvider((
                    jobId: jobId,
                    itemCode: item.itemCode,
                  )),
                )
                .value ??
            evidence;
        _save(fresh, advance: true);
      });
    }

    final needPhotos = photos < requirement.minPhotos;
    final needVideos = videos < requirement.minVideos;
    final needDocs = requirement.requiresDocument && documents == 0;
    final String? secondaryLabel = readOnly
        ? null
        : needPhotos
        ? t(TechnicianKeys.addPhoto)
        : needVideos
        ? t(TechnicianKeys.addVideo)
        : needDocs
        ? t(TechnicianKeys.technicianCaptureDocument)
        : null;
    void secondaryAction() {
      if (needPhotos) {
        _captureDirect('PHOTO');
      } else if (needVideos) {
        _captureDirect('VIDEO');
      } else if (needDocs) {
        _captureDirect('DOCUMENT');
      }
    }

    // Presentation grouping only; labels and membership come from the API.
    // gate-allow: codes
    const primaryCodes = [
      'NO_ISSUE_OBSERVED',
      'ATTENTION_RECOMMENDED',
      'DEFECT_FOUND',
    ];
    final primary = [
      for (final code in primaryCodes)
        if (item.resultOptions.contains(code)) code,
    ];
    final rest = [
      for (final code in item.resultOptions)
        if (!primaryCodes.contains(code)) code,
    ];
    ResultOptionView viewFor(String code) => ResultOptionView(
      code: code,
      label: resultLabel(resultRecords, code),
      tone: resultTone(resultRecords, code),
      icon: resultIcon(code),
    );

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 16, 4),
              child: ItemHeader(
                eyebrow: widget.eyebrow,
                label: item.labelFor(language),
                instruction: item.instructionFor(language),
                spec: item.standardSpecFor(language),
                safety: item.safetyCritical,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 24),
                children: [
                  if (readOnly)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceLowest,
                        borderRadius: BorderRadius.circular(
                          QueueMetrics.radiusCard,
                        ),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t(TechnicianKeys.technicianResult).toUpperCase(),
                            style: queueEyebrow(context),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: QueueStatusChip(
                              label: _result == null
                                  ? t(TechnicianKeys.notChecked)
                                  : resultLabel(resultRecords, _result!),
                              tone: resultTone(resultRecords, _result),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ResultOptions(
                      options: [for (final code in primary) viewFor(code)],
                      rest: [for (final code in rest) viewFor(code)],
                      selected: _result,
                      onSelect: _selectResult,
                      suggestion: _suggestedResult == null
                          ? null
                          : '${t(TechnicianKeys.technicianSuggestedResult)}: '
                                '${resultLabel(resultRecords, _suggestedResult!)}'
                                '${_suggestedScore == null ? '' : ' · ${t(TechnicianKeys.technicianScore)} $_suggestedScore'}',
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
                  EvidenceSection(
                    photos: photos,
                    minPhotos: requirement.minPhotos,
                    videos: videos,
                    minVideos: requirement.minVideos,
                    documents: documents,
                    minDocuments: requirement.requiresDocument ? 1 : 0,
                    strip: evidence.isEmpty
                        ? null
                        : EvidenceStrip(
                            items: evidence,
                            upload: upload,
                            uploadingSha: _uploadingSha,
                            failedSha: _failedSha,
                            interactive: !readOnly,
                            onOpen: _openEvidence,
                            onDelete: _confirmDeleteEvidence,
                            loadBytes: _evidenceBytes,
                          ),
                    onCapturePhoto: () => _captureDirect('PHOTO'),
                    onCaptureVideo: () => _captureDirect('VIDEO'),
                    onCaptureDocument: requirement.requiresDocument
                        ? () => _captureDirect('DOCUMENT')
                        : null,
                    interactive: !readOnly,
                    busy: _queue.isBusy,
                    progress: upload.progress,
                    progressLabel: upload.stage == EvidenceUploadStage.capturing
                        ? t(TechnicianKeys.technicianEvidenceStateCapturing)
                        : t(TechnicianKeys.technicianEvidenceUploading, {
                            'type': evidenceTypeLabel(
                              evidenceTypes,
                              upload.type ?? 'PHOTO',
                            ),
                          }),
                    onCancel: _cancelEvidence,
                    failed:
                        upload.stage == EvidenceUploadStage.failed &&
                        upload.failure == null,
                    onRetry: _retryEvidence,
                    error: _evidenceError,
                    queued: upload.stage == EvidenceUploadStage.queued,
                  ),
                  if (_markCandidate != null && !readOnly) ...[
                    const SizedBox(height: 12),
                    MarkPrompt(
                      photoBytes: _markCandidate!.bytes,
                      // A defect emphasises marking over keeping the photo.
                      // gate-allow: behaviour — emphasis follows the verdict.
                      defect: _result == 'DEFECT_FOUND',
                      onMark: _markCandidateDamage,
                      onDismiss: () => setState(() => _markCandidate = null),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (showNotes) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceLowest,
                        borderRadius: BorderRadius.circular(
                          QueueMetrics.radiusCard,
                        ),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t(TechnicianKeys.technicianNotes),
                                  style: queueText(
                                    context,
                                    16,
                                    weight: FontWeight.w700,
                                    height: 22,
                                    tracking: -0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t(TechnicianKeys.technicianNotesCount, {
                                  'done': _notesEn.text.trim().length,
                                  'required': minNotes,
                                }),
                                textDirection: TextDirection.ltr,
                                style: queueText(
                                  context,
                                  13,
                                  weight: FontWeight.w700,
                                  height: 18,
                                  tabular: true,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _notesEn,
                            label: t(TechnicianKeys.technicianCaptionsEn),
                            labelAbove: true,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _notesAr,
                            label: t(TechnicianKeys.technicianCaptionsAr),
                            labelAbove: true,
                            maxLines: 3,
                            textDirection: TextDirection.rtl,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                              _autoSaveArmed = true;
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
                                  _autoSaveArmed = true;
                                  setState(() {
                                    _optionValues.putIfAbsent(
                                      field.fieldCode,
                                      () => {},
                                    )[index] = code;
                                  });
                                },
                                onMultiChanged: (field, index, code, selected) {
                                  _autoSaveArmed = true;
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
                  ),
                ],
              ),
            ),
            ItemFooter(
              primaryLabel: readOnly
                  ? t(TechnicianKeys.commonBack)
                  : widget.nextItemCode == null
                  ? t(TechnicianKeys.technicianSaveAndFinish)
                  : t(TechnicianKeys.technicianSaveAndNext),
              onPrimary: readOnly
                  ? () => Navigator.of(context).maybePop()
                  : () => _save(evidence, advance: true),
              saving: _saving && !readOnly,
              secondaryLabel: secondaryLabel,
              onSecondary: secondaryLabel == null ? null : secondaryAction,
            ),
          ],
        ),
      ),
    );
  }

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

  /// Opens the markup editor for the just-captured photo, then uploads the
  /// marked image as an additional photo through the existing queue.
  Future<void> _markCandidateDamage() async {
    final candidate = _markCandidate;
    if (candidate == null || _queue.isBusy) {
      return;
    }
    setState(() {
      _markCandidate = null;
      _evidenceError = null;
    });
    final language = Localizations.localeOf(context).languageCode;
    try {
      final marked = await Navigator.of(context).push<MarkedPhoto>(
        MaterialPageRoute(
          builder: (_) => PhotoMarkupPage(
            photoBytes: candidate.bytes,
            title: item.labelFor(language),
          ),
        ),
      );
      if (marked == null || !mounted) {
        return;
      }
      await _enqueueMarked(
        marked.bytes,
        marked.width,
        marked.height,
        candidate.caption,
      );
    } on Object catch (error) {
      _queue.clearCapturing();
      if (!mounted) {
        return;
      }
      setState(
        () =>
            _evidenceError = _serverEvidenceError(UiStrings.of(context), error),
      );
    }
  }

  /// Deletes a tile after the confirm sheet: offline-queued rows through the
  /// offline store, served rows through the existing delete endpoint.
  Future<void> _confirmDeleteEvidence(Evidence evidence) async {
    final t = UiStrings.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: t(TechnicianKeys.technicianDeleteEvidence),
      message: t(TechnicianKeys.technicianDeleteEvidenceBody),
      confirmLabel: t(TechnicianKeys.delete),
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      if (evidence.id.startsWith('local-')) {
        await ref
            .read(offlineStoreProvider)
            .deleteLocalEvidence(evidence.id.substring('local-'.length));
      } else {
        await ref
            .read(technicianApiProvider)
            .deleteEvidence(jobId, evidence.itemCode, evidence.id);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _evidenceError = _serverEvidenceError(t, error));
      return;
    }
    _invalidateEvidence();
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: t(TechnicianKeys.technicianEvidenceDeleted),
    );
  }

  /// Thumbnail bytes for the strip: offline-queued rows read the queued blob,
  /// served rows download through the existing content endpoint.
  Future<Uint8List?> _evidenceBytes(Evidence evidence) async {
    try {
      if (evidence.id.startsWith('local-')) {
        final local = await ref
            .read(offlineStoreProvider)
            .evidenceForItem(jobId, evidence.itemCode);
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
          .evidenceContent(jobId, evidence.itemCode, evidence.id);
      return Uint8List.fromList(bytes);
    } on Object {
      return null;
    }
  }

  /// Opens a tile: photos go through the existing markup route and upload as
  /// an additional marked photo; video and documents open the viewer sheet.
  /// Read-only items view everything in the sheet — never the editor.
  Future<void> _openEvidence(Evidence evidence) async {
    if (!evidence.isPhoto || widget.readOnly) {
      await showEvidenceViewer(context, evidence);
      return;
    }
    final bytes = await _evidenceBytes(evidence);
    if (!mounted) {
      return;
    }
    if (bytes == null) {
      setState(
        () => _evidenceError = UiStrings.of(context)(
          TechnicianKeys.commonLoadFailed,
        ),
      );
      return;
    }
    final language = Localizations.localeOf(context).languageCode;
    final marked = await Navigator.of(context).push<MarkedPhoto>(
      MaterialPageRoute(
        builder: (_) =>
            PhotoMarkupPage(photoBytes: bytes, title: item.labelFor(language)),
      ),
    );
    if (marked == null || !mounted) {
      return;
    }
    await _enqueueMarked(
      marked.bytes,
      marked.width,
      marked.height,
      evidence.captionFor(language) ?? '',
    );
  }

  /// Uploads marked bytes as ordinary photo evidence so the report shows the
  /// damage circled.
  Future<void> _enqueueMarked(
    Uint8List bytes,
    int? width,
    int? height,
    String baseCaption,
  ) async {
    final t = UiStrings.of(context);
    _queue.markCapturing('PHOTO');
    _activeSha = sha256Hex(bytes);
    _uploadingSha = _activeSha;
    _failedSha = null;
    try {
      final existing = await _existingSha256();
      final caption = baseCaption.isEmpty
          ? t(TechnicianKeys.technicianMarkupCaption)
          : '$baseCaption · ${t(TechnicianKeys.technicianMarkupCaption)}';
      final captured = CapturedEvidence(
        type: 'PHOTO',
        bytes: bytes,
        mime: 'image/jpeg',
        capturedAt: DateTime.now().toUtc().toIso8601String(),
        captureSource: 'CAMERA',
        width: width,
        height: height,
      );
      final result = await _queue.enqueue(
        captured,
        captionEn: caption,
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
      setState(() {
        _uploadingSha = null;
        _failedSha = _activeSha;
        _evidenceError = _serverEvidenceError(t, error);
      });
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
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.open,
    required this.requiredCount,
    required this.onToggle,
    required this.measurement,
    required this.score,
    required this.issueFields,
  });

  final bool open;
  final int requiredCount;
  final VoidCallback onToggle;
  final Widget? measurement;
  final Widget? score;
  final Widget? issueFields;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final groups = <Widget>[?measurement, ?score, ?issueFields];
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
