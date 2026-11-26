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
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_evidence.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_evidence_viewer.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_item.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_issue_fields.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_mark_prompt.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_results.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_ui.dart';
import 'package:technician_app/src/features/inspection/option_labels.dart';
import 'package:technician_app/src/features/inspection/photo_markup_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';
import 'package:uuid/uuid.dart';

import '../jobs/queue/jobs_queue_format.dart';
import '../jobs/queue/queue_model.dart';

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
          return _AssessmentForm(
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
            vehicleLabel: queueVehicleLabel(checklist.job),
            reference: checklist.job.reference,
            done: checklist.completed,
            total: checklist.total,
            nextItemCode: _nextItem(checklist, item)?.itemCode,
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
    required this.vehicleLabel,
    required this.reference,
    required this.done,
    required this.total,
    this.nextItemCode,
    super.key,
  });

  final String jobId;
  final ChecklistItem item;
  final String eyebrow;
  final bool readOnly;
  final String vehicleLabel;
  final String reference;
  final int done;
  final int total;
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

    final evidenceZone = EvidenceSection(
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
              'type': evidenceTypeLabel(evidenceTypes, upload.type ?? 'PHOTO'),
            }),
      onCancel: _cancelEvidence,
      failed:
          upload.stage == EvidenceUploadStage.failed && upload.failure == null,
      onRetry: _retryEvidence,
      error: _evidenceError,
      queued: upload.stage == EvidenceUploadStage.queued,
    );

    final zones = <Widget>[
      if (readOnly) ...[
        FieldworkValues(
          resultLabel: _result == null
              ? t(TechnicianKeys.notChecked)
              : resultLabel(resultRecords, _result!),
          resultTone: resultTone(resultRecords, _result),
          resultCaption: t(TechnicianKeys.technicianResult),
          values: _readOnlyValues(t, language),
        ),
        evidenceZone,
      ] else ...[
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
        if (_error != null)
          FieldworkNote(
            message: _error!,
            tone: StatusTone.danger,
            icon: Icons.error_outline_rounded,
          ),
        if (_saved)
          FieldworkNote(
            message: t(TechnicianKeys.technicianItemSaved),
            tone: StatusTone.success,
            icon: Icons.check_circle_outline,
          ),
        ?_measurementZone(t),
        if (item.issueFields.isNotEmpty)
          IssueChipsSection(
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
                _optionValues.putIfAbsent(field.fieldCode, () => {})[index] =
                    code;
              });
            },
            onMultiChanged: (field, index, code, selected) {
              _autoSaveArmed = true;
              setState(() {
                final map = _multiValues.putIfAbsent(field.fieldCode, () => {});
                final values = map.putIfAbsent(index, () => <String>{});
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
        evidenceZone,
        if (_markCandidate != null)
          MarkPrompt(
            photoBytes: _markCandidate!.bytes,
            // A defect emphasises marking over keeping the photo.
            // gate-allow: behaviour — emphasis follows the verdict.
            defect: _result == 'DEFECT_FOUND',
            onMark: _markCandidateDamage,
            onDismiss: () => setState(() => _markCandidate = null),
          ),
        if (showNotes)
          FieldworkNotes(
            title: t(TechnicianKeys.technicianNotes),
            counter: t(TechnicianKeys.technicianNotesCount, {
              'done': _notesEn.text.trim().length,
              'required': minNotes,
            }),
            englishLabel: t(TechnicianKeys.technicianCaptionsEn),
            arabicLabel: t(TechnicianKeys.technicianCaptionsAr),
            englishController: _notesEn,
            arabicController: _notesAr,
            onChanged: (_) => setState(() {}),
            enabled: !_saving,
          ),
      ],
    ];

    final nextItemCode = widget.nextItemCode;
    return FieldworkItemScreen(
      header: FieldworkItemHeader(
        backLabel: MaterialLocalizations.of(context).backButtonTooltip,
        title: widget.vehicleLabel,
        reference: widget.reference,
        done: widget.done,
        total: widget.total,
        progressLabel: t(TechnicianKeys.technicianQueueItems, {
          'done': widget.done,
          'total': widget.total,
        }),
      ),
      hero: FieldworkHero(
        eyebrow: widget.eyebrow,
        label: item.labelFor(language),
        instruction: item.instructionFor(language),
        spec: item.standardSpecFor(language),
        safety: item.safetyCritical,
        safetyLabel: t(TechnicianKeys.technicianSafetyCritical),
        numberLabel: '${item.sortOrder}'.padLeft(2, '0'),
      ),
      zones: zones,
      footer: ItemFooter(
        primaryLabel: readOnly
            ? t(TechnicianKeys.commonBack)
            : nextItemCode == null
            ? t(TechnicianKeys.technicianSaveAndFinish)
            : t(TechnicianKeys.technicianSaveAndNext),
        onPrimary: readOnly
            ? () => Navigator.of(context).maybePop()
            : () => _save(evidence, advance: true),
        saving: _saving && !readOnly,
        secondaryLabel: readOnly || nextItemCode == null
            ? null
            : t(TechnicianKeys.technicianSessionNext),
        onSecondary: readOnly || nextItemCode == null ? null : _advanceToNext,
      ),
    );
  }

  /// Measurement and score, when the served bands give this item one. Both
  /// stay live: clearing a measurement nulls the value, and the score is only
  /// in range when a band exists.
  Widget? _measurementZone(UiStrings t) {
    final language = Localizations.localeOf(context).languageCode;
    final fields = <Widget>[];
    if (item.measurementUnit != null || item.measurementBands.isNotEmpty) {
      for (final index in _measurementIndexes) {
        fields.add(
          AppTextField(
            controller: _measurements[index]!,
            label: index == null
                ? t(TechnicianKeys.technicianMeasurement)
                : '${t(TechnicianKeys.technicianMeasurement)} · $index',
            labelAbove: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: _measurementUnit,
            errorText:
                _showValidation &&
                    _measurementRequired &&
                    _measurementFor(index) == null
                ? t(TechnicianKeys.technicianMeasurementRequired)
                : _measurementError(index, language),
          ),
        );
        fields.add(const SizedBox(height: 10));
      }
    }
    final band = _selectedScoreBand;
    if (band != null) {
      fields.add(
        AppTextField(
          controller: _score,
          label: t(TechnicianKeys.technicianScore),
          labelAbove: true,
          keyboardType: TextInputType.number,
          helperText: t(TechnicianKeys.technicianScoreHint, {
            'min': band.minScore,
            'max': band.maxScore,
          }),
          errorText: !_scoreValid
              ? t(TechnicianKeys.technicianScoreOutOfRange, {
                  'min': band.minScore,
                  'max': band.maxScore,
                })
              : _fieldErrors['score']?.messageFor(language),
          onChanged: (_) {
            _scoreManuallyEdited = true;
            _autoSaveArmed = true;
            setState(() {});
          },
        ),
      );
    }
    if (fields.isEmpty) {
      return null;
    }
    // The trailing gap belongs to the zone separator, not to the last field.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [...fields]..removeLast(),
    );
  }

  /// Every value the technician saved, for the read-only view. No field, no
  /// capture affordance, nothing to type into.
  List<FieldworkValue> _readOnlyValues(UiStrings t, String language) {
    final values = <FieldworkValue>[];
    if (item.measurementUnit != null || item.measurementBands.isNotEmpty) {
      for (final index in _measurementIndexes) {
        final measurement = _measurementFor(index);
        if (measurement == null) {
          continue;
        }
        final unit = _measurementUnit;
        values.add(
          FieldworkValue(
            label: index == null
                ? t(TechnicianKeys.technicianMeasurement)
                : '${t(TechnicianKeys.technicianMeasurement)} · $index',
            value:
                '${_formatNumber(measurement)}${unit == null ? '' : ' $unit'}',
          ),
        );
      }
    }
    final score = _score.text.trim();
    if (score.isNotEmpty) {
      values.add(
        FieldworkValue(label: t(TechnicianKeys.technicianScore), value: score),
      );
    }
    for (final field in item.issueFields) {
      if (field.fieldCode == 'MEASUREMENT' ||
          (field.inputType == 'TEXT' && !field.allowFreeText)) {
        continue;
      }
      final options = _optionsFor(field);
      for (final index in _indexesFor(field)) {
        if (!_dependencySatisfied(field, index)) {
          continue;
        }
        if (_isMulti(field)) {
          final selected =
              _multiValues[field.fieldCode]?[index] ?? const <String>{};
          if (selected.isEmpty) {
            continue;
          }
          final labels = <String>[
            for (final option in options)
              if (selected.contains(option.code))
                issueOptionLabel(t, option, language),
          ];
          values.add(
            _issueFieldValue(field, index, labels.join(', '), language),
          );
          continue;
        }
        switch (field.inputType) {
          case 'NUMBER':
            final text =
                _fieldControllers[field.fieldCode]?[index]?.text.trim() ?? '';
            if (text.isEmpty) {
              continue;
            }
            final unit = field.unitSetCode;
            values.add(
              _issueFieldValue(
                field,
                index,
                '$text${unit == null ? '' : ' $unit'}',
                language,
              ),
            );
          case 'TEXT':
            final text =
                _fieldControllers[field.fieldCode]?[index]?.text.trim() ?? '';
            if (text.isEmpty) {
              continue;
            }
            values.add(_issueFieldValue(field, index, text, language));
          default:
            final code = _optionValues[field.fieldCode]?[index] ?? '';
            if (code.isEmpty) {
              continue;
            }
            IssueOption? match;
            for (final option in options) {
              if (option.code == code) {
                match = option;
                break;
              }
            }
            values.add(
              _issueFieldValue(
                field,
                index,
                match == null ? code : issueOptionLabel(t, match, language),
                language,
              ),
            );
        }
      }
    }
    return values;
  }

  FieldworkValue _issueFieldValue(
    IssueField field,
    String? index,
    String value,
    String language,
  ) {
    return FieldworkValue(
      label: index == null
          ? field.labelFor(language)
          : '${field.labelFor(language)} · $index',
      value: value,
    );
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
