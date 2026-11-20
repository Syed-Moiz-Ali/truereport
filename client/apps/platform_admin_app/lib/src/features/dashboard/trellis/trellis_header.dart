import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'trellis_ui.dart';

class TrellisHeader extends StatelessWidget {
  const TrellisHeader({
    super.key,
    required this.strings,
    required this.onRefresh,
    required this.width,
  });

  final UiMessageStrings strings;
  final VoidCallback onRefresh;
  final double width;

  @override
  Widget build(BuildContext context) {
    final compact = width < 700;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.sectionDashboardKpis),
          style: Trellis.eyebrow,
        ),
        const SizedBox(height: 8),
        Text(
          strings.tKey(PlatformAdminKeys.pageDashboardTitle),
          style: Trellis.pageTitle,
        ),
        const SizedBox(height: 5),
        Text(
          strings.tKey(PlatformAdminKeys.pageDashboardSubtitle),
          style: Trellis.body,
        ),
      ],
    );
    final refresh = TrellisButton(
      label: strings.tKey(CommonKeys.buttonRefresh),
      icon: Icons.refresh_rounded,
      variant: TrellisButtonVariant.secondary,
      onPressed: onRefresh,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 14),
          Align(alignment: AlignmentDirectional.centerStart, child: refresh),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        refresh,
      ],
    );
  }
}
