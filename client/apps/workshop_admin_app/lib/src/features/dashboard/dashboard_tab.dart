import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_style.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_atlas.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_groups.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_hero.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Pins numerals to Latin digits and strips bidi control characters.
///
/// The page's counts come from `NumberFormat.decimalPattern`, which renders
/// Latin digits for `ar` in intl 0.20, while `DateFormat` renders Arabic-Indic
/// digits **and** inserts RLM/LRM controls around the separators. Left in, those
/// controls split `2026/11/5 09:00` inside the row meta (the gate caught
/// `509:00 2026/11/`). One screen must not mix numbering systems, and a data
/// line must not carry invisible direction switches.
String pinDashboardDigits(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    // Arabic-Indic digits → ASCII.
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(rune - 0x0660 + 0x30);
      continue;
    }
    // Bidi controls: LRM, RLM, ALM, embeddings/overrides, isolates.
    if (rune == 0x200E ||
        rune == 0x200F ||
        rune == 0x061C ||
        (rune >= 0x202A && rune <= 0x202E) ||
        (rune >= 0x2066 && rune <= 0x2069)) {
      continue;
    }
    buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

/// Builds a row's meta line from machine-readable fields.
///
/// The line is rendered with an explicit LTR base direction by
/// [DashboardJobRow]: an RTL paragraph reorders neutral-separated runs, which
/// split the date around the reference on the Arabic capture
/// (`…2026/11/JOB-10485 · Ahmed… · 5`). Pinning the base direction keeps
/// `2026/11/5 09:00` contiguous while the Arabic name inside still shapes RTL.
String dashboardRowMeta({
  required String reference,
  String? customer,
  String? technician,
  String? schedule,
}) {
  final parts = <String>[
    reference,
    if ((customer ?? '').trim().isNotEmpty) customer!.trim(),
    if ((technician ?? '').trim().isNotEmpty) technician!.trim(),
    if ((schedule ?? '').trim().isNotEmpty) schedule!.trim(),
  ];
  return parts.join(' · ');
}

/// Locale-aware integer formatting. Kept here because five other screens import
/// it from this file; deleting it would be a rename, not a simplification.
String formatNumber(BuildContext context, int value) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format(value);

