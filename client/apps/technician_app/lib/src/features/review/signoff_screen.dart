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

/// The sign-off as three gates: inspect → sign → complete.
///
/// The screen exists to answer "what is still stopping this inspection?" and
/// to name the one next action, so the footer always advances the gate that is
/// actually open instead of only disabling a button.
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
    final language = Localizations.localeOf(context).languageCode;
    final summaryAsync = ref.watch(technicianSummaryProvider(widget.jobId));
    final reviewAsync = ref.watch(technicianReviewProvider(widget.jobId));
    final conflictsAsync = ref.watch(technicianConflictsProvider(widget.jobId));
    final jobReference = ref
        .watch(technicianJobSummaryProvider(widget.jobId))
        .asData
        ?.value
        .reference;

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: summaryAsync.when(
        loading: () => Column(
          children: [
            _ScreenBar(reference: (jobReference ?? '').trim()),
            const Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.all(20),
                child: LoadingSkeleton(lines: 7),
              ),
            ),
          ],
        ),
        error: (error, _) => Column(
          children: [
            _ScreenBar(reference: (jobReference ?? '').trim()),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(20),
                child: ErrorState(
                  title: t(TechnicianKeys.error),
                  body: t(TechnicianKeys.genericError),
                  onRetry: () =>
                      ref.invalidate(technicianSummaryProvider(widget.jobId)),
                  retryLabel: t(TechnicianKeys.retryAction),
                ),
              ),
            ),
          ],
        ),
        data: (summary) {
          final review = reviewAsync.asData?.value;
          final conflicts =
              conflictsAsync.asData?.value ?? const <SyncConflictRecord>[];
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
          final signatureBlocker = _signatureBlocker(blockers);
          final otherBlockers = [
            for (final blocker in blockers)
              if (!_isSignature(blocker)) blocker,
          ];
          final inspectBlockers = [
            for (final blocker in otherBlockers)
              if (blocker.itemCode != null && blocker.itemCode!.isNotEmpty)
                blocker,
          ];
          final itemsDone =
              summary.itemsTotal > 0 &&
              summary.itemsAssessed >= summary.itemsTotal;
          final inspectDone = itemsDone && inspectBlockers.isEmpty;
          final signed = signatureBlocker == null;
          final step = !inspectDone
              ? 1
              : !signed
              ? 2
              : 3;

          return Column(
            children: [
              _ScreenBar(
                reference: (jobReference ?? '').trim(),
                status: summary.status,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 20),
                  child: _Capped(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Stepper(
                          inspectDone: inspectDone,
                          inspectCaption: inspectBlockers.isNotEmpty
                              ? '${t(TechnicianKeys.technicianBlockers)} · ${inspectBlockers.length}'
                              : t(TechnicianKeys.technicianItemsAssessed, {
                                  'done': summary.itemsAssessed,
                                  'total': summary.itemsTotal,
                                }),
                          signDone: signed,
                          signCaption: signed
                              ? t(TechnicianKeys.technicianSignatureCaptured)
                              : signatureBlocker.messageFor(language),
                          completeDone: canComplete,
                          completeCurrent: !canComplete && signed,
                          completeCaption: canComplete
                              ? t(TechnicianKeys.technicianReadyToComplete)
                              : signed
                              ? '${t(TechnicianKeys.technicianBlockers)} · ${otherBlockers.length}'
                              : t(TechnicianKeys.technicianWaitingSignature),
                          onSign: _openSignature,
                          onInspect: () => Navigator.of(context).maybePop(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _Banner(message: _error!, tone: StatusTone.danger),
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
                        if (otherBlockers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _BlockingList(
                            title: t(TechnicianKeys.technicianAlsoBlocking),
                            blockers: otherBlockers,
                            tone: StatusTone.danger,
                            onOpen: _openBlocker,
                          ),
                        ],
                        if (warnings.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _NoteList(
                            title: t(TechnicianKeys.technicianWarningsTitle),
                            blockers: warnings,
                            tone: StatusTone.warning,
                          ),
                        ],
                        if (conflicts.isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                        ],
                        const SizedBox(height: 12),
                        _ScoreStrip(
                          summary: summary,
                          warnings: warnings.length,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _Footer(
                step: step,
                hint: step == 1
                    ? '${t(TechnicianKeys.technicianBlockers)} · ${inspectBlockers.length}'
                    : step == 2
                    ? t(TechnicianKeys.technicianSignToContinue)
                    : canComplete
                    ? t(TechnicianKeys.technicianReadyToComplete)
                    : '${t(TechnicianKeys.technicianBlockers)} · ${otherBlockers.length}',
                primaryLabel: step == 1
                    ? t(TechnicianKeys.technicianContinueChecklist)
                    : step == 2
                    ? t(TechnicianKeys.technicianSignNow)
                    : t(TechnicianKeys.technicianCompleteInspection),
                primaryIcon: step == 1
                    ? Icons.arrow_back_rounded
                    : step == 2
                    ? Icons.draw_outlined
                    : Icons.check_rounded,
                completing: _completing,
                enabled: step == 1
                    ? true
                    : step == 2
                    ? true
                    : canComplete,
                onPressed: step == 1
                    ? () => Navigator.of(context).maybePop()
                    : step == 2
                    ? _openSignature
                    : _complete,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSignature(Blocker blocker) => blocker.code == 'SIGNATURE_MISSING';

  Blocker? _signatureBlocker(List<Blocker> blockers) {
    for (final blocker in blockers) {
      if (_isSignature(blocker)) {
        return blocker;
      }
    }
    return null;
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

// ============================================================ presentation

class _Capped extends StatelessWidget {
  const _Capped({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: child,
      ),
    );
  }
}

class _ScreenBar extends ConsumerWidget {
  const _ScreenBar({required this.reference, this.status});

  final String reference;
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 16, 8),
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
                    child: Icon(Icons.arrow_back_rounded, size: 21),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t(TechnicianKeys.technicianSummaryTitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (status != null &&
                  MediaQuery.sizeOf(context).width >= 420) ...[
                StatusChip(
                  label: jobStatusLabel(ref, status!),
                  tone: jobStatusTone(ref, status!),
                ),
                const SizedBox(width: 8),
              ],
              if (reference.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    reference,
                    key: const Key('summary-job-reference'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: context.texts.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

/// Inspect → Sign → Complete. Each row is a gate with its own state.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.inspectDone,
    required this.inspectCaption,
    required this.signDone,
    required this.signCaption,
    required this.completeDone,
    required this.completeCurrent,
    required this.completeCaption,
    required this.onSign,
    required this.onInspect,
  });

  final bool inspectDone;
  final String inspectCaption;
  final bool signDone;
  final String signCaption;
  final bool completeDone;
  final bool completeCurrent;
  final String completeCaption;
  final VoidCallback onSign;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _StepRow(
            title: t(TechnicianKeys.technicianStepInspect),
            caption: inspectCaption,
            number: 1,
            state: inspectDone ? _GateState.done : _GateState.current,
            actionLabel: inspectDone
                ? null
                : t(TechnicianKeys.technicianContinueChecklist),
            onAction: inspectDone ? null : onInspect,
          ),
          Divider(height: 1, color: context.colors.outlineVariant, indent: 58),
          _StepRow(
            title: t(TechnicianKeys.technicianStepSign),
            caption: signCaption,
            number: 2,
            state: signDone ? _GateState.done : _GateState.current,
            actionLabel: signDone ? null : t(TechnicianKeys.technicianSignNow),
            onAction: signDone ? null : onSign,
          ),
          Divider(height: 1, color: context.colors.outlineVariant, indent: 58),
          _StepRow(
            title: t(TechnicianKeys.technicianStepComplete),
            caption: completeCaption,
            number: 3,
            state: completeDone
                ? _GateState.done
                : completeCurrent
                ? _GateState.current
                : _GateState.blocked,
          ),
        ],
      ),
    );
  }
}

enum _GateState { done, current, blocked }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.caption,
    required this.number,
    required this.state,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String caption;
  final int number;
  final _GateState state;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final (fg, bg) = switch (state) {
      _GateState.done => (
        context.statusColors.success.foreground,
        context.statusColors.success.background,
      ),
      _GateState.current => (
        context.statusColors.warning.foreground,
        context.statusColors.warning.background,
      ),
      _GateState.blocked => (colors.onSurfaceVariant, colors.surfaceContainer),
    };
    final icon = switch (state) {
      _GateState.done => Icons.check_rounded,
      _GateState.current => Icons.adjust_rounded,
      _GateState.blocked => Icons.lock_outline_rounded,
    };
    return Semantics(
      label: '$number. $title. $caption',
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 13, 12, 13),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$number. $title',
                    style: context.texts.titleSmall?.copyWith(
                      fontWeight: state == _GateState.blocked
                          ? FontWeight.w600
                          : FontWeight.w700,
                      color: state == _GateState.blocked
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (actionLabel != null)
              Semantics(
                button: true,
                label: actionLabel,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.brand.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        actionLabel!,
                        style: context.texts.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (state == _GateState.done)
              Text(
                t(TechnicianKeys.technicianGateDone),
                style: context.texts.labelSmall?.copyWith(
                  color: context.statusColors.success.foreground,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlockingList extends StatelessWidget {
  const _BlockingList({
    required this.title,
    required this.blockers,
    required this.tone,
    required this.onOpen,
  });

  final String title;
  final List<Blocker> blockers;
  final StatusTone tone;
  final ValueChanged<Blocker> onOpen;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _CountPill(
                value: blockers.length,
                fg: pair.foreground,
                bg: pair.background,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < blockers.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                child: Divider(height: 1, color: colors.outlineVariant),
              ),
            _BlockerRow(
              blocker: blockers[index],
              message: blockers[index].messageFor(language),
              tone: pair.foreground,
              background: pair.background,
              onTap: () => onOpen(blockers[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.title,
    required this.blockers,
    required this.tone,
  });

  final String title;
  final List<Blocker> blockers;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _CountPill(
                value: blockers.length,
                fg: pair.foreground,
                bg: pair.background,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < blockers.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                child: Divider(height: 1, color: colors.outlineVariant),
              ),
            _BlockerRow(
              blocker: blockers[index],
              message: blockers[index].messageFor(language),
              tone: pair.foreground,
              background: pair.background,
              onTap: null,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockerRow extends StatelessWidget {
  const _BlockerRow({
    required this.blocker,
    required this.message,
    required this.tone,
    required this.background,
    required this.onTap,
  });

  final Blocker blocker;
  final String message;
  final Color tone;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = blocker.itemCode == null || blocker.itemCode!.isEmpty
        ? null
        : blocker.itemCode;
    return Semantics(
      button: onTap != null,
      label: message,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                onTap == null
                    ? Icons.info_outline_rounded
                    : Icons.arrow_forward_rounded,
                size: 14,
                color: tone,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      meta,
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.value, required this.fg, required this.bg});

  final int value;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          '$value',
          style: context.texts.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.summary, required this.warnings});

  final Summary summary;
  final int warnings;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final score = summary.score?.toString() ?? t(TechnicianKeys.notAvailable);
    final grade = summary.gradeCode ?? t(TechnicianKeys.notAvailable);
    return _Panel(
      child: Row(
        children: [
          _Stat(value: score, label: t(TechnicianKeys.technicianDraftScore)),
          const SizedBox(width: 28),
          _Stat(value: grade, label: t(TechnicianKeys.technicianGradeLabel)),
          const Spacer(),
          if (warnings > 0)
            StatusChip(
              label: '${t(TechnicianKeys.technicianWarningsTitle)} · $warnings',
              tone: StatusTone.warning,
              icon: Icons.info_outline_rounded,
            )
          else
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.texts.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.hint,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.completing,
    required this.enabled,
    required this.onPressed,
  });

  final int step;
  final String hint;
  final String primaryLabel;
  final IconData primaryIcon;
  final bool completing;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(TechnicianKeys.technicianStepOf, {
                        'step': step,
                        'total': 3,
                      }).toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PrimaryAction(
                label: primaryLabel,
                icon: primaryIcon,
                saving: completing,
                enabled: enabled && !completing,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.saving,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool saving;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: 48,
        child: Material(
          color: enabled
              ? context.brand.ink
              : context.brand.ink.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (saving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (!saving) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.tone});

  final String message;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 15, color: pair.foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall?.copyWith(
                  color: pair.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
