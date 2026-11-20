import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_theme.dart';
import '../dashboard_feed.dart';
import 'trellis_ui.dart';

/// Full-width attention ribbon: the one place exceptions surface in Trellis.
class TrellisRibbon extends StatelessWidget {
  const TrellisRibbon({
    super.key,
    required this.strings,
    required this.entries,
    required this.onDetails,
  });

  final UiMessageStrings strings;
  final List<DashboardAttention> entries;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final hasAttention = entries.isNotEmpty;
    final accent = hasAttention ? PtTheme.gold : PtTheme.deepGreen;
    final background = hasAttention ? Trellis.amberTint : Trellis.tint;
    final border = hasAttention
        ? const Color(0xFFF1DFC2)
        : const Color(0xFFD8EAE2);
    final label = hasAttention
        ? entries.first.title
        : strings.tKey(PlatformAdminKeys.dashboardNeedsAttentionEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 760;
          final lead = Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasAttention ? PtTheme.amber : PtTheme.deepGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Trellis.text(
                    12,
                    weight: FontWeight.w700,
                    color: hasAttention
                        ? const Color(0xFF7C4A05)
                        : PtTheme.deepGreen,
                  ),
                ),
              ),
            ],
          );
          final tail = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasAttention)
                TrellisPill(
                  label: '${entries.length}',
                  tone: TrellisTone.warning,
                ),
              const SizedBox(width: 10),
              TrellisButton(
                label: strings.tKey(PlatformAdminKeys.buttonViewDetails),
                variant: TrellisButtonVariant.ghost,
                compact: true,
                onPressed: onDetails,
              ),
              const SizedBox(width: 2),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                size: 14,
                color: accent,
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                lead,
                const SizedBox(height: 6),
                Align(alignment: AlignmentDirectional.centerEnd, child: tail),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: lead),
              const SizedBox(width: 12),
              tail,
            ],
          );
        },
      ),
    );
  }
}
