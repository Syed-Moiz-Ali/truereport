import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Loading and failure surfaces for the dashboard.
///
/// The rule from the audit (S1/R2): a placeholder must never look like a number.
/// The hero skeleton is a bar at the numeral's height, not a "0"; the atlas
/// skeleton is a hollow bar, not a proportional guess.

class DashboardHeroSkeleton extends StatelessWidget {
  const DashboardHeroSkeleton({required this.totalHeight, super.key});

  final double totalHeight;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: totalHeight * 1.6,
          height: totalHeight * 0.8,
          decoration: BoxDecoration(
            color: ws.border,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(height: spacing.sm),
        Container(
          width: 180,
          height: 14,
          decoration: BoxDecoration(
            color: ws.canvas,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class DashboardAtlasSkeleton extends StatelessWidget {
  const DashboardAtlasSkeleton({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: ws.border,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(height: spacing.md),
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: context.spacing.sm),
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: ws.canvas,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class DashboardRowsSkeleton extends StatelessWidget {
  const DashboardRowsSkeleton({this.rows = 2, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: ws.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.xl),
                    Container(
                      width: 62,
                      height: 13,
                      decoration: BoxDecoration(
                        color: ws.canvas,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                Container(
                  width: 200,
                  height: 11,
                  decoration: BoxDecoration(
                    color: ws.canvas,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A bounded one-line failure with a retry. Never renders a number.
class DashboardErrorLine extends StatelessWidget {
  const DashboardErrorLine({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        decoration: BoxDecoration(
          color: ws.dangerSoft,
          borderRadius: BorderRadius.circular(ws.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 15, color: ws.danger),
            SizedBox(width: spacing.sm),
            Flexible(
              child: Text(message, style: ws.meta.copyWith(color: ws.danger)),
            ),
            SizedBox(width: spacing.sm),
            _RetryAction(label: retryLabel, onRetry: onRetry),
          ],
        ),
      ),
    );
  }
}

class _RetryAction extends StatelessWidget {
  const _RetryAction({required this.label, required this.onRetry});

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onRetry,
          canRequestFocus: true,
          borderRadius: BorderRadius.circular(ws.chipRadius),
          child: Container(
            constraints: BoxConstraints(minHeight: ws.touchTarget),
            padding: EdgeInsets.symmetric(horizontal: spacing.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: ws.danger.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(ws.chipRadius),
            ),
            child: Text(
              label,
              style: ws.meta.copyWith(
                color: ws.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
