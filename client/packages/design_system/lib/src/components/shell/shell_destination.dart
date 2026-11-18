import 'package:flutter/widgets.dart';

/// A workshop shell navigation entry.
///
/// [key] is placed on the rendered navigation item so tests, deep links and the
/// shell's own analytics can target it (`workshop-tab-*`).
@immutable
class WorkshopNavDestination {
  const WorkshopNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.key,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Key? key;
}
