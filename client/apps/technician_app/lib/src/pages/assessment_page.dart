import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/offline/photo_service.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class AssessmentPage extends ConsumerStatefulWidget {
  const AssessmentPage({required this.jobId, required this.itemId, super.key});

  final String jobId;
  final String itemId;

  @override
  ConsumerState<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends ConsumerState<AssessmentPage> {
  final _note = TextEditingController();
  final _reason = TextEditingController();
  final _photoService = PhotoService();
  String? _result;
  String? _severity;
  bool _initialized = false;
  bool _busy = false;
  bool _photoBusy = false;
  bool _guideLoaded = false;
  Uint8List? _guideImage;
  List<LocalEvidence> _photos = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPhotos);
  }

  @override
  void dispose() {
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checklist = ref.watch(inspectionChecklistProvider(widget.jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.result)),
      body: checklist.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () =>
                  ref.invalidate(inspectionChecklistProvider(widget.jobId)),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (value) {
          final item = _item(value);
          if (item == null) {
            return Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: EmptyState(title: l10n.error, body: l10n.noResults),
              ),
            );
          }
          _initialize(item);
          return _Form(
            item: item,
            note: _note,
            reason: _reason,
            result: _result,
            severity: _severity,
            busy: _busy,
            photoBusy: _photoBusy,
            photos: _photos,
            guideImage: _guideImage,
            onResult: (result) => setState(() => _result = result),
            onSeverity: (severity) => setState(() => _severity = severity),
            onSave: () => _save(item),
            onAddPhoto: _addPhoto,
          );
        },
      ),
    );
  }

  InspectionItem? _item(InspectionChecklist checklist) {
    for (final item in checklist.items) {
      if (item.inspectionItemId == widget.itemId) {
        return item;
      }
    }
    return null;
  }

  void _initialize(InspectionItem item) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final assessment = item.assessment;
    _result = assessment?.resultCode;
    _severity = assessment?.severityCode;
    _note.text = assessment?.note ?? '';
    _reason.text = assessment?.reasonText ?? assessment?.reasonCode ?? '';
    if (item.guideImageId != null && !_guideLoaded) {
      _guideLoaded = true;
      Future.microtask(_loadGuideImage);
    }
  }

  Future<void> _loadGuideImage() async {
    final store = ref.read(offlineStoreProvider);
    try {
      final cached = await store.loadGuideImage(widget.jobId, widget.itemId);
      if (cached != null) {
        if (mounted) {
          setState(() => _guideImage = cached.bytes);
        }
        return;
      }
      final bytes = await ref
          .read(technicianApiProvider)
          .guideImage(widget.jobId, widget.itemId);
      if (bytes.isNotEmpty) {
        final data = Uint8List.fromList(bytes);
        await store.cacheGuideImage(
          widget.jobId,
          widget.itemId,
          'image/jpeg',
          data,
        );
        if (mounted) {
          setState(() => _guideImage = data);
        }
      }
    } on Object {
      return;
    }
  }

  Future<void> _loadPhotos() async {
    final photos = await ref
        .read(offlineStoreProvider)
        .evidenceForItem(widget.jobId, widget.itemId);
    if (mounted) {
      setState(() => _photos = photos);
    }
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) {
      return;
    }
    setState(() => _photoBusy = true);
    try {
      final photo = await _photoService.capture(source);
      if (photo == null) {
        return;
      }
      if (photo.bytes.length > 8 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
        }
        return;
      }
      await ref
          .read(offlineStoreProvider)
          .queueEvidence(
            jobId: widget.jobId,
            itemId: widget.itemId,
            bytes: photo.bytes,
            mimeType: photo.mimeType,
            sha256: photo.sha256,
          );
      await ref.read(syncServiceProvider).syncAll();
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(pendingOperationsProvider);
      ref.invalidate(inspectionChecklistProvider(widget.jobId));
      ref.invalidate(inspectionReviewProvider(widget.jobId));
      await _loadPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.photoSaved)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  Future<void> _save(InspectionItem item) async {
    final l10n = AppLocalizations.of(context);
    if (_result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.assessmentRequired)));
      return;
    }
    final defect =
        _result == 'DEFECT_FOUND' || _result == 'ATTENTION_RECOMMENDED';
    final reasonRequired =
        _result == 'NOT_CHECKED' || _result == 'COULD_NOT_VERIFY';
    if (defect && (_severity == null || _severity!.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.severity)));
      return;
    }
    if (reasonRequired && _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reason)));
      return;
    }
    if (item.noteRequirement == 'REQUIRED' && _note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.note)));
      return;
    }
    setState(() => _busy = true);
    try {
      final existing = item.assessment;
      final body = <String, dynamic>{
        'baseVersion': existing?.version ?? 0,
        'clientRevision': (existing?.clientRevision ?? 0) + 1,
        'resultCode': _result,
        'severityCode': defect ? _severity : null,
        'note': _note.text,
        'reasonText': reasonRequired ? _reason.text : null,
      };
      final localAssessment = InspectionAssessment(
        id: existing?.id ?? 'local-${widget.itemId}',
        resultCode: _result!,
        severityCode: defect ? _severity : null,
        note: _note.text,
        noteLanguage: existing?.noteLanguage,
        reasonCode: existing?.reasonCode,
        reasonText: reasonRequired ? _reason.text : null,
        clientRevision: body['clientRevision'] as int,
        serverRevision: existing?.serverRevision ?? 0,
        version: existing?.version ?? 0,
      ).toJson();
      final store = ref.read(offlineStoreProvider);
      await store.saveAssessmentLocally(
        jobId: widget.jobId,
        itemId: widget.itemId,
        body: body,
        assessment: localAssessment,
      );
      await ref.read(syncServiceProvider).syncAll();
      final pending = await store.pendingCount();
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(pendingOperationsProvider);
      ref.invalidate(inspectionChecklistProvider(widget.jobId));
      ref.invalidate(inspectionReviewProvider(widget.jobId));
      ref.invalidate(technicianJobProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pending == 0 ? l10n.itemSaved : l10n.savedOnPhone,
            ),
          ),
        );
        context.pop();
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.item,
    required this.note,
    required this.reason,
    required this.result,
    required this.severity,
    required this.busy,
    required this.photoBusy,
    required this.photos,
    required this.guideImage,
    required this.onResult,
    required this.onSeverity,
    required this.onSave,
    required this.onAddPhoto,
  });

  final InspectionItem item;
  final TextEditingController note;
  final TextEditingController reason;
  final String? result;
  final String? severity;
  final bool busy;
  final bool photoBusy;
  final List<LocalEvidence> photos;
  final Uint8List? guideImage;
  final ValueChanged<String> onResult;
  final ValueChanged<String> onSeverity;
  final VoidCallback onSave;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defect =
        result == 'DEFECT_FOUND' || result == 'ATTENTION_RECOMMENDED';
    final reasonRequired =
        result == 'NOT_CHECKED' || result == 'COULD_NOT_VERIFY';
    final evidenceRequired =
        item.evidenceRequirement != 'NONE' || item.minPhotos > 0;
    return ListView(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      children: [
        SectionHeader(
          title: item.labelEn,
          subtitle: '${item.stableCode} - v${item.versionNo}',
        ),
        Text(item.instructionEn, style: context.texts.bodyMedium),
        SizedBox(height: context.spacing.md),
        if (evidenceRequired)
          StatusChip(
            label: l10n.evidenceRequirement,
            tone: StatusTone.warning,
            icon: Icons.photo_camera_outlined,
          ),
        if (guideImage != null) ...[
          SizedBox(height: context.spacing.lg),
          SectionHeader(title: l10n.guideImage),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              guideImage!,
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
        ],
        if (evidenceRequired) ...[
          SizedBox(height: context.spacing.lg),
          SectionHeader(title: l10n.attachments),
          if (photos.isEmpty)
            Text(l10n.photoRequired, style: context.texts.bodySmall),
          if (photos.isNotEmpty)
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: photos
                  .map(
                    (photo) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        photo.bytes,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  .toList(),
            ),
          SizedBox(height: context.spacing.sm),
          AppButton(
            label: l10n.addPhoto,
            onPressed: photoBusy ? null : onAddPhoto,
            isLoading: photoBusy,
            icon: Icons.add_a_photo_outlined,
            variant: AppButtonVariant.tonal,
            expand: true,
          ),
        ],
        SizedBox(height: context.spacing.lg),
        SectionHeader(title: l10n.result),
        Wrap(
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xs,
          children: item.resultOptions
              .map(
                (code) => AppSelectableText(
                  label: resultLabel(l10n, code),
                  selected: result == code,
                  onTap: () => onResult(code),
                ),
              )
              .toList(),
        ),
        if (defect) ...[
          SizedBox(height: context.spacing.lg),
          SectionHeader(title: l10n.severity),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: const ['MINOR', 'MODERATE', 'MAJOR', 'SAFETY_CRITICAL']
                .map(
                  (code) => AppSelectableText(
                    label: severityLabel(l10n, code),
                    selected: severity == code,
                    onTap: () => onSeverity(code),
                  ),
                )
                .toList(),
          ),
        ],
        SizedBox(height: context.spacing.lg),
        AppTextField(
          controller: note,
          label: l10n.note,
          maxLines: 3,
          helperText: l10n.keyboardHelp,
        ),
        if (reasonRequired || result == 'NOT_APPLICABLE') ...[
          SizedBox(height: context.spacing.sm),
          AppTextField(controller: reason, label: l10n.reason, maxLines: 2),
        ],
        SizedBox(height: context.spacing.xl),
        AppButton(
          label: l10n.saveAnswer,
          onPressed: busy ? null : onSave,
          isLoading: busy,
          icon: Icons.save_outlined,
          expand: true,
        ),
      ],
    );
  }
}
