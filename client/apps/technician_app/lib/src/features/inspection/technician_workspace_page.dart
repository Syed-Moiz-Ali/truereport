import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';

import '../../inspection_models.dart';
import '../../technician_providers.dart';
import 'inspection_deck.dart';
import 'vehicle_photo_gate.dart';

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
              ? _deck(checklist, null, showBanner: false)
              : _photoLoading(context, t),
          // A photo-service failure never blocks the inspection; the banner
          // stays available so the technician can retry explicitly.
          error: (error, _) => _deck(checklist, null, showBanner: true),
          data: (photo) {
            if (_photoPromptOpen) {
              return _gate(context, t);
            }
            if (photo == null) {
              if (!completed && !_continuedWithoutPhoto) {
                return _gate(context, t);
              }
              return _deck(checklist, null, showBanner: true);
            }
            return _deck(checklist, photo, showBanner: false);
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

  Widget _deck(
    Checklist checklist,
    VehiclePhoto? photo, {
    required bool showBanner,
  }) {
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: InspectionDeck(
        checklist: checklist,
        jobId: widget.jobId,
        selectedCategory: _category,
        focusedItemCode: _focus,
        banner: showBanner
            ? VehiclePhotoBanner(
                onAdd: () => setState(() => _photoPromptOpen = true),
              )
            : null,
        headerTrailing: photo == null
            ? null
            : VehiclePhotoThumb(jobId: widget.jobId, onRetake: _retakePhoto),
        onCategory: (code) => setState(() {
          _category = code;
          _focus = null;
        }),
        onFocus: (item) => setState(() => _focus = item.itemCode),
        onOpen: _open,
        onSummary: () => context.push('/jobs/${widget.jobId}/summary'),
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
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
