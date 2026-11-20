import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/clean_conflict_panel.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:uuid/uuid.dart';

final technicianConflictsProvider = FutureProvider.autoDispose
    .family<List<SyncConflictRecord>, String>((ref, jobId) {
      return ref.watch(offlineStoreProvider).openConflicts(jobId: jobId);
    });

/// Pure completion gate: a summary blocker or an open conflict always wins.
@visibleForTesting
bool technicianCanComplete({
  required bool completing,
  required List<Blocker> blockers,
  required int conflicts,
  required int itemsTotal,
}) => !completing && blockers.isEmpty && conflicts == 0 && itemsTotal > 0;

/// Where a blocker sends the technician. Kept pure so the gating contract is
/// pinned without booting a router.
@visibleForTesting
String? technicianBlockerRoute(String jobId, Blocker blocker) {
  if (blocker.code == 'SIGNATURE_MISSING') {
    return '/jobs/$jobId/signature';
  }
  if (blocker.code == 'SYNC_CONFLICT') {
    return '/sync';
  }
  final itemCode = blocker.itemCode;
  if (itemCode == null || itemCode.isEmpty) {
    return null;
  }
  return '/jobs/$jobId/items/${Uri.encodeComponent(itemCode)}';
}

/// The handover dossier: grade stamp, blockers and warnings, one sign-off bar.
class TechnicianSummaryPage extends ConsumerStatefulWidget {
  const TechnicianSummaryPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<TechnicianSummaryPage> createState() =>
      _TechnicianSummaryPageState();
}

class _TechnicianSummaryPageState extends ConsumerState<TechnicianSummaryPage> {
  bool _completing = false;
  String? _error;
  List<Blocker> _completeBlockers = const [];
  bool _reloadedConflict = false;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final summaryAsync = ref.watch(technicianSummaryProvider(widget.jobId));
    final reviewAsync = ref.watch(technicianReviewProvider(widget.jobId));
    final conflictsAsync = ref.watch(technicianConflictsProvider(widget.jobId));
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _SummaryBar(title: t(TechnicianKeys.technicianSummaryTitle)),
          Expanded(
            child: summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsetsDirectional.all(20),
                child: LoadingSkeleton(lines: 7),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsetsDirectional.all(20),
                child: ErrorState(
                  title: t(TechnicianKeys.error),
                  body: t(TechnicianKeys.genericError),
                  onRetry: () =>
                      ref.invalidate(technicianSummaryProvider(widget.jobId)),
                  retryLabel: t(TechnicianKeys.retryAction),
                ),
              ),
              data: (summary) {
                final review = reviewAsync.asData?.value;
                final conflicts =
                    conflictsAsync.asData?.value ??
                    const <SyncConflictRecord>[];
                final blockers = _merge(
                  summary.blockers,
                  review?.blockers ?? const [],
                  _completeBlockers,
                );
                final warnings = _merge(
                  summary.warnings,
                  review?.warnings ?? const [],
                  const [],
                );
                final canComplete = technicianCanComplete(
                  completing: _completing,
                  blockers: blockers,
                  conflicts: conflicts.length,
                  itemsTotal: summary.itemsTotal,
                );
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          0,
                          16,
                          20,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ScoreHero(summary: summary, t: t),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  _Banner(
                                    message: _error!,
                                    tone: StatusTone.danger,
                                  ),
                                ],
                                if (summary.safetyCapApplied) ...[
                                  const SizedBox(height: 12),
                                  _Banner(
                                    message:
                                        '${t(TechnicianKeys.technicianSafetyCap)}: '
                                        '${summary.safetyCapReason ?? ''}',
                                    tone: StatusTone.warning,
                                  ),
                                ],
                                const SizedBox(height: 18),
                                _IssueSection(
                                  title: t(TechnicianKeys.technicianBlockers),
                                  blockers: blockers,
                                  emptyLabel: t(
                                    TechnicianKeys.technicianNoIssues,
                                  ),
                                  tone: StatusTone.danger,
                                  emptyTone: StatusTone.success,
                                  onOpen: _openBlocker,
                                ),
                                const SizedBox(height: 12),
                                _IssueSection(
                                  title: t(
                                    TechnicianKeys.technicianWarningsTitle,
                                  ),
                                  blockers: warnings,
                                  emptyLabel: t(
                                    TechnicianKeys.technicianNoIssues,
                                  ),
                                  tone: StatusTone.warning,
                                  emptyTone: StatusTone.success,
                                ),
                                if (conflicts.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ConflictPanel(
                                    conflicts: [
                                      for (final conflict in conflicts)
                                        ConflictViewData(
                                          id: conflict.id,
                                          itemCode: conflict.itemCode,
                                          clientPayload:
                                              conflict.clientPayloadJson,
                                          serverPayload:
                                              conflict.serverPayloadJson,
                                        ),
                                    ],
                                    reloaded: _reloadedConflict,
                                    onReload: _reloadConflict,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ActionBar(
                      signatureLabel: t(TechnicianKeys.technicianSignature),
                      completeLabel: t(
                        TechnicianKeys.technicianCompleteInspection,
                      ),
                      completing: _completing,
                      canComplete: canComplete,
                      onSignature: _openSignature,
                      onComplete: _complete,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSignature() async {
    await context.push('/jobs/${widget.jobId}/signature');
    ref.invalidate(technicianSummaryProvider(widget.jobId));
    ref.invalidate(technicianReviewProvider(widget.jobId));
  }

  List<Blocker> _merge(List<Blocker> a, List<Blocker> b, List<Blocker> c) {
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
    final t = UiStrings.of(context);
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
      showAppSnackBar(
        context,
        message: t(TechnicianKeys.technicianConflictReloaded),
      );
    }
  }

  Future<void> _openBlocker(Blocker blocker) async {
    final route = technicianBlockerRoute(widget.jobId, blocker);
    if (route == null) {
      return;
    }
    await context.push(route);
    if (!mounted) {
      return;
    }
    ref.invalidate(technicianSummaryProvider(widget.jobId));
    ref.invalidate(technicianReviewProvider(widget.jobId));
    ref.invalidate(technicianChecklistProvider(widget.jobId));
  }

  Future<void> _complete() async {
    final t = UiStrings.of(context);
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      final fresh = await ref.read(technicianApiProvider).summary(widget.jobId);
      if (!mounted) {
        return;
      }
      if (fresh.blockers.isNotEmpty) {
        setState(() {
          _completing = false;
          _completeBlockers = fresh.blockers;
          _error = t(TechnicianKeys.technicianCompleteBlocked);
        });
        return;
      }
      final result = await ref
          .read(technicianApiProvider)
          .completeJob(
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
          _error = t(TechnicianKeys.technicianCompleteBlocked);
        });
        return;
      }
      ref.invalidate(technicianSummaryProvider(widget.jobId));
      ref.invalidate(technicianReviewProvider(widget.jobId));
      ref.invalidate(technicianJobSummaryProvider(widget.jobId));
      ref.invalidate(technicianJobPageProvider);
      setState(() => _completing = false);
      context.go('/jobs/${widget.jobId}/completed');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final fields = ApiFieldError.fromFailure(error);
      if (fields.isNotEmpty) {
        setState(() {
          _completing = false;
          _completeBlockers = fields
              .map(
                (value) => Blocker(
                  code: value.code,
                  itemCode: value.field == value.code ? null : value.field,
                  messageEn: value.messageEn,
                  messageAr: value.messageAr,
                ),
              )
              .toList(growable: false);
          _error = t(TechnicianKeys.technicianCompleteBlocked);
        });
        return;
      }
      setState(() {
        _completing = false;
        _error = t(TechnicianKeys.commonActionFailed);
      });
    }
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
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

class _ScoreHero extends ConsumerWidget {
  const _ScoreHero({required this.summary, required this.t});

