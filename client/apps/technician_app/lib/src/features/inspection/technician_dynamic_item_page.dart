import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_sheet.dart';
import 'package:technician_app/src/inspection_models.dart';
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
    final l10n = AppLocalizations.of(context);
    final checklistAsync = ref.watch(technicianChecklistProvider(jobId));
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: checklistAsync.when(
        loading: () => Column(
          children: [
            _SimpleBar(title: l10n.technicianAssessmentState),
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
            _SimpleBar(title: l10n.technicianAssessmentState),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(20),
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () =>
                      ref.invalidate(technicianChecklistProvider(jobId)),
                  retryLabel: l10n.retryAction,
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
                _SimpleBar(title: l10n.technicianAssessmentState),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(20),
                    child: EmptyState(
                      title: l10n.technicianNoItems,
                      body: l10n.technicianNoItems,
                      icon: Icons.search_off,
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _AssessmentTopBar(checklist: checklist, item: item),
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
  const _AssessmentTopBar({required this.checklist, required this.item});

  final Checklist checklist;
  final ChecklistItem item;

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
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.labelFor(
                              Localizations.localeOf(context).languageCode,
                            ),
                            maxLines: 1,
                            style: context.texts.bodySmall?.copyWith(
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
  Map<String, ApiFieldError> _fieldErrors = {};
  String? _result;
  String? _error;
  String? _evidenceError;
  String? _uploadingType;
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

  @override
  void dispose() {
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

  String _booleanLabel(AppLocalizations l10n, String code) =>
      code == 'YES' ? l10n.commonYes : l10n.commonNo;
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

  bool _requiredFor(IssueField field) =>
      field.required || field.requiredForStatuses.contains(_result);
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
    final l10n = AppLocalizations.of(context);
    setState(() {
      _showValidation = true;
      _error = null;
      _fieldErrors = {};
    });
    if (!_formValid(evidence)) {
      setState(() => _error = l10n.technicianIssueFieldRequired);
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
      showAppSnackBar(context, message: l10n.technicianItemSaved);
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
        showAppSnackBar(context, message: l10n.technicianOfflineQueued);
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
              ? l10n.commonActionFailed
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
    final l10n = AppLocalizations.of(context);
    final request = await showEvidenceCaptureSheet(context, evidenceType: type);
    if (request == null || !mounted) {
      return;
    }
    setState(() {
      _uploadingType = type;
      _evidenceError = null;
    });
    CapturedEvidence? captured;
    try {
      captured = await _capture(type, request);
      if (captured == null) {
        if (mounted) {
          setState(() => _uploadingType = null);
        }
        return;
      }
      await _uploadEvidence(captured, request);
      ref.invalidate(
        technicianEvidenceListProvider((jobId: jobId, itemCode: item.itemCode)),
      );
      ref.invalidate(technicianChecklistProvider(jobId));
      if (!mounted) {
        return;
      }
      setState(() => _uploadingType = null);
    } on EvidenceCaptureException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadingType = null;
        _evidenceError = switch (error.failure) {
          EvidenceCaptureFailure.tooShort => l10n.technicianVideoTooShort,
          EvidenceCaptureFailure.tooLong => l10n.technicianVideoTooLong,
          EvidenceCaptureFailure.tooLarge => l10n.technicianFileTooLarge,
          EvidenceCaptureFailure.unavailable => l10n.technicianEvidenceFailed,
        };
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      if (isNetworkFailure(error) && captured != null) {
        await _queueCapturedEvidence(captured, request);
        if (!mounted) {
          return;
        }
        setState(() => _uploadingType = null);
        showAppSnackBar(context, message: l10n.technicianOfflineQueued);
      } else {
        final fields = fieldErrorsByCode(error);
        final lang = Localizations.localeOf(context).languageCode;
        final message = fields.values
            .map((value) => value.messageFor(lang))
            .where((value) => value.isNotEmpty)
            .join('\n');
        setState(() {
          _uploadingType = null;
          _evidenceError = message.isEmpty
              ? l10n.technicianEvidenceFailed
              : message;
        });
      }
    }
  }

  Future<CapturedEvidence?> _capture(
    String type,
    EvidenceCaptureRequest request,
  ) {
    return switch (type) {
      'PHOTO' => _service.capturePhoto(),
      'VIDEO' => _service.recordVideo(capturePoster: request.capturePoster),
      _ => _service.pickDocument(),
    };
  }

  Future<void> _uploadEvidence(
    CapturedEvidence captured,
    EvidenceCaptureRequest request,
  ) async {
    final api = ref.read(technicianApiProvider);
    final device = await DeviceIdentity.deviceId();
    final init = await api.cleanInitEvidence(
      jobId,
      item.itemCode,
      EvidenceInitRequest(
        type: captured.type,
        mime: captured.mime,
        bytes: captured.bytes.length,
        sha256: sha256Hex(captured.bytes),
        capturedAt: captured.capturedAt,
        captureSource: captured.captureSource,
        deviceId: device,
        width: captured.width,
        height: captured.height,
        durationMs: captured.durationMs,
        captionEn: request.captionEn,
        captionAr: request.captionAr,
        posterBase64: captured.posterBase64,
      ),
      idempotencyKey: 'evidence-${const Uuid().v7()}',
    );
    if (init.status != 'VERIFIED') {
      await api.uploadEvidenceContent(
        jobId,
        item.itemCode,
        init.id,
        captured.bytes,
        contentType: captured.mime,
      );
      await api.cleanCompleteEvidence(
        jobId,
        item.itemCode,
        init.id,
        EvidenceCompleteRequest(
          captionEn: request.captionEn,
          captionAr: request.captionAr,
          posterBase64: captured.posterBase64,
        ),
      );
    }
  }

  Future<void> _queueCapturedEvidence(
    CapturedEvidence captured,
    EvidenceCaptureRequest request,
  ) async {
    final l10n = AppLocalizations.of(context);
    final device = await DeviceIdentity.deviceId();
    await ref
        .read(offlineStoreProvider)
        .queueEvidence(
          jobId: jobId,
          itemId: item.itemCode,
          bytes: captured.bytes,
          mimeType: captured.mime,
          sha256: sha256Hex(captured.bytes),
          type: captured.type,
          captionEn: request.captionEn,
          captionAr: request.captionAr,
          posterBase64: captured.posterBase64,
          durationMs: captured.durationMs,
          captureSource: captured.captureSource,
          deviceId: device,
          width: captured.width,
          height: captured.height,
          clean: true,
        );
    ref.invalidate(syncQueueStatusProvider);
    if (mounted) {
      showAppSnackBar(context, message: l10n.technicianOfflineQueued);
    }
  }

  Future<void> _deleteEvidence(Evidence evidence) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.technicianDeleteEvidence,
      message: l10n.technicianDeleteEvidence,
      confirmLabel: l10n.commonConfirm,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(technicianApiProvider)
          .deleteEvidence(jobId, item.itemCode, evidence.id);
      ref.invalidate(
        technicianEvidenceListProvider((jobId: jobId, itemCode: item.itemCode)),
      );
      ref.invalidate(technicianChecklistProvider(jobId));
    } on Object {
      if (mounted) {
        setState(() => _evidenceError = l10n.technicianEvidenceFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final evidenceAsync = ref.watch(
      technicianEvidenceListProvider((jobId: jobId, itemCode: item.itemCode)),
    );
    final evidence = evidenceAsync.asData?.value ?? const <Evidence>[];
    final requirement = _evidenceRequirement;
    final photos = evidence.where((value) => value.isPhoto).length;
    final videos = evidence.where((value) => value.isVideo).length;
    final documents = evidence.where((value) => value.isDocument).length;
    final evidenceOk = _evidenceSatisfied(evidence);
    final canSave = !_saving && _formValid(evidence);
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
                label: l10n.technicianItemSaved,
                tone: StatusTone.success,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 8),
            ],
            _Section(
              title: l10n.technicianResult,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResultChoices(
                    codes: item.resultOptions,
                    selected: _result,
                    onSelect: _selectResult,
                    l10n: l10n,
                  ),
                  if (_result == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.technicianSelectResult,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_suggestedResult != null) ...[
                    SizedBox(height: context.spacing.xs),
                    Text(
                      '${l10n.technicianSuggestedResult}: '
                      '${resultLabel(l10n, _suggestedResult!)}'
                      '${_suggestedScore == null ? '' : ' Â· ${l10n.technicianScore} $_suggestedScore'}',
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
                title: l10n.technicianMeasurement,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final index in _measurementIndexes) ...[
                      AppTextField(
                        controller: _measurements[index]!,
                        label: index == null
                            ? l10n.technicianMeasurement
                            : '${l10n.technicianMeasurement} Â· $index',
                        labelAbove: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        suffixText: _measurementUnit,
                        errorText:
                            _showValidation &&
                                _measurementRequired &&
                                _measurementFor(index) == null
                            ? l10n.technicianMeasurementRequired
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
                title: l10n.technicianScoreOverride,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _score,
                      label: l10n.technicianScore,
                      labelAbove: true,
                      keyboardType: TextInputType.number,
                      enabled: _selectedScoreBand != null,
                      helperText: _selectedScoreBand == null
                          ? null
                          : l10n.technicianScoreHint(
                              _selectedScoreBand!.minScore,
                              _selectedScoreBand!.maxScore,
                            ),
                      errorText: !_scoreValid
                          ? l10n.technicianScoreOutOfRange(
                              _selectedScoreBand!.minScore,
                              _selectedScoreBand!.maxScore,
                            )
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
                title: l10n.technicianIssueDetails,
                subtitle: l10n.technicianIssueDetailsHint,
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
                title: l10n.technicianNotes,
                subtitle: requirement.minNotesChars > 0
                    ? l10n.technicianNotesHint(requirement.minNotesChars)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _notesEn,
                      label: l10n.technicianCaptionsEn,
                      labelAbove: true,
                      maxLines: 3,
                    ),
                    SizedBox(height: context.spacing.sm),
                    AppTextField(
                      controller: _notesAr,
                      label: l10n.technicianCaptionsAr,
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
              title: l10n.technicianEvidence,
              subtitle: l10n.technicianEvidenceCounts,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: context.spacing.xs,
                    runSpacing: context.spacing.xs,
                    children: [
                      StatusChip(
                        label: l10n.technicianEvidencePhotoCount(
                          photos,
                          requirement.minPhotos,
                        ),
                        tone: photos >= requirement.minPhotos
                            ? StatusTone.success
                            : StatusTone.warning,
                        icon: Icons.photo_camera_outlined,
                      ),
                      StatusChip(
                        label: l10n.technicianEvidenceVideoCount(
                          videos,
                          requirement.minVideos,
                        ),
                        tone: videos >= requirement.minVideos
                            ? StatusTone.success
                            : StatusTone.warning,
                        icon: Icons.videocam_outlined,
                      ),
                      if (requirement.requiresDocument)
                        StatusChip(
                          label: l10n.technicianEvidenceDocumentCount(
                            documents,
                            1,
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
                        ? l10n.technicianEvidenceSatisfied
                        : l10n.technicianEvidenceRequired,
                    style: context.texts.bodySmall?.copyWith(
                      color: evidenceOk
                          ? context.statusColors.success.foreground
                          : context.statusColors.warning.foreground,
                    ),
                  ),
                  SizedBox(height: context.spacing.sm),
                  Wrap(
                    spacing: context.spacing.sm,
                    runSpacing: context.spacing.sm,
                    children: [
                      AppButton(
                        label: l10n.technicianCapturePhoto,
                        icon: Icons.photo_camera_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _uploadingType == null
                            ? () => _captureEvidence('PHOTO')
                            : null,
                      ),
                      AppButton(
                        label: l10n.technicianCaptureVideo,
                        icon: Icons.videocam_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _uploadingType == null
                            ? () => _captureEvidence('VIDEO')
                            : null,
                      ),
                      AppButton(
                        label: l10n.technicianCaptureDocument,
                        icon: Icons.description_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _uploadingType == null
                            ? () => _captureEvidence('DOCUMENT')
                            : null,
                      ),
                    ],
                  ),
                  if (_uploadingType != null) ...[
                    SizedBox(height: context.spacing.sm),
                    Text(
                      l10n.technicianEvidenceUploading(
                        evidenceTypeLabel(l10n, _uploadingType!),
                      ),
                      style: context.texts.bodySmall,
                    ),
                    SizedBox(height: context.spacing.xxs),
                    const LinearProgressIndicator(semanticsLabel: null),
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
              label: l10n.technicianSaveItem,
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

class _ResultChoices extends StatelessWidget {
  const _ResultChoices({
    required this.codes,
    required this.selected,
    required this.onSelect,
    required this.l10n,
  });

  static const _primary = [
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
  ];

  final List<String> codes;
  final String? selected;
  final ValueChanged<String> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
                  label: switch (primary[index]) {
                    'NO_ISSUE_OBSERVED' => l10n.technicianResultNoIssue,
                    'ATTENTION_RECOMMENDED' => l10n.technicianResultAttention,
                    _ => l10n.technicianResultDefect,
                  },
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
                  label: resultLabel(l10n, code),
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

class _ResultTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(resultTone(code));
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
          height: 74,
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

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item, required this.result});

  final ChecklistItem item;
  final String? result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    ? l10n.notChecked
                    : resultLabel(l10n, result!),
                tone: resultTone(result),
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
                      '${l10n.technicianStandardSpec}: $spec',
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
                  label: l10n.technicianSafetyCritical,
                  tone: StatusTone.danger,
                  icon: Icons.health_and_safety_outlined,
                ),
              if (item.multiPoint)
                StatusChip(
                  label: l10n.technicianMultiPoint,
                  tone: StatusTone.info,
                  icon: Icons.grid_on_outlined,
                ),
              if (item.measurementUnit != null)
                StatusChip(
                  label: '${l10n.technicianUnit}: ${item.measurementUnit}',
                  tone: StatusTone.neutral,
                  icon: Icons.straighten,
                ),
              if (item.sensorTool != null && item.sensorTool!.isNotEmpty)
                StatusChip(
                  label: '${l10n.technicianTool}: ${item.sensorTool}',
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
  final String Function(AppLocalizations l10n, String code) booleanLabel;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                          ? l10n.technicianIssueFieldRequired
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
  final String Function(AppLocalizations l10n, String code) booleanLabel;
  final String? errorText;
  final ValueChanged<String> onOptionChanged;
  final void Function(String code, bool selected) onMultiChanged;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        ? booleanLabel(l10n, option.code)
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

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.evidence, required this.onDelete});
  final Evidence evidence;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final caption = evidence.captionFor(language);
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
                Text(
                  evidenceTypeLabel(l10n, evidence.type),
                  style: context.texts.labelLarge,
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
            semanticLabel: l10n.technicianDeleteEvidence,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