/// Overview tab — direction B "The floor" (`docs/ui_brief.md`).
///
/// The page answers one question: *what needs my decision right now?* It reads
/// only the clean (`platform_jobs`) family, so the jobs it counts are the jobs
/// its own "New job" action creates (invariant J19).
///
/// Structure, top to bottom: hero (total + decision sentence + the page's only
/// filled button) → the nine-segment partition (or the phone spine) → three
/// action groups → a footer that states the partition's meaning.
///
/// The previous composition (greeting, five-tile strip, Next up card, pipeline
/// card, recent-jobs card, quick actions) is deleted — see the kill list in
/// `docs/visual_language_dashboard.md` §8.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  static const String _pendingKey =
      '0\u00015\u0001PENDING_REVIEW\u0001\u0001\u0001';
  static const String _inBayKey = '0\u00013\u0001IN_PROGRESS\u0001\u0001\u0001';
  static const String _approvedKey = '0\u00013\u0001APPROVED\u0001\u0001\u0001';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;

    final counts = ref.watch(cleanJobCountsProvider);
    final pending = ref.watch(cleanJobsProvider(_pendingKey));
    final inBay = ref.watch(cleanJobsProvider(_inBayKey));
    final approved = ref.watch(cleanJobsProvider(_approvedKey));

    void openJob(String jobId) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => JobDetailPage(jobId: jobId)),
    );
    void newJob() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const JobCreationWizardPage()),
    );
    void refresh() {
      ref.invalidate(cleanJobCountsProvider);
      ref.invalidate(cleanJobsProvider(_pendingKey));
      ref.invalidate(cleanJobsProvider(_inBayKey));
      ref.invalidate(cleanJobsProvider(_approvedKey));
    }

    final total = counts.value?.total;
    final DashboardHeroState heroState;
    if (counts.hasError) {
      heroState = DashboardHeroState.failed;
    } else if (!counts.hasValue) {
      heroState = DashboardHeroState.loading;
    } else {
      heroState = counts.value!.total == 0
          ? DashboardHeroState.empty
          : DashboardHeroState.ready;
    }

    // The page lives inside the shell's content area, so its breakpoints are
    // computed from the width it is actually given — not the window width (the
    // sidebar can take 256 px of it).
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = DashboardScale.byWidth(constraints.maxWidth);
        final compact = constraints.maxWidth < 600;
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  scale.gutter,
                  scale.gutter,
                  scale.gutter,
                  spacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DashboardHero(
                        state: heroState,
                        scale: scale,
                        compact: compact,
                        // The shell's identity strip already names the workshop;
                        // repeating it here would put the same words twice above
                        // the fold (shell audit finding S1).
                        eyebrow: null,
                        totalText: total == null
                            ? null
                            : formatNumber(context, total),
                        label: (total ?? 0) == 1
                            ? l10n.dashFloorLabelOne
                            : l10n.dashFloorLabel,
                        sentence: total == null
                            ? null
                            : (counts.value!.pendingReview == 0
                                  ? l10n.dashNothingWaiting
                                  : l10n.dashDecisionWaiting(
                                      counts.value!.pendingReview,
                                    )),
                        emptyTitle: l10n.dashFloorEmpty,
                        emptyBody: l10n.dashFloorEmptyBody,
                        errorMessage: l10n.commonLoadFailed,
                        retryLabel: l10n.retryAction,
                        onRetry: () => ref.invalidate(cleanJobCountsProvider),
                        newJobLabel: l10n.newJob,
                        onNewJob: newJob,
                      ),

                      // The partition. Only rendered when the counts endpoint
                      // said there is something to partition; a failure never
                      // draws a hollow bar that could read as "zero".
                      if (heroState == DashboardHeroState.ready) ...[
                        SizedBox(height: spacing.xxl),
                        DashboardAtlas(
                          key: const Key('dashboard-atlas'),
                          segments: _segments(context, l10n, counts.value!),
                          total: total!,
                          height: scale.atlasHeight,
                          semanticLabel: l10n.dashAtlasLabel,
                        ),
                      ],

                      // The lists are independent of the counts call: a failed
                      // counts request must not hide work the admin can still do.
                      if (heroState != DashboardHeroState.empty) ...[
                        SizedBox(height: spacing.xxl),
                        _groups(
                          context: context,
                          ref: ref,
                          l10n: l10n,
                          scale: scale,
                          pending: pending,
                          inBay: inBay,
                          approved: approved,
                          counts: counts.value,
                          onOpen: openJob,
                        ),
                        if (total != null) ...[
                          SizedBox(height: spacing.xl),
                          _footer(context, l10n, total),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<AtlasSegment> _segments(
    BuildContext context,
    AppLocalizations l10n,
    CleanJobCounts counts,
  ) {
    final ws = context.ws;
    int countOf(String status) => switch (status) {
      'DRAFT' => counts.draft,
      'SCHEDULED' => counts.scheduled,
      'ASSIGNED' => counts.assigned,
      'IN_PROGRESS' => counts.inProgress,
      'PENDING_REVIEW' => counts.pendingReview,
      'APPROVED' => counts.approved,
      'PUBLISHED' => counts.published,
      'REJECTED' => counts.rejected,
      'CANCELLED' => counts.cancelled,
      _ => 0,
    };
    final segments = [
      for (final status in dashboardStatusOrder)
        AtlasSegment(
          status: status,
          label: jobStatusLabel(l10n, status),
          count: countOf(status),
          color: dashboardStatusTint(status, ws),
        ),
    ];
    // A status the client does not know still counts towards `total` on the
    // server. It is drawn as an explicit neutral tail, never dropped.
    final labelled = segments.fold<int>(0, (sum, s) => sum + s.count);
    final unaccounted = counts.total - labelled;
    if (unaccounted > 0) {
      segments.add(
        AtlasSegment(
          status: '__other__',
          label: l10n.dashSegmentOther,
          count: unaccounted,
          color: dashboardStatusTint('OTHER', ws),
          isRemainder: true,
        ),
      );
    }
    return segments;
  }

  Widget _groups({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required DashboardScale scale,
    required AsyncValue<JobPage> pending,
    required AsyncValue<JobPage> inBay,
    required AsyncValue<JobPage> approved,
    required CleanJobCounts? counts,
    required void Function(String jobId) onOpen,
  }) {
    final ws = context.ws;
    final spacing = context.spacing;

    DashboardRowData map(CleanJob job, {String? verb}) {
      final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
      final title = vehicle.isEmpty ? job.customerName : vehicle;
      final schedule = pinDashboardDigits(
        WorkshopClock.formatInstant(context, job.scheduledAt),
      );
      return DashboardRowData(
        id: job.id,
        title: title,
        meta: dashboardRowMeta(
          reference: job.reference,
          customer: job.customerName,
          technician: job.assignedTechnicianName,
          schedule: schedule,
        ),
        statusLabel: jobStatusLabel(l10n, job.status),
        tone: dashboardStatusTone(job.status),
        onOpen: () => onOpen(job.id),
        verbLabel: verb,
        onVerb: verb == null ? null : () => onOpen(job.id),
      );
    }

    final waiting = DashboardGroup(
      swatch: ws.warning,
      title: l10n.dashGroupWaiting,
      meta: counts == null
          ? null
          : l10n.dashGroupCountPending(counts.pendingReview),
      rows: pending.whenData(
        (page) => [
          for (final job in page.items) map(job, verb: l10n.dashReviewVerb),
        ],
      ),
      emptyText: l10n.dashGroupEmpty,
      loadFailed: l10n.commonLoadFailed,
      retryLabel: l10n.retryAction,
      onRetry: () => ref.invalidate(cleanJobsProvider(_pendingKey)),
      verbInline: scale.verbInline,
      rowKeyPrefix: 'dashboard-job-waiting',
    );

    final bay = DashboardGroup(
      swatch: ws.accent,
      title: l10n.dashGroupInBay,
      meta: counts == null ? null : l10n.dashGroupCountInBay(counts.inProgress),
      rows: inBay.whenData((page) => [for (final job in page.items) map(job)]),
      emptyText: l10n.dashGroupEmpty,
      loadFailed: l10n.commonLoadFailed,
      retryLabel: l10n.retryAction,
      onRetry: () => ref.invalidate(cleanJobsProvider(_inBayKey)),
      verbInline: scale.verbInline,
      rowKeyPrefix: 'dashboard-job-bay',
    );

    final ready = DashboardGroup(
      swatch: ws.success,
      title: l10n.dashGroupReady,
      meta: counts == null ? null : l10n.dashGroupCountReady(counts.approved),
      rows: approved.whenData(
        (page) => [
          for (final job in page.items) map(job, verb: l10n.dashPublishVerb),
        ],
      ),
      emptyText: l10n.dashGroupEmpty,
      loadFailed: l10n.commonLoadFailed,
      retryLabel: l10n.retryAction,
      onRetry: () => ref.invalidate(cleanJobsProvider(_approvedKey)),
      verbInline: scale.verbInline,
      rowKeyPrefix: 'dashboard-job-ready',
    );

    if (!scale.sideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          waiting,
          SizedBox(height: spacing.xxl),
          bay,
          SizedBox(height: spacing.xxl),
          ready,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: waiting),
        SizedBox(width: spacing.xxl),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              bay,
              SizedBox(height: spacing.xxl),
              ready,
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n, int total) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: ws.border),
        SizedBox(height: spacing.md),
        Text(
          l10n.dashFooterSum(total),
          style: ws.meta.copyWith(color: ws.muted),
        ),
      ],
    );
  }
}
