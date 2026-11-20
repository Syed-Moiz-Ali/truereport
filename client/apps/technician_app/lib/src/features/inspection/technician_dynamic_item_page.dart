import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_sheet.dart';
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';
import 'package:uuid/uuid.dart';

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
        loading: () => Column(
          children: [
            _SimpleBar(title: t(TechnicianKeys.technicianAssessmentState)),
            const Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.all(20),
                child: LoadingSkeleton(lines: 8),
              ),
            ),
          ],
        ),
        error: (error, _) => Column(
          children: [
            _SimpleBar(title: t(TechnicianKeys.technicianAssessmentState)),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ErrorState(
                      title: t(TechnicianKeys.error),
                      body: t(TechnicianKeys.technicianItemLoadFailed),
                      onRetry: () =>
                          ref.invalidate(technicianChecklistProvider(jobId)),
                      retryLabel: t(TechnicianKeys.retryAction),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        data: (checklist) {
          final item = checklist.item(itemCode);
          if (item == null) {
            return Column(
              children: [
                _SimpleBar(title: t(TechnicianKeys.technicianAssessmentState)),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: EmptyState(
                          title: t(TechnicianKeys.technicianItemNotFoundTitle),
                          body: t(TechnicianKeys.technicianItemNotFound),
                          icon: Icons.search_off,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _AssessmentTopBar(checklist: checklist),
              Expanded(
                child: _AssessmentForm(
                  key: ValueKey(
                    '$jobId-${item.itemCode}-${item.assessment?.version ?? 0}',
                  ),
                  jobId: jobId,
                  item: item,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AssessmentTopBar extends StatelessWidget {
  const _AssessmentTopBar({required this.checklist});

  final Checklist checklist;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final job = checklist.job;
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
      if (job.vehicleYear != null) '${job.vehicleYear}',
    ].where((value) => value.isNotEmpty).join(' ');
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 6),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.onSurface,
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
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: context.texts.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.outline),
                          ),
                          child: Text(
                            job.vehiclePlate ?? job.reference,
                            style: context.texts.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: UiStrings.of(context)(
                  TechnicianKeys.technicianItemsAssessed,
                  {'done': checklist.completed, 'total': checklist.total},
                ),
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleBar extends StatelessWidget {
  const _SimpleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Text(
              title,
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentForm extends ConsumerStatefulWidget {
  const _AssessmentForm({required this.jobId, required this.item, super.key});
  final String jobId;
  final ChecklistItem item;
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

  Future<void> _save(List<Evidence> evidence) async {
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
    final canSave = !_saving && _formValid(evidence);
    final upload = _queue.state.value;
    final stage = _evidenceStage(t, upload, evidenceOk);
    final requiredType = requirement.requiredEvidenceType;
    final requiredCount = requiredType == null
        ? 1
        : requirement.countFor(
            requiredType,
            photos: photos,
            videos: videos,
            documents: documents,
          );
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 32),
          children: [
            _ItemHeader(item: item, result: _result),
            const SizedBox(height: 12),
            if (_error != null) ...[
              _InlineBanner(message: _error!, tone: StatusTone.danger),
              const SizedBox(height: 8),
            ],
            if (_saved) ...[
              StatusChip(
                label: t(TechnicianKeys.technicianItemSaved),
                tone: StatusTone.success,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 8),
            ],
            _Section(
              title: t(TechnicianKeys.technicianResult),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResultChoices(
                    codes: item.resultOptions,
                    selected: _result,
                    onSelect: _selectResult,
                  ),
                  if (_result == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      t(TechnicianKeys.technicianSelectResult),
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_suggestedResult != null) ...[
                    SizedBox(height: context.spacing.xs),
                    Text(
                      '${t(TechnicianKeys.technicianSuggestedResult)}: '
                      '${resultLabel(resultRecords, _suggestedResult!)}'
                      '${_suggestedScore == null ? '' : ' Â· ${t(TechnicianKeys.technicianScore)} $_suggestedScore'}',
                      style: context.texts.bodyMedium,
                    ),
                  ],
                  if (_fieldErrors['resultCode'] != null)
                    _InlineError(
                      message: _fieldErrors['resultCode']!.messageFor(language),
                    ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sm),
            if (item.measurementUnit != null ||
                item.measurementBands.isNotEmpty)
              _Section(
                title: t(TechnicianKeys.technicianMeasurement),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final index in _measurementIndexes) ...[
                      AppTextField(
                        controller: _measurements[index]!,
                        label: index == null
                            ? t(TechnicianKeys.technicianMeasurement)
                            : '${t(TechnicianKeys.technicianMeasurement)} Â· $index',
                        labelAbove: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        suffixText: _measurementUnit,
                        errorText:
                            _showValidation &&
                                _measurementRequired &&
                                _measurementFor(index) == null
                            ? t(TechnicianKeys.technicianMeasurementRequired)
                            : _measurementError(index, language),
                      ),
                      SizedBox(height: context.spacing.sm),
                    ],
                  ],
                ),
              ),
            SizedBox(height: context.spacing.sm),
            if (_selectedScoreBand != null)
              _Section(
                title: t(TechnicianKeys.technicianScoreOverride),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _score,
                      label: t(TechnicianKeys.technicianScore),
                      labelAbove: true,
                      keyboardType: TextInputType.number,
                      enabled: _selectedScoreBand != null,
                      helperText: _selectedScoreBand == null
                          ? null
                          : t(TechnicianKeys.technicianScoreHint, {
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
                  ],
                ),
              ),
            if (item.issueFields.isNotEmpty) ...[
              SizedBox(height: context.spacing.sm),
              _Section(
                title: t(TechnicianKeys.technicianIssueDetails),
                subtitle: t(TechnicianKeys.technicianIssueDetailsHint),
                child: _IssueFields(
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
              ),
            ],
            if (item.allowFreeTextNote) ...[
              SizedBox(height: context.spacing.sm),
              _Section(
                title: t(TechnicianKeys.technicianNotes),
                subtitle: requirement.minNotesChars > 0
                    ? t(TechnicianKeys.technicianNotesHint, {
                        'count': requirement.minNotesChars,
                      })
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _notesEn,
                      label: t(TechnicianKeys.technicianCaptionsEn),
                      labelAbove: true,
                      maxLines: 3,
                    ),
                    SizedBox(height: context.spacing.sm),
                    AppTextField(
                      controller: _notesAr,
                      label: t(TechnicianKeys.technicianCaptionsAr),
                      labelAbove: true,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.spacing.sm),
            _Section(
              title: t(TechnicianKeys.technicianEvidence),
              subtitle: t(TechnicianKeys.technicianEvidenceCounts),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      StatusChip(
                        label: stage.label,
                        tone: stage.tone,
                        icon: stage.icon,
                      ),
                      if (upload.stage == EvidenceUploadStage.uploading) ...[
                        SizedBox(width: context.spacing.xs),
                        Text(
                          t(TechnicianKeys.technicianEvidenceAttempt, {
                            'attempt': upload.attempt,
                            'max': EvidenceUploadQueue.maxAttempts,
                          }),
                          style: context.texts.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: context.spacing.xs),
                  Wrap(
                    spacing: context.spacing.xs,
                    runSpacing: context.spacing.xs,
                    children: [
                      StatusChip(
                        label: t(TechnicianKeys.technicianEvidencePhotoCount, {
                          'count': photos,
                          'required': requirement.minPhotos,
                        }),
                        tone: photos >= requirement.minPhotos
                            ? StatusTone.success
                            : StatusTone.warning,
                        icon: Icons.photo_camera_outlined,
                      ),
                      StatusChip(
                        label: t(TechnicianKeys.technicianEvidenceVideoCount, {
                          'count': videos,
                          'required': requirement.minVideos,
                        }),
                        tone: videos >= requirement.minVideos
                            ? StatusTone.success
                            : StatusTone.warning,
                        icon: Icons.videocam_outlined,
                      ),
                      if (requirement.requiresDocument)
                        StatusChip(
                          label: t(
                            TechnicianKeys.technicianEvidenceDocumentCount,
                            {'count': documents, 'required': 1},
                          ),
                          tone: documents > 0
                              ? StatusTone.success
                              : StatusTone.warning,
                          icon: Icons.description_outlined,
                        ),
                    ],
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(
                    evidenceOk
                        ? t(TechnicianKeys.technicianEvidenceSatisfied)
                        : t(TechnicianKeys.technicianEvidenceRequired),
                    style: context.texts.bodySmall?.copyWith(
                      color: evidenceOk
                          ? context.statusColors.success.foreground
                          : context.statusColors.warning.foreground,
                    ),
                  ),
                  if (requiredType != null && requiredCount == 0) ...[
                    SizedBox(height: context.spacing.xs),
                    _InlineError(
                      message: t(
                        TechnicianKeys.technicianEvidenceTypeRequired,
                        {
                          'type': evidenceTypeLabel(
                            evidenceTypes,
                            requiredType,
                          ),
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: context.spacing.sm),
                  Wrap(
                    spacing: context.spacing.sm,
                    runSpacing: context.spacing.sm,
                    children: [
                      AppButton(
                        label: t(TechnicianKeys.technicianCapturePhoto),
                        icon: Icons.photo_camera_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _queue.isBusy
                            ? null
                            : () => _captureEvidence('PHOTO'),
                      ),
                      AppButton(
                        label: t(TechnicianKeys.technicianCaptureVideo),
                        icon: Icons.videocam_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _queue.isBusy
                            ? null
                            : () => _captureEvidence('VIDEO'),
                      ),
                      AppButton(
                        label: t(TechnicianKeys.technicianCaptureDocument),
                        icon: Icons.description_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _queue.isBusy
                            ? null
                            : () => _captureEvidence('DOCUMENT'),
                      ),
                    ],
                  ),
                  if (upload.busy) ...[
                    SizedBox(height: context.spacing.sm),
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
                    if (upload.stage == EvidenceUploadStage.uploading) ...[
                      SizedBox(height: context.spacing.xxs),
                      LinearProgressIndicator(
                        value: upload.progress,
                        semanticsLabel: t(
                          TechnicianKeys.technicianUploadProgress,
                        ),
                      ),
                      SizedBox(height: context.spacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              upload.progress == null
                                  ? ''
                                  : t(
                                      TechnicianKeys.technicianEvidencePercent,
                                      {
                                        'percent': (upload.progress! * 100)
                                            .round(),
                                      },
                                    ),
                              style: context.texts.labelSmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          AppButton(
                            label: t(TechnicianKeys.technicianEvidenceCancel),
                            variant: AppButtonVariant.text,
                            onPressed: _cancelEvidence,
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (upload.stage == EvidenceUploadStage.queued) ...[
                    SizedBox(height: context.spacing.xs),
                    _InlineBanner(
                      message: t(TechnicianKeys.technicianEvidenceQueued),
                      tone: StatusTone.warning,
                    ),
                  ],
                  if (upload.stage == EvidenceUploadStage.failed &&
                      upload.failure == null) ...[
                    SizedBox(height: context.spacing.xs),
                    AppButton(
                      label: t(TechnicianKeys.technicianRetryUpload),
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.tonal,
                      onPressed: _retryEvidence,
                    ),
                  ],
                  if (_evidenceError != null) ...[
                    SizedBox(height: context.spacing.xs),
                    _InlineError(message: _evidenceError!),
                  ],
                  if (evidence.isNotEmpty) ...[
                    SizedBox(height: context.spacing.sm),
                    for (final value in evidence) ...[
                      _EvidenceRow(
                        evidence: value,
                        onDelete: () => _deleteEvidence(value),
                      ),
                      SizedBox(height: context.spacing.xs),
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: context.spacing.lg),
            AppButton(
              label: t(TechnicianKeys.technicianSaveItem),
              icon: Icons.save_outlined,
              large: true,
              expand: true,
              isLoading: _saving,
              onPressed: canSave ? () => _save(evidence) : null,
            ),
            SizedBox(height: context.spacing.lg),
          ],
        ),
      ),
    );
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

class _ResultChoices extends ConsumerWidget {
  const _ResultChoices({
    required this.codes,
    required this.selected,
    required this.onSelect,
  });

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
    final resultRecords = ref.watch(enumsProvider('result')).value;
    final primary = [
      for (final code in _primary)
        if (codes.contains(code)) code,
    ];
    final rest = [
      for (final code in codes)
        if (!_primary.contains(code)) code,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var index = 0; index < primary.length; index++) ...[
              Expanded(
                child: _ResultTile(
                  code: primary[index],
                  label: resultLabel(resultRecords, primary[index]),
                  selected: selected == primary[index],
                  onTap: () => onSelect(primary[index]),
                ),
              ),
              if (index != primary.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final code in rest)
                AppFilterChip(
                  label: resultLabel(resultRecords, code),
                  selected: selected == code,
                  onSelected: (_) => onSelect(code),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({
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
    final resultRecords = ref.watch(enumsProvider('result')).value;
    final pair = context.statusColors.forTone(resultTone(resultRecords, code));
    final colors = context.colors;
    final icon = switch (code) {
      'NO_ISSUE_OBSERVED' => Icons.check_rounded,
      'ATTENTION_RECOMMENDED' => Icons.priority_high_rounded,
      'DEFECT_FOUND' => Icons.close_rounded,
      _ => Icons.circle_outlined,
    };
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
            color: selected ? pair.background : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? pair.foreground : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? pair.foreground : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: context.texts.labelSmall?.copyWith(
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

class _ItemHeader extends ConsumerWidget {
  const _ItemHeader({required this.item, required this.result});

  final ChecklistItem item;
  final String? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultRecords = ref.watch(enumsProvider('result')).value;
    final t = UiStrings.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final instruction = item.instructionFor(language);
    final spec = item.standardSpecFor(language);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.labelFor(language),
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: result == null
                    ? t(TechnicianKeys.notChecked)
                    : resultLabel(resultRecords, result!),
                tone: resultTone(resultRecords, result),
              ),
            ],
          ),
          if (instruction != null && instruction.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              instruction,
              style: context.texts.bodyMedium?.copyWith(
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
                      '${t(TechnicianKeys.technicianStandardSpec)}: $spec',
                      style: context.texts.bodySmall?.copyWith(
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
                StatusChip(
                  label: t(TechnicianKeys.technicianSafetyCritical),
                  tone: StatusTone.danger,
                  icon: Icons.health_and_safety_outlined,
                ),
              if (item.multiPoint)
                StatusChip(
                  label: t(TechnicianKeys.technicianMultiPoint),
                  tone: StatusTone.info,
                  icon: Icons.grid_on_outlined,
                ),
              if (item.measurementUnit != null)
                StatusChip(
                  label:
                      '${t(TechnicianKeys.technicianUnit)}: ${item.measurementUnit}',
                  tone: StatusTone.neutral,
                  icon: Icons.straighten,
                ),
              if (item.sensorTool != null && item.sensorTool!.isNotEmpty)
                StatusChip(
                  label:
                      '${t(TechnicianKeys.technicianTool)}: ${item.sensorTool}',
                  tone: StatusTone.neutral,
                  icon: Icons.handyman_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: context.texts.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.tone});
  final String message;
  final StatusTone tone;
  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Container(
      padding: EdgeInsetsDirectional.all(context.spacing.md),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Text(
        message,
        style: context.texts.bodySmall?.copyWith(color: pair.foreground),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: context.spacing.xxs),
      child: Text(
        message,
        style: context.texts.bodySmall?.copyWith(color: context.colors.error),
      ),
    );
  }
}

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
                        : option.labelFor(language),
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

class _EvidenceRow extends ConsumerWidget {
  const _EvidenceRow({required this.evidence, required this.onDelete});
  final Evidence evidence;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final caption = evidence.captionFor(language);
    final evidenceTypes = ref.watch(enumsProvider('evidence-type')).value;
    return Container(
      padding: EdgeInsetsDirectional.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Row(
        children: [
          Icon(
            evidence.isPhoto
                ? Icons.photo_outlined
                : evidence.isVideo
                ? Icons.videocam_outlined
                : Icons.description_outlined,
            color: context.brand.ink,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        evidenceTypeLabel(evidenceTypes, evidence.type),
                        style: context.texts.labelLarge,
                      ),
                    ),
                    StatusChip(
                      label: evidenceStatusLabel(ref, evidence.status),
                      tone: evidenceStatusTone(ref, evidence.status),
                    ),
                  ],
                ),
                if (caption != null && caption.isNotEmpty)
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            semanticLabel: t(TechnicianKeys.technicianDeleteEvidence),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
