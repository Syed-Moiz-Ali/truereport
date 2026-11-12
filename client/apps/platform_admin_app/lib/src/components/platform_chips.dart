import 'package:flutter/material.dart';

import '../platform_theme.dart';

/// Selectable pill filter chip used in toolbars.
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          decoration: BoxDecoration(
            color: selected
                ? PtTheme.deepGreen.withValues(alpha: 0.12)
                : PtTheme.canvas,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: selected
                  ? PtTheme.deepGreen.withValues(alpha: 0.35)
                  : PtTheme.border,
            ),
          ),
          child: Text(
            label,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? PtTheme.deepGreen : PtTheme.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Status pill (ACTIVE/PUBLISHED green, DRAFT amber, RETIRED rose,
/// everything else muted). Text + background convey state, never color alone.
class PlatformStatusChip extends StatelessWidget {
  const PlatformStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    var foreground = PtTheme.muted;
    var background = PtTheme.canvas;
    if (normalized == 'ACTIVE' || normalized == 'PUBLISHED') {
      foreground = PtTheme.deepGreen;
      background = PtTheme.emerald.withValues(alpha: 0.14);
    } else if (normalized == 'DRAFT' || normalized == 'PENDING') {
      foreground = PtTheme.amber;
      background = const Color(0xFFFFF7E6);
    } else if (normalized == 'RETIRED' ||
        normalized == 'DISABLED' ||
        normalized == 'FAILED') {
      foreground = PtTheme.rose;
      background = PtTheme.rose.withValues(alpha: 0.08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: PtTheme.font(
          10,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: foreground,
          tracking: 0.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
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
