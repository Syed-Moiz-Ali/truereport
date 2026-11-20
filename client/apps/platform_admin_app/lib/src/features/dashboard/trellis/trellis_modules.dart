import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_config_models.dart';
import '../../../platform_theme.dart';
import 'trellis_ui.dart';

/// Server-formatted KPI cards from `/platform/overview`.
///
/// Every number, label and caption is served; the client only lays them out in
/// the existing Trellis grid (three / two / one column).
class TrellisBento extends StatelessWidget {
  const TrellisBento({super.key, required this.strings, required this.cards});

  final UiMessageStrings strings;
  final List<OverviewMetricCard> cards;

  @override
  Widget build(BuildContext context) {
    final resolved =
        <({OverviewMetricCard card, String label, String caption})>[
          for (final card in [
            ...cards,
          ]..sort((a, b) => a.order.compareTo(b.order)))
            if (strings.resolveFlatKey(card.labelKey) case final label?
                when label.trim().isNotEmpty)
              (
                card: card,
                label: label,
                caption: strings.resolveFlatKey(card.captionKey) ?? '',
              ),
        ];
    if (resolved.isEmpty) {
      return TrellisSurface(
        child: Text(strings.tKey(CommonKeys.emptyTitle), style: Trellis.body),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        final rows =
            <List<({OverviewMetricCard card, String label, String caption})>>[];
        for (var i = 0; i < resolved.length; i += columns) {
          final end = i + columns < resolved.length
              ? i + columns
              : resolved.length;
          rows.add(resolved.sublist(i, end));
        }
        return Column(
          children: [
            for (var row = 0; row < rows.length; row++) ...[
              if (row > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 12),
                      Expanded(
                        child: column < rows[row].length
                            ? _MetricTile(
                                card: rows[row][column].card,
                                label: rows[row][column].label,
                                caption: rows[row][column].caption,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.card,
    required this.label,
    required this.caption,
  });

  final OverviewMetricCard card;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(Trellis.surfaceRadius),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _toneColor(card.tone),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Trellis.eyebrow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            card.value,
            style: Trellis.text(
              40,
              weight: FontWeight.w800,
              tracking: -1.4,
              tabular: true,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Trellis.text(10.5, color: PtTheme.muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

Color _toneColor(String tone) {
  return switch (tone.toLowerCase()) {
    'success' || 'positive' => PtTheme.deepGreen,
    'warning' || 'caution' => PtTheme.amber,
    'danger' || 'error' || 'negative' || 'critical' => PtTheme.rose,
    'info' => const Color(0xFF1D4ED8),
    _ => PtTheme.muted,
  };
}
