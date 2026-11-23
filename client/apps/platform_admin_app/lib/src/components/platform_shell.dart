import 'package:flutter/material.dart';

import '../platform_theme.dart';
import 'shell/platform_dock.dart';
import 'shell/platform_identity_strip.dart';

export 'shell/platform_identity_strip.dart' show PlatformBrandMark;

/// Shared Platform Admin shell — direction A "Docked Command".
///
/// One 44px identity strip at the top, one floating dock at the bottom, and
/// the work in between at full width. No rail, no command bar, no "More"
/// sheet: the same five destinations are reachable at every size. Audit log
/// lives inside the profile ledger rather than in the dock.
///
/// Pass [showStrip] false for immersive pages that own the top edge
/// themselves (the profile screen carries its own account card, so the
/// strip would duplicate it). Content still reserves the dock height.
///
/// Content reserves the dock's height ([PlatformDock.reserve]) so no screen
/// has to know the dock exists. Layout uses directional insets, so an RTL
/// locale mirrors the strip and the dock.
class PlatformShell extends StatelessWidget {
  const PlatformShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.onSearchChanged,
    this.showSearch = true,
    this.onNavigate,
    this.contextBar,
    this.showStrip = true,
  });

  final String currentRoute;
  final Widget child;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearch;
  final ValueChanged<String>? onNavigate;

  /// Page-provided context bar (breadcrumbs + page actions) rendered
  /// directly below the strip on the page canvas. Pages own their data.
  final Widget? contextBar;

  /// Whether the identity strip renders. The dock always renders.
  final bool showStrip;

  @override
  Widget build(BuildContext context) {
    final reserve = PlatformDock.reserve(context);
    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showStrip)
                  PlatformIdentityStrip(
                    currentRoute: currentRoute,
                    onSearchChanged: showSearch ? onSearchChanged : null,
                    onNavigate: onNavigate,
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: reserve),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ?contextBar,
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: PlatformDock(
                      currentRoute: currentRoute,
                      onNavigate: onNavigate,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consistent page frame: top-aligned, max-width constrained, with the same
/// horizontal/vertical rhythm on every Platform Admin screen.
class PlatformPage extends StatelessWidget {
  const PlatformPage({
    super.key,
    required this.child,
    this.maxWidth = 1240,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding:
              padding ??
              EdgeInsets.fromLTRB(
                compact ? 16 : 24,
                compact ? 16 : 24,
                compact ? 16 : 24,
                36,
              ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Consistent page heading used by every Platform Admin screen.
class PlatformPageHeader extends StatelessWidget {
  const PlatformPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: PtTheme.pageTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: PtTheme.bodyMuted,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Expanded(child: titleBlock),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(child: titleBlock),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Standard section card used by configuration screens.
class PlatformSectionCard extends StatelessWidget {
  const PlatformSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: child,
    );
  }
}
