import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsetsDirectional.all(context.sizing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: context.sizing.iconXl, color: iconColor),
            SizedBox(height: context.spacing.md),
            Semantics(
              header: true,
              child: Text(title, style: context.texts.titleMedium),
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              body,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (footer != null) ...[
              SizedBox(height: context.spacing.lg),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.body,
    this.action,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String title;
  final String body;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: _StatePanel(
        icon: icon,
        iconColor: context.colors.secondary,
        title: title,
        body: body,
        footer: action,
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.body,
    this.onRetry,
    this.retryLabel,
    this.action,
    this.icon = Icons.error_outline,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry != null && retryLabel != null
        ? FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel!))
        : null;
    return Semantics(
      container: true,
      liveRegion: true,
      child: _StatePanel(
        icon: icon,
        iconColor: context.colors.error,
        title: title,
        body: body,
        footer: action ?? retry,
      ),
    );
  }
}

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    this.lines = 3,
    this.height,
    this.semanticLabel,
    super.key,
  });

  final int lines;
  final double? height;
  final String? semanticLabel;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration.zero,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.motion.slow * 3;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.55;
    } else if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.semanticLabel,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 0.8).animate(
          CurvedAnimation(
            parent: _controller,
            curve: context.motion.enterCurve,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            widget.lines,
            (index) => Container(
              height: widget.height ?? spacing.md,
              margin: EdgeInsetsDirectional.only(bottom: spacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(context.radii.sm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.message,
    this.icon = Icons.cloud_off,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.warning;
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        width: double.infinity,
        padding: EdgeInsetsDirectional.all(context.spacing.md),
        decoration: BoxDecoration(color: pair.background),
        child: Row(
          children: [
            Icon(icon, size: context.sizing.iconLg, color: pair.foreground),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall?.copyWith(
                  color: pair.foreground,
                ),
              ),
            ),
            if (action != null) ...[
              SizedBox(width: context.spacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class FadeInCard extends StatelessWidget {
  const FadeInCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = context.motionDuration(context.motion.normal);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: context.motion.enterCurve,
      builder: (context, value, animatedChild) => Opacity(
        opacity: reduceMotion ? 1 : value,
        child: Transform.translate(
          offset: reduceMotion
              ? Offset.zero
              : Offset(0, context.spacing.sm * (1 - value)),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}
