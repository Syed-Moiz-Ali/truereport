import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_theme.dart';
import '../dashboard_feed.dart';
import 'trellis_ui.dart';

Future<void> showTrellisAttentionSheet({
  required BuildContext context,
  required UiMessageStrings strings,
  required List<DashboardAttention> entries,
  required ValueChanged<String> onOpen,
  required VoidCallback onHealth,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: PtTheme.border)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: PtTheme.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.tKey(
                                PlatformAdminKeys.dashboardNeedsAttentionTitle,
                              ),
                              style: Trellis.text(19, weight: FontWeight.w800),
                            ),
                          ),
                          TrellisPill(
                            label: '${entries.length}',
                            tone: entries.isEmpty
                                ? TrellisTone.positive
                                : TrellisTone.warning,
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: strings.tKey(CommonKeys.buttonClose),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: PtTheme.muted,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            strings.tKey(
                              PlatformAdminKeys.dashboardNeedsAttentionEmpty,
                            ),
                            style: Trellis.body,
                          ),
                        )
                      else
                        for (final entry in entries)
                          _SheetRow(
                            entry: entry,
                            onTap: entry.canOpen
                                ? () {
                                    Navigator.of(sheetContext).pop();
                                    onOpen(entry.route);
                                  }
                                : null,
                          ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TrellisButton(
                          label: strings.tKey(
                            PlatformAdminKeys.dashboardQuickActionsViewHealth,
                          ),
                          icon: Icons.arrow_outward_rounded,
                          variant: TrellisButtonVariant.secondary,
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            onHealth();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.entry, required this.onTap});

  final DashboardAttention entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = switch (entry.severity) {
      DashboardSeverity.critical => PtTheme.rose,
      DashboardSeverity.warning => PtTheme.amber,
      DashboardSeverity.info => const Color(0xFF1D4ED8),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: PtTheme.border)),
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: 17, color: tone),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      style: Trellis.text(12.5, weight: FontWeight.w700),
                    ),
                    if (entry.meta.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.meta,
                        style: Trellis.text(11, color: PtTheme.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (entry.actionLabel.trim().isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  entry.actionLabel,
                  style: Trellis.text(
                    11.5,
                    weight: FontWeight.w700,
                    color: PtTheme.deepGreen,
                  ),
                ),
              ],
              if (entry.canOpen) ...[
                const SizedBox(width: 6),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 17,
                  color: PtTheme.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
