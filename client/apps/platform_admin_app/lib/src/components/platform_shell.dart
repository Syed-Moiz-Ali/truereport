import 'package:flutter/material.dart';

import '../platform_theme.dart';
import 'platform_header.dart';
import 'platform_sidebar.dart';

/// Shared Platform Admin shell.
///
/// Keeps the desktop sidebar and header on every screen, hides the sidebar on
/// compact widths (the header exposes the mobile navigation sheet), and gives
/// pages one consistent top-aligned content frame.
class PlatformShell extends StatelessWidget {
  const PlatformShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.onSearchChanged,
    this.showSearch = true,
    this.onNavigate,
    this.contextBar,
  });

  final String currentRoute;
  final Widget child;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearch;
  final ValueChanged<String>? onNavigate;

  /// Page-provided context bar (breadcrumbs + page actions) rendered
  /// directly below the app header. Pages own their breadcrumb data.
  final Widget? contextBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: PtTheme.canvas,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSidebar)
                PlatformSidebar(
                  currentRoute: currentRoute,
                  onNavigate: onNavigate,
                ),
              Expanded(
                child: Column(
                  children: [
                    PlatformHeader(
                      currentRoute: currentRoute,
                      onSearchChanged: showSearch ? onSearchChanged : null,
                      onNavigate: onNavigate,
                    ),
                    // ignore: use_null_aware_elements
                    if (contextBar != null) contextBar!,
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                compact ? 16 : 28,
                compact ? 20 : 28,
                compact ? 16 : 28,
                40,
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
              const SizedBox(height: 6),
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
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Expanded(child: titleBlock),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(child: titleBlock),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 20),
              // Flexible bounds the actions Wrap so buttons wrap instead of
              // overflowing when the title and actions exceed the row width.
              Flexible(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: actions,
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
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
