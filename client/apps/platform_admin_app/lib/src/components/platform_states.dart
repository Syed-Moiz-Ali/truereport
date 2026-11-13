import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_buttons.dart';

import 'package:l10n/l10n.dart';

class PlatformLoadingView extends ConsumerWidget {
  const PlatformLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return _StateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: PtTheme.deepGreen),
          const SizedBox(height: 12),
          Text(
            message ?? strings.tKey(CommonKeys.stateLoading),
            style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

/// Empty state: icon + title + optional body + optional action.
class PlatformEmptyView extends StatelessWidget {
  const PlatformEmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: PtTheme.canvas,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: PtTheme.muted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PtTheme.font(
              15,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          if (body != null && body!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body!, textAlign: TextAlign.center, style: PtTheme.bodyMuted),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            PlatformSecondaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Inline error card with retry. Server messages are mapped to fields by
/// the calling page; this widget only renders the card.
class PlatformErrorView extends ConsumerWidget {
  const PlatformErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return _StateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: PtTheme.rose,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
          ),
          const SizedBox(height: 12),
          PlatformSecondaryButton(
            label: retryLabel ?? strings.tKey(CommonKeys.buttonRetry),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class PlatformSkeletonList extends StatefulWidget {
  const PlatformSkeletonList({super.key, this.rows = 3});

  final int rows;

  @override
  State<PlatformSkeletonList> createState() => _PlatformSkeletonListState();
}

class _PlatformSkeletonListState extends State<PlatformSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.rows; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _SkeletonRow(phase: (_controller.value + i * 0.18) % 1.0),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final glow = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    final fill = Color.lerp(PtTheme.border, PtTheme.canvas, glow)!;
    final bar = BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(6),
    );
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FractionallySizedBox(
                widthFactor: 0.55,
                child: Container(height: 12, decoration: bar),
              ),
              const SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: Container(height: 10, decoration: bar),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StateFrame extends StatelessWidget {
  const _StateFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
      ),
      child: Center(child: child),
    );
  }
}
