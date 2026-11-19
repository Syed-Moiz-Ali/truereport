import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'dashboard_palette.dart';
import 'dashboard_primitives.dart';

@immutable
class DashboardCommand {
  const DashboardCommand({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Four destinations, one surface. Navigation choices are tiles, not cards:
/// icon, label, target. No descriptions, no second action.
class DashboardCommands extends StatelessWidget {
  const DashboardCommands({
    super.key,
    required this.strings,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final ValueChanged<String> onOpen;

  List<DashboardCommand> _commands() => [
    DashboardCommand(
      label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshop),
      icon: Icons.add_business_outlined,
      route: '/workshops/new',
    ),
    DashboardCommand(
      label: strings.tKey(
        PlatformAdminKeys.dashboardQuickActionsAddChecklistItem,
      ),
      icon: Icons.post_add_outlined,
      route: '/checklist/items/new',
    ),
    DashboardCommand(
      label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguage),
      icon: Icons.translate_rounded,
      route: '/settings/languages',
    ),
    DashboardCommand(
      label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsViewHealth),
      icon: Icons.health_and_safety_outlined,
      route: '/checklist/health',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final commands = _commands();
    return DashboardSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 4 : 2;
          final width = constraints.maxWidth / columns;
          return Wrap(
            children: [
              for (var i = 0; i < commands.length; i++)
                SizedBox(
                  width: width,
                  child: _CommandCell(
                    command: commands[i],
                    topBorder: i >= columns,
                    startBorder: i % columns != 0,
                    onTap: () => onOpen(commands[i].route),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CommandCell extends StatelessWidget {
  const _CommandCell({
    required this.command,
    required this.topBorder,
    required this.startBorder,
    required this.onTap,
  });

  final DashboardCommand command;
  final bool topBorder;
  final bool startBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          top: topBorder
              ? BorderSide(color: palette.hairline)
              : BorderSide.none,
          start: startBorder
              ? BorderSide(color: palette.hairline)
              : BorderSide.none,
        ),
      ),
      child: DashboardPressable(
        onTap: onTap,
        semanticLabel: command.label,
        borderRadius: 8,
        builder: (context, state) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            color: state.hovered ? palette.hover : Colors.transparent,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(command.icon, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    command.label,
                    style: DashboardType.meta(palette.ink).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.north_east_rounded,
                  size: 13,
                  color: palette.muted.withValues(alpha: 0.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
