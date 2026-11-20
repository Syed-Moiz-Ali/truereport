import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_theme.dart';
import '../dashboard_feed.dart';
import 'trellis_ui.dart';

/// Quiet full-width activity ledger. Kept below the domain board so the
/// dashboard does not lose "what just happened" while staying board-first.
class TrellisActivity extends StatelessWidget {
  const TrellisActivity({
    super.key,
    required this.strings,
    required this.entries,
    required this.onViewAll,
  });

  final UiMessageStrings strings;
  final List<DashboardActivity> entries;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return TrellisSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.tKey(
                      PlatformAdminKeys.sectionDashboardRecentActivity,
                    ),
                    style: Trellis.text(16, weight: FontWeight.w800),
                  ),
                ),
                if (entries.isNotEmpty)
                  TrellisButton(
                    label: strings.tKey(PlatformAdminKeys.buttonAuditViewAll),
                    icon: Icons.arrow_outward_rounded,
                    variant: TrellisButtonVariant.ghost,
                    compact: true,
                    onPressed: onViewAll,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: PtTheme.border),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                strings.tKey(PlatformAdminKeys.emptyActivityTitle),
                style: Trellis.body,
              ),
            )
          else
            for (var i = 0; i < entries.length; i++)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  border: i == entries.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: PtTheme.border)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Trellis.neutralTint,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 15,
                        color: PtTheme.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entries[i].title,
                            style: Trellis.text(12, weight: FontWeight.w700),
                          ),
                          if (entries[i].meta.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              entries[i].meta,
                              style: Trellis.text(10.5, color: PtTheme.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      entries[i].when,
                      style: Trellis.text(9.5, color: PtTheme.muted),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
