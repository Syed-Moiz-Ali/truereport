import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/offline/photo_service.dart';
import 'package:technician_app/src/screens/f2b/defect_detail_view.dart';
import 'package:technician_app/src/technician_providers.dart';

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
    return checklist.when(
      loading: () => AppScaffold(
        appBar: AppBar(title: Text(l10n.result)),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
      ),
      error: (error, _) => AppScaffold(
        appBar: AppBar(title: Text(l10n.result)),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () =>
                  ref.invalidate(inspectionChecklistProvider(widget.jobId)),
              retryLabel: l10n.retryAction,
            ),
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
        return DefectDetailView(
          job: value.job,
          item: item,
          noteController: _note,
          selectedResult: _result,
          selectedSeverity: _severity,
          photos: _photos,
          busy: _busy,
          photoBusy: _photoBusy,
          finalized: value.job.status == 'FINALIZED',
          onResult: (result) => setState(() => _result = result),
          onSeverity: (severity) => setState(() => _severity = severity),
          onSave: () => _save(item),
          onAddPhoto: _addPhoto,
          onClose: () => context.pop(),
        );
      },
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
              title: Text(l10n.photoSourceCamera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photoSourceGallery),
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
            content: Text(pending == 0 ? l10n.itemSaved : l10n.savedOnPhone),
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