  final Summary summary;
  final UiStrings t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = summary.score?.toString() ?? t(TechnicianKeys.notAvailable);
    final grade = summary.gradeCode ?? t(TechnicianKeys.notAvailable);
    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: context.brand.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t(TechnicianKeys.technicianDraftScore).toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 26,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: context.statusColors
                                  .forTone(jobStatusTone(ref, summary.status))
                                  .foreground,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            jobStatusLabel(ref, summary.status),
                            style: context.texts.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  score,
                  style: context.texts.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -1.5,
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(TechnicianKeys.technicianItemsAssessed, {
                    'done': summary.itemsAssessed,
                    'total': summary.itemsTotal,
                  }),
                  style: context.texts.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  grade,
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t(TechnicianKeys.technicianGrade).toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueSection extends StatelessWidget {
  const _IssueSection({
    required this.title,
    required this.blockers,
    required this.emptyLabel,
    required this.tone,
    required this.emptyTone,
    this.onOpen,
  });

  final String title;
  final List<Blocker> blockers;
  final String emptyLabel;
  final StatusTone tone;
  final StatusTone emptyTone;
  final ValueChanged<Blocker>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final pair = context.statusColors.forTone(
      blockers.isEmpty ? emptyTone : tone,
    );
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.texts.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: pair.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      '${blockers.length}',
                      style: context.texts.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: pair.foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (blockers.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 14),
              child: Text(
                emptyLabel,
                style: context.texts.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < blockers.length; index++) ...[
              if (index != 0)
                Divider(
                  height: 1,
                  color: colors.outlineVariant,
                  indent: 16,
                  endIndent: 16,
                ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
                child: InkWell(
                  onTap: onOpen == null ? null : () => onOpen!(blockers[index]),
                  borderRadius: BorderRadius.circular(8),
                  child: Semantics(
                    button: onOpen != null,
                    label: blockers[index].messageFor(language),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: pair.foreground,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            blockers[index].messageFor(language),
                            style: context.texts.bodyMedium,
                          ),
                        ),
                        if (onOpen != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: pair.foreground,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.signatureLabel,
    required this.completeLabel,
    required this.completing,
    required this.canComplete,
    required this.onSignature,
    required this.onComplete,
  });

  final String signatureLabel;
  final String completeLabel;
  final bool completing;
  final bool canComplete;
  final VoidCallback onSignature;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: signatureLabel,
                  icon: Icons.draw_outlined,
                  variant: _PillVariant.ghost,
                  onPressed: onSignature,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillButton(
                  label: completeLabel,
                  icon: Icons.check_rounded,
                  variant: _PillVariant.primary,
                  loading: completing,
                  onPressed: canComplete ? onComplete : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PillVariant { primary, ghost }

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.variant,
    this.icon,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final _PillVariant variant;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (variant) {
      _PillVariant.primary => (context.brand.ink, Colors.white, null),
      _PillVariant.ghost => (
        Colors.transparent,
        context.colors.onSurface,
        context.colors.outlineVariant,
      ),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else ...[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: enabled ? fg : fg.withValues(alpha: 0.7),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? fg : fg.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ],
          ),
        ),
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
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: context.texts.bodySmall?.copyWith(color: pair.foreground),
      ),
    );
  }
}
