import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';

/// Single breadcrumb entry passed by the owning page.
///
/// Labels are already localized by the caller. The last entry is rendered
/// as the active (dark) crumb; ancestors are muted.
@immutable
class ContextBreadcrumbItem {
  const ContextBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Reusable context bar rendered directly below the identity strip.
///
/// It sits on the page canvas rather than on a second white strip, so the
/// command bar is the only chrome edge on screen. Hierarchy:
/// Left: optional back affordance + breadcrumb trail (parent -> current).
/// Right: page-provided actions.
class PlatformContextBar extends StatelessWidget {
  const PlatformContextBar({
    super.key,
    required this.breadcrumbs,
    this.actions = const [],
    this.onBack,
  });

  final List<ContextBreadcrumbItem> breadcrumbs;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        // Compact: the full trail does not fit, and the current page name plus
        // its parent are the parts that matter. Keep the last two crumbs (the
        // parent doubles as the back target) instead of clipping the trail.
        final items = compact && breadcrumbs.length > 2
            ? breadcrumbs.sublist(breadcrumbs.length - 2)
            : breadcrumbs;
        final breadcrumb = _Breadcrumbs(items: items, onBack: onBack);

        final child = actions.isEmpty
            ? breadcrumb
            : (compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        breadcrumb,
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: breadcrumb),
                        const SizedBox(width: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: actions,
                        ),
                      ],
                    ));

        return Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 16 : 24,
            6,
            compact ? 16 : 24,
            6,
          ),
          child: child,
        );
      },
    );
  }
}

class _Breadcrumbs extends ConsumerWidget {
  const _Breadcrumbs({required this.items, this.onBack});

  final List<ContextBreadcrumbItem> items;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty && onBack == null) {
      return const SizedBox.shrink();
    }

    final strings = ref.watch(uiStringsProvider);
    final hasBack =
        onBack != null ||
        (items.length > 1 && items[items.length - 2].onTap != null);
    final effectiveBack =
        onBack ?? (items.length > 1 ? items[items.length - 2].onTap : null);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasBack && effectiveBack != null) ...[
            Semantics(
              button: true,
              label: strings.tKey(CommonKeys.buttonBack),
              child: Tooltip(
                message: strings.tKey(CommonKeys.buttonBack),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('btn-context-bar-back'),
                    onTap: effectiveBack,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 17,
                        color: PtTheme.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 7),
                child: Text(
                  '/',
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w400,
                    color: PtTheme.muted.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
            _Crumb(item: items[i], isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.item, required this.isLast});

  final ContextBreadcrumbItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final style = isLast
        ? PtTheme.font(
            13,
            lineHeight: 18,
            weight: FontWeight.w700,
            color: PtTheme.ink,
            tracking: -0.1,
          )
        : PtTheme.font(
            12,
            lineHeight: 16,
            weight: FontWeight.w500,
            color: PtTheme.muted,
          );

    final label = Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(
        item.label,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (item.onTap == null || isLast) {
      return Semantics(header: isLast, label: item.label, child: label);
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: PtTheme.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: label,
      ),
    );
  }
}
