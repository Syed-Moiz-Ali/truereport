import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

/// Skeletons in the real region geometry: identity band, two body columns.
class JobDetailLoading extends StatelessWidget {
  const JobDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return ListView(
      padding: ws.pagePaddingOf(context),
      children: [
        const WorkshopSkeleton(card: true, lines: 6),
        SizedBox(height: spacing.lg),
        const WorkshopSkeleton(card: true, lines: 5),
        SizedBox(height: spacing.lg),
        const WorkshopSkeleton(card: true, lines: 4),
      ],
    );
  }
}

/// Bounded load error with distinct forbidden / not-found copy (F17).
class JobDetailLoadError extends StatelessWidget {
  const JobDetailLoadError({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    return SingleChildScrollView(
      padding: ws.pagePaddingOf(context),
      child: WorkshopErrorState(
        title: t(WorkshopAdminKeys.error),
        body: _loadCopy(t, error),
        retryLabel: t(WorkshopAdminKeys.retryAction),
        onRetry: onRetry,
      ),
    );
  }
}

String _loadCopy(UiStrings t, Object error) {
  if (error is AppFailure) {
    final failure = error;
    if (failure.statusCode == 403 || failure.code == 'FORBIDDEN') {
      return t(WorkshopAdminKeys.jobsForbidden);
    }
    if (failure.statusCode == 404 || failure.code == 'JOB_NOT_FOUND') {
      return t(WorkshopAdminKeys.jobsNotFound);
    }
  }
  return t(WorkshopAdminKeys.commonLoadFailed);
}

/// Persistent conflict banner: the page never silently discards a stale write.
/// Message-only; the sticky bar owns the single explicit reload control (N9).
class JobDetailConflictBanner extends StatelessWidget {
  const JobDetailConflictBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(spacing.md),
        decoration: BoxDecoration(
          color: ws.warningSoft,
          borderRadius: BorderRadius.circular(ws.cardRadius),
          border: Border.all(color: ws.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sync_problem_outlined, size: 18, color: ws.warning),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(message, style: ws.body.copyWith(color: ws.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Version missing blocks every mutation (M5); this says so on the page.
class JobDetailVersionNote extends StatelessWidget {
  const JobDetailVersionNote({super.key});

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return WorkshopInlineNote(text: t(WorkshopAdminKeys.jobsNoVersion));
  }
}
