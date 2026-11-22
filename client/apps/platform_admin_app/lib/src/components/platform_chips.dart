import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform_theme.dart';
import '../reference_status_lookup.dart';

/// Selectable filter chip used in toolbars and views.
class PlatformFilterChip extends StatelessWidget {
  const PlatformFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PtTheme.chipRadius),
          hoverColor: PtTheme.canvas,
          // 7px of padding above/below the 30px pill keeps the touch target at
          // 44px without making the visible chip taller than the row.
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              constraints: const BoxConstraints(minWidth: 44),
              decoration: BoxDecoration(
                color: selected
                    ? PtTheme.deepGreen.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(PtTheme.chipRadius),
                border: Border.all(
                  color: selected
                      ? PtTheme.deepGreen.withValues(alpha: 0.35)
                      : PtTheme.border,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? PtTheme.deepGreen : PtTheme.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status badge for a lifecycle state.
///
/// The tone comes from the served reference taxonomy (`statusesProvider`);
/// there is no local status→colour switch. Until the taxonomy resolves, the
/// chip stays neutral.
class PlatformStatusChip extends ConsumerWidget {
  const PlatformStatusChip({super.key, required this.status, this.label});

  final String status;

  /// Localized display label. When omitted, [status] is shown as-is.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = ref.watch(statusToneTokenProvider(status))?.toLowerCase();
    Color foreground = PtTheme.muted;
    Color background = PtTheme.canvas;
    switch (tone) {
      case 'success':
      case 'positive':
        foreground = PtTheme.deepGreen;
        background = PtTheme.emerald.withValues(alpha: 0.12);
      case 'warning':
      case 'caution':
        // amber-800 on the cream chip: 8.6:1, AA for the 11px label.
        foreground = const Color(0xFF92400E);
        background = const Color(0xFFFFFBEB);
      case 'danger':
      case 'error':
      case 'negative':
      case 'critical':
        foreground = PtTheme.rose;
        background = PtTheme.rose.withValues(alpha: 0.08);
    }

    return Container(
      // 14px line + 8px padding above/below = the 30px chip height.
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(PtTheme.chipRadius),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        (label ?? status).isEmpty ? '—' : label ?? status,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w600,
          color: foreground,
          tracking: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Small `label: value` metadata pill used inside cards.
class PlatformMetaPill extends StatelessWidget {
  const PlatformMetaPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 14px line + 8px padding above/below = the 30px chip height.
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(PtTheme.chipRadius),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w600,
          color: PtTheme.muted,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Metadata chip for secondary tags, counts, or attributes.
class PlatformMetadataChip extends StatelessWidget {
  const PlatformMetadataChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: PtTheme.chipHeight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(PtTheme.chipRadius),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: PtTheme.muted),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: PtTheme.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
