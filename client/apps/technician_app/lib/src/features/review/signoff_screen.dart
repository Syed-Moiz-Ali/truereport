import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/clean_conflict_panel.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:uuid/uuid.dart';

import '../../reference_ui.dart';
import '../jobs/queue/jobs_queue_format.dart';
import '../jobs/queue/queue_model.dart';
import 'fieldwork/review_ui.dart';

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

/// Where a blocker sends the technician. Kept pure so the routing contract is
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

/// The sign-off as an inspect → blockers → sign → complete gate in the deck
/// language.
///
/// The screen answers "what is still stopping this inspection?" and names the
/// one next fix, so the footer always advances the gate that is actually
/// open instead of only disabling a button.
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
    final job = ref
        .watch(technicianJobSummaryProvider(widget.jobId))
        .asData
        ?.value;
    final online = ref.watch(connectivityProvider).value ?? true;
    final readOnly = job == null ? true : verbFor(job) == QueueVerb.view;

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: summaryAsync.when(
        loading: () => Column(
          children: [
            ReviewBackBar(onBack: () => Navigator.of(context).maybePop()),
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
            ReviewBackBar(onBack: () => Navigator.of(context).maybePop()),
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
          final canComplete =
              !readOnly &&
              technicianCanComplete(
                completing: _completing,
                blockers: blockers,
                conflicts: conflicts.length,
                itemsTotal: summary.itemsTotal,
              );
          final signature = _signatureBlocker(blockers);
          final inspectBlockers = [
            for (final blocker in blockers)
              if (!_isSignature(blocker) &&
                  !_isSync(blocker) &&
                  blocker.itemCode != null &&
                  blocker.itemCode!.isNotEmpty)
                blocker,
          ];
          final syncRows = [
            for (final blocker in blockers)
              if (!_isSignature(blocker) &&
                  (blocker.itemCode == null || blocker.itemCode!.isEmpty))
                blocker,
          ];
          final ordered = <Blocker>[...inspectBlockers, ...syncRows];
          if (signature != null) {
            ordered.add(signature);
          }
          final hasSyncIssue = conflicts.isNotEmpty || syncRows.isNotEmpty;
          final showScore =
              summary.score != null ||
              summary.gradeCode != null ||
              summary.safetyCapApplied;

          final String primaryLabel;
          final VoidCallback? primaryAction;
          if (readOnly) {
            primaryLabel = t(TechnicianKeys.commonBack);
            primaryAction = () => Navigator.of(context).maybePop();
          } else if (canComplete) {
            primaryLabel = t(TechnicianKeys.technicianSummaryComplete);
            primaryAction = _complete;
          } else if (inspectBlockers.isNotEmpty) {
            primaryLabel = t(TechnicianKeys.technicianSummaryReviewItems, {
              'count': inspectBlockers.length,
            });
            primaryAction = () => _openBlocker(inspectBlockers.first);
          } else if (hasSyncIssue) {
            primaryLabel = t(TechnicianKeys.technicianSummaryResolveConflicts);
            primaryAction = () => context.push('/sync');
          } else if (signature != null) {
            primaryLabel = t(TechnicianKeys.technicianSummaryAddSignature);
            primaryAction = _openSignature;
          } else {
            primaryLabel = t(TechnicianKeys.technicianSummaryComplete);
            primaryAction = null;
          }
          final secondaryLabel =
              !readOnly &&
                  signature != null &&
                  (inspectBlockers.isNotEmpty || hasSyncIssue)
              ? t(TechnicianKeys.technicianSignature)
              : null;

          final status = (job?.status ?? summary.status).trim();
          final scoreData = showScore
              ? ReviewScoreData(
                  score: summary.score,
                  grade: summary.gradeCode,
                  capApplied: summary.safetyCapApplied,
                  capReason: summary.safetyCapReason ?? '',
                  scoreLabel: t(TechnicianKeys.technicianDraftScore),
                  gradeLabel: t(TechnicianKeys.technicianGradeLabel),
                  capLabel: t(TechnicianKeys.technicianSafetyCap),
                  capAppliedLabel: t(
                    TechnicianKeys.technicianSummaryCapApplied,
                  ),
                )
              : null;
          final ready = ordered.isEmpty && conflicts.isEmpty
              ? ReviewReadyData(
                  title: t(TechnicianKeys.technicianReadyToComplete),
                  body: t(TechnicianKeys.technicianSummaryReadyBody),
                )
              : null;
          return SummaryGateView(
            header: ReviewJobHeader(
              vehicle: job == null ? '' : queueVehicleLabel(job),
              plate: (job?.vehiclePlate ?? '').trim(),
              reference: (job?.reference ?? '').trim(),
              statusLabel: status.isEmpty ? null : jobStatusLabel(ref, status),
              statusTone: status.isEmpty
                  ? StatusTone.neutral
                  : jobStatusTone(ref, status),
              progressLabel: t(TechnicianKeys.technicianQueueItems, {
                'done': summary.itemsAssessed,
                'total': summary.itemsTotal,
              }),
              progress: summary.itemsTotal > 0
                  ? summary.itemsAssessed / summary.itemsTotal
                  : null,
            ),
            onBack: () => Navigator.of(context).maybePop(),
            primaryLabel: primaryLabel,
            onPrimary: primaryAction,
            saving: _completing && !readOnly,
            secondaryLabel: secondaryLabel,
            onSecondary: secondaryLabel == null ? null : _openSignature,
            score: scoreData,
            offlineLabel: online ? null : t(TechnicianKeys.offlineBanner),
            error: _error,
            blockersTitle: t(TechnicianKeys.technicianBlockersToResolve, {
              'count': ordered.length,
            }),
            blockers: [
              for (final blocker in ordered)
                ReviewGateRowData(
                  icon: _rowIcon(blocker, signature),
                  title: blocker.messageFor(language),
                  code: blocker.itemCode,
                  onTap: readOnly ? null : _openFor(blocker),
                ),
            ],
            warningsTitle: t(TechnicianKeys.technicianWarningsTitle),
            warnings: [
              for (final warning in warnings)
                ReviewGateRowData(
                  icon: Icons.info_outline_rounded,
                  title: warning.messageFor(language),
                  code: warning.itemCode,
                ),
            ],
            ready: ready,
            readyChecks: ready == null
                ? const <ReviewReceiptRow>[]
                : [
                    ReviewReceiptRow(
                      label: t(TechnicianKeys.technicianItems),
                      value: t(TechnicianKeys.technicianItemsAssessed, {
                        'done': summary.itemsAssessed,
                        'total': summary.itemsTotal,
                      }),
                    ),
                    ReviewReceiptRow(
                      label: t(TechnicianKeys.technicianSignatureTitle),
                      value: t(TechnicianKeys.technicianSignatureCaptured),
                    ),
                    ReviewReceiptRow(
                      label: t(TechnicianKeys.technicianSyncConflictTitle),
                      value: t(TechnicianKeys.technicianNoConflicts),
                    ),
                  ],
            conflictsPanel: conflicts.isNotEmpty && !readOnly
                ? ConflictPanel(
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
                  )
                : null,
          );
        },
      ),
    );
  }

  VoidCallback? _openFor(Blocker blocker) {
    if (technicianBlockerRoute(widget.jobId, blocker) == null) {
      return null;
    }
    return () => _openBlocker(blocker);
  }

  IconData _rowIcon(Blocker blocker, Blocker? signature) {
    if (identical(blocker, signature)) {
      return Icons.draw_outlined;
    }
    if (_isSync(blocker)) {
      return Icons.sync_problem_rounded;
    }
    return Icons.format_list_bulleted_rounded;
  }

  bool _isSignature(Blocker blocker) => blocker.code == 'SIGNATURE_MISSING';

  bool _isSync(Blocker blocker) => blocker.code == 'SYNC_CONFLICT';

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
      // A signature or a sync conflict is one blocker no matter how many
      // sources report it: the same code with a different sentence is still the
      // same thing to fix. Item blockers keep the item code so several items can
      // each have their own row.
      final key = switch (blocker.code) {
        'SIGNATURE_MISSING' || 'SYNC_CONFLICT' => blocker.code,
        _ => '${blocker.code}|${blocker.itemCode}',
      };
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
