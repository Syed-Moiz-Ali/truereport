import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../inspection_models.dart';
import '../../technician_providers.dart';
import 'inspection_deck.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checklistAsync = ref.watch(technicianChecklistProvider(widget.jobId));
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: checklistAsync.when(
        loading: () => AppScaffold(
          appBar: TechnicianAppBar(
            title: l10n.technicianInspectionHub,
            showBack: true,
          ),
          body: const Padding(
            padding: EdgeInsetsDirectional.all(20),
            child: LoadingSkeleton(lines: 8),
          ),
        ),
        error: (error, _) => AppScaffold(
          appBar: TechnicianAppBar(
            title: l10n.technicianInspectionHub,
            showBack: true,
          ),
          body: Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () =>
                  ref.invalidate(technicianChecklistProvider(widget.jobId)),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
        data: (checklist) => InspectionDeck(
          checklist: checklist,
          jobId: widget.jobId,
          selectedCategory: _category,
          focusedItemCode: _focus,
          onCategory: (code) => setState(() {
            _category = code;
            _focus = null;
          }),
          onFocus: (item) => setState(() => _focus = item.itemCode),
          onOpen: _open,
          onSummary: () => context.push('/jobs/${widget.jobId}/summary'),
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
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
