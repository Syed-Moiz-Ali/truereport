import 'package:design_system/design_system.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:flutter/material.dart';

/// A compact single-choice group built from workshop filter chips.
///
/// The wizard's odometer unit, transmission and fuel values are client
/// conventions with no server enum and no ARB label, so they are humanized here
/// instead of printing raw upper-case codes. The preferred-language values are
/// backend codes and pass their manifest display names through [labelFor].
/// A change request for first-class labels is recorded in
/// `docs/change_requests.md` (CR-9).
class WizardChoiceGroup extends StatelessWidget {
  const WizardChoiceGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.keyPrefix,
    this.labelFor,
    super.key,
  });

  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final String keyPrefix;
  final String Function(String value)? labelFor;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ws.bodyStrong),
        SizedBox(height: spacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              JobPillChip(
                key: Key('$keyPrefix-${value.toLowerCase()}'),
                label: labelFor?.call(value) ?? humanizeChoice(value),
                selected: selected == value,
                onTap: () => onChanged(value),
              ),
          ],
        ),
      ],
    );
  }
}

/// Presentation for a client-convention value: `AUTOMATIC` -> `Automatic`,
/// while short acronyms such as `KM`, `MI` and `CVT` stay upper-case.
String humanizeChoice(String value) {
  final upper = value.toUpperCase();
  if (upper == 'KM' || upper == 'MI' || upper == 'CVT') {
    return upper;
  }
  final lower = value.toLowerCase();
  if (lower.isEmpty) {
    return value;
  }
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}
