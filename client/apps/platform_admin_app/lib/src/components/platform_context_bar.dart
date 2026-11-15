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

/// Reusable context bar rendered directly below [PlatformHeader].
///
/// Hierarchy:
/// Left side: optional back affordance + breadcrumb trail (parent -> current).
/// Right side: page-provided actions.
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
        final breadcrumb = _Breadcrumbs(items: breadcrumbs, onBack: onBack);

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
          decoration: const BoxDecoration(
            color: PtTheme.white,
            border: Border(
              bottom: BorderSide(color: PtTheme.border, width: 1),
            ),
          ),
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 14 : 24,
            8,
            compact ? 14 : 24,
            8,
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
    final hasBack = onBack != null ||
        (items.length > 1 && items[items.length - 2].onTap != null);
    final effectiveBack = onBack ??
        (items.length > 1 ? items[items.length - 2].onTap : null);

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
              child: InkWell(
                key: const Key('btn-context-bar-back'),
                onTap: effectiveBack,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 8),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: PtTheme.muted,
                  ),
                ),
              ),
            ),
          ],
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
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
            weight: FontWeight.w600,
            color: PtTheme.ink,
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
      return Semantics(
        header: isLast,
        label: item.label,
        child: label,
      );
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      hoverColor: PtTheme.canvas,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: label,
      ),
    );
  }
}
