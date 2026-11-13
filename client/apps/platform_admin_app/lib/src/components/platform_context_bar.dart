import 'package:flutter/material.dart';

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

/// Reusable context bar rendered directly below [PlatformHeader].
///
/// Left side is a breadcrumb trail, right side is page-provided actions
/// (for example a view toggle). Breadcrumbs are never hardcoded here; the
/// page passes them in.
class PlatformContextBar extends StatelessWidget {
  const PlatformContextBar({
    super.key,
    required this.breadcrumbs,
    this.actions = const [],
  });

  final List<ContextBreadcrumbItem> breadcrumbs;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final breadcrumb = _Breadcrumbs(items: breadcrumbs);
        if (actions.isEmpty) {
          return Container(
            width: double.infinity,
            color: PtTheme.white,
            padding: EdgeInsetsDirectional.fromSTEB(
              compact ? 16 : 24,
              12,
              compact ? 16 : 24,
              12,
            ),
            child: breadcrumb,
          );
        }
        if (compact) {
          return Container(
            width: double.infinity,
            color: PtTheme.white,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                breadcrumb,
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ),
          );
        }
        return Container(
          width: double.infinity,
          color: PtTheme.white,
          padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: breadcrumb),
              const SizedBox(width: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.items});

  final List<ContextBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w500,
                    color: PtTheme.muted,
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
            15,
            lineHeight: 22,
            weight: FontWeight.w700,
            color: PtTheme.ink,
          )
        : PtTheme.font(
            11,
            lineHeight: 14,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.5,
          );
    final label = Text(
      item.label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (item.onTap == null || isLast) {
      return Flexible(
        child: Semantics(header: isLast, label: item.label, child: label),
      );
    }
    return Flexible(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(4),
        child: label,
      ),
    );
  }
}
