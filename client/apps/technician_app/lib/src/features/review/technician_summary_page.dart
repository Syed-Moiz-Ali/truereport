import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/clean_conflict_panel.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';
import 'package:uuid/uuid.dart';

final technicianConflictsProvider = FutureProvider.autoDispose
    .family<List<SyncConflictRecord>, String>((ref, jobId) {
      return ref.watch(offlineStoreProvider).openConflicts(jobId: jobId);
    });

class TechnicianSummaryPage extends ConsumerStatefulWidget {
  const TechnicianSummaryPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<TechnicianSummaryPage> createState() =>
      _TechnicianSummaryPageState();
}

class _TechnicianSummaryPageState
    extends ConsumerState<TechnicianSummaryPage> {
  bool _completing = false;
  String? _error;
  List<Blocker> _completeBlockers = const [];
  bool _reloadedConflict = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(technicianSummaryProvider(widget.jobId));
    final reviewAsync = ref.watch(technicianReviewProvider(widget.jobId));
    final conflictsAsync = ref.watch(
      technicianConflictsProvider(widget.jobId),
    );
    return AppScaffold(
      backgroundColor: context.colors.surface,
      appBar: TechnicianAppBar(
        title: l10n.technicianSummaryTitle,
        showBack: true,
      ),
      body: summaryAsync.when(
        loading: () => const Padding(
          padding: EdgeInsetsDirectional.all(24),
          child: LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.gutter),
          child: ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () =>
                ref.invalidate(technicianSummaryProvider(widget.jobId)),
            retryLabel: l10n.retryAction,
          ),
        ),
        data: (summary) {
          final review = reviewAsync.asData?.value;
          final conflicts = conflictsAsync.asData?.value ?? const [];
          final blockers = _mergeBlockers(
            summary.blockers,
            review?.blockers ?? const [],
            _completeBlockers,
          );
          final warnings = _mergeBlockers(
            summary.warnings,
            review?.warnings ?? const [],
            const [],
          );
          final canComplete = !_completing &&
              blockers.isEmpty &&
              conflicts.isEmpty &&
              summary.itemsTotal > 0;
          return Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsetsDirectional.all(context.spacing.gutter),
                children: [
                  _SummaryCard(summary: summary),
                  SizedBox(height: context.spacing.md),
                  if (_error != null) ...[
                    _Banner(message: _error!, tone: StatusTone.danger),
                    SizedBox(height: context.spacing.sm),
                  ],
                  _BlockerCard(
                    title: l10n.technicianBlockers,
                    blockers: blockers,
                    tone: StatusTone.danger,
                  ),
                  SizedBox(height: context.spacing.md),
                  _BlockerCard(
                    title: l10n.technicianWarningsTitle,
                    blockers: warnings,
                    tone: StatusTone.warning,
                  ),
                  SizedBox(height: context.spacing.md),
                  ConflictPanel(
                    conflicts: [
                      for (final conflict in conflicts)
                        ConflictViewData(
                          id: conflict.id,
                          itemCode: conflict.itemCode,
                          clientPayload: conflict.clientPayloadJson,
                          serverPayload: conflict.serverPayloadJson,
                        ),
                    ],
                    reloaded: _reloadedConflict,
                    onReload: _reloadConflict,
                  ),
                  SizedBox(height: context.spacing.lg),
                  Wrap(
                    spacing: context.spacing.sm,
                    runSpacing: context.spacing.sm,
                    alignment: WrapAlignment.end,
                    children: [
                      AppButton(
                        key: const Key('summary-signature'),
                        label: l10n.technicianSignature,
                        icon: Icons.draw_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: () async {
                          await context.push(
                            '/jobs/${widget.jobId}/signature',
                          );
                          ref.invalidate(
                            technicianSummaryProvider(widget.jobId),
                          );
                          ref.invalidate(
                            technicianReviewProvider(widget.jobId),
                          );
                        },
                      ),
                      AppButton(
                        key: const Key('summary-complete'),
                        label: l10n.technicianCompleteInspection,
                        icon: Icons.check_circle_outline,
                        isLoading: _completing,
                        onPressed: canComplete ? _complete : null,
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Blocker> _mergeBlockers(
    List<Blocker> a,
    List<Blocker> b,
    List<Blocker> c,
  ) {
    final seen = <String>{};
    final merged = <Blocker>[];
    for (final blocker in [...a, ...b, ...c]) {
      final key = '${blocker.code}|${blocker.itemCode}|${blocker.messageEn}';
      if (seen.add(key)) {
        merged.add(blocker);
      }
    }
    return merged;
  }

  Future<void> _reloadConflict(ConflictViewData conflict) async {
    final l10n = AppLocalizations.of(context);
    final id = conflict.id;
    if (id != null) {
      await ref.read(offlineStoreProvider).resolveConflict(id);
    }
    ref.invalidate(technicianConflictsProvider(widget.jobId));
    ref.invalidate(technicianChecklistProvider(widget.jobId));
    ref.invalidate(technicianSummaryProvider(widget.jobId));
    ref.invalidate(technicianReviewProvider(widget.jobId));
    if (mounted) {
      setState(() => _reloadedConflict = true);
      showAppSnackBar(context, message: l10n.technicianConflictReloaded);
    }
  }

  Future<void> _complete() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      final result = await ref.read(technicianApiProvider).completeJob(
            widget.jobId,
            CompleteRequest(
              clientRevision: DateTime.now().millisecondsSinceEpoch,
            ),
            idempotencyKey: const Uuid().v7(),
          );
      if (!mounted) {
        return;
      }
      if (result.blockers.isNotEmpty) {
        setState(() {
          _completing = false;
          _completeBlockers = result.blockers;
          _error = l10n.technicianConflictExists;
        });
        return;
      }
      ref.invalidate(technicianSummaryProvider(widget.jobId));
      ref.invalidate(technicianReviewProvider(widget.jobId));
      ref.invalidate(technicianJobSummaryProvider(widget.jobId));
      ref.invalidate(technicianJobPageProvider);
      setState(() => _completing = false);
      context.go('/jobs/${widget.jobId}/completed');
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _completing = false;
        _error = l10n.commonActionFailed;
      });
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TechnicianSectionTitle(
            title: l10n.technicianSummaryTitle,
            trailing: StatusChip(
              label: technicianStatusLabel(l10n, summary.status),
              tone: technicianStatusTone(summary.status),
            ),
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.lg,
            runSpacing: context.spacing.md,
            children: [
              TechnicianLabeledValue(
                label: l10n.technicianDraftScore,
                value: summary.score?.toString() ?? l10n.notAvailable,
                emphasized: true,
              ),
              TechnicianLabeledValue(
                label: l10n.technicianGrade,
                value: summary.gradeCode ?? l10n.notAvailable,
                emphasized: true,
              ),
              TechnicianLabeledValue(
                label: l10n.technicianAssessmentProgress,
                value: l10n.technicianItemsAssessed(
                  summary.itemsAssessed,
                  summary.itemsTotal,
                ),
              ),
            ],
          ),
          if (summary.safetyCapApplied) ...[
            SizedBox(height: context.spacing.sm),
            _Banner(
              message:
                  '${l10n.technicianSafetyCap}: ${summary.safetyCapReason ?? ''}',
              tone: StatusTone.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockerCard extends StatelessWidget {
  const _BlockerCard({
    required this.title,
    required this.blockers,
    required this.tone,
  });

  final String title;
  final List<Blocker> blockers;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return AppCard(
      variant: AppCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TechnicianSectionTitle(
            title: title,
            trailing: StatusChip(
              label: '${blockers.length}',
              tone: blockers.isEmpty ? StatusTone.success : tone,
            ),
          ),
          if (blockers.isEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Text(
              l10n.technicianNoIssues,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ] else
            for (final blocker in blockers) ...[
              SizedBox(height: context.spacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: context.sizing.iconMd,
                    color: context.statusColors.forTone(tone).foreground,
                  ),
                  SizedBox(width: context.spacing.xs),
                  Expanded(
                    child: Text(
                      blocker.messageFor(language),
                      style: context.texts.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.tone});

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
