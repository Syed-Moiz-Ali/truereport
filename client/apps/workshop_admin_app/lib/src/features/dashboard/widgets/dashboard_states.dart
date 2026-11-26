import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_controls.dart';

/// Inline, scoped error. Never a full-page failure: the queues can still be
/// used when only the counts call failed.
class DashboardInlineError extends StatelessWidget {
  const DashboardInlineError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.compact = false,
    this.filled = true,
    super.key,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final bool compact;

  /// Filled pink for the page-level error; quiet for a group that failed while
  /// the rest of the ledger still works.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final row = Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 18, color: ws.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: ws.meta.copyWith(color: filled ? ws.danger : ws.ink),
          ),
        ),
        const SizedBox(width: 8),
        QueueTextAction(
          label: retryLabel,
          onTap: onRetry,
          icon: Icons.refresh_rounded,
        ),
      ],
    );

    if (!filled) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: 4,
        ),
        child: row,
      );
    }

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: ws.dangerSoft,
        borderRadius: BorderRadius.circular(DashboardShape.control),
      ),
      child: row,
    );
  }
}

/// A group with nothing in it: one quiet line, checked, not an empty canvas.
class DashboardGroupEmpty extends StatelessWidget {
  const DashboardGroupEmpty({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 16, color: ws.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: ws.meta.copyWith(color: ws.muted)),
          ),
        ],
      ),
    );
  }
}

/// Loading shape for the decision module: three rows in the same geometry as a
/// real decision (title, meta, pill + verb). No rank column — this is not the
/// jobs queue.
class DashboardSkeletonRows extends StatelessWidget {
  const DashboardSkeletonRows({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 3; index++)
          _SkeletonRow(compact: compact, first: index == 0),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.compact, required this.first});

  final bool compact;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ws.canvas,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(compact ? 180 : 240, 14),
        const SizedBox(height: 10),
        bar(compact ? 210 : 420, 10),
        if (compact) ...[
          const SizedBox(height: 14),
          Row(children: [bar(96, 24), const Spacer(), bar(54, 10)]),
        ],
      ],
    );

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        compact ? 16 : 20,
        16,
        compact ? 12 : 20,
        16,
      ),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: ws.border)),
      ),
      child: compact
          ? content
          : Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 24),
                bar(108, 24),
                const SizedBox(width: 16),
                bar(16, 12),
              ],
            ),
    );
  }
}

/// Loading shape for the overview while the counts call is in flight: four KPI
/// blocks and one composition card. Same rhythm as the loaded page, so nothing
/// jumps when the numbers arrive.
class DashboardOverviewSkeleton extends StatelessWidget {
  const DashboardOverviewSkeleton({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    Widget block(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: ws.canvas,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border.withValues(alpha: 0.6)),
      ),
    );

    final kpis = compact
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: block(104)),
                  const SizedBox(width: 12),
                  Expanded(child: block(104)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: block(104)),
                  const SizedBox(width: 12),
                  Expanded(child: block(104)),
                ],
              ),
            ],
          )
        : Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: block(104)),
              ],
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        kpis,
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsetsDirectional.all(20),
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(DashboardShape.card),
            border: Border.all(color: ws.border),
          ),
          child: Row(
            children: [
              Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ws.canvas, width: 16),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(12),
                    const SizedBox(height: 18),
                    block(12),
                    const SizedBox(height: 18),
                    block(12),
                    const SizedBox(height: 18),
                    block(12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Loading shape for the insights row: one chart card, then two summary cards.
class DashboardInsightSkeleton extends StatelessWidget {
  const DashboardInsightSkeleton({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    Widget block(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        block(compact ? 260 : 300),
        const SizedBox(height: 16),
        if (compact) ...[
          block(180),
          const SizedBox(height: 16),
          block(180),
        ] else
          Row(
            children: [
              Expanded(child: block(200)),
              const SizedBox(width: 16),
              Expanded(child: block(200)),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// The whole-floor empty state. Built from the ledger's own motif: three rows,
/// one of them accented. No stock illustration, no empty canvas.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      padding: const EdgeInsetsDirectional.all(32),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: DashboardType.emptyTitle(ws)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(body, style: DashboardType.decision(ws)),
              ),
            ],
          );
          final action = QueueButton(
            label: actionLabel,
            icon: Icons.add_rounded,
            onPressed: onAction,
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _QueueGlyph(),
                const SizedBox(height: 28),
                copy,
                const SizedBox(height: 24),
                action,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _QueueGlyph(),
              const SizedBox(width: 36),
              Expanded(child: copy),
              const SizedBox(width: 24),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _QueueGlyph extends StatelessWidget {
  const _QueueGlyph();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    Widget row(double width, {bool accent = false, bool muted = false}) {
      return Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: accent
              ? ws.accent
              : muted
              ? ws.border
              : ws.canvas,
          borderRadius: BorderRadius.circular(DashboardShape.pill),
          border: muted ? Border.all(color: ws.border) : null,
        ),
      );
    }

    return SizedBox(
      width: 132,
      height: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          row(132, muted: true),
          row(104, accent: true),
          row(72, muted: true),
        ],
      ),
    );
  }
}
