import 'package:flutter/material.dart';

import '../tokens.dart';
import 'buttons.dart';

/// Maps a backend tone token to the design-system tone.
///
/// Unknown tokens fall back to neutral so a newer backend value never crashes
/// or renders an unstyled chip.
StatusTone statusToneFromToken(String token) {
  return switch (token.toLowerCase()) {
    'success' || 'positive' => StatusTone.success,
    'warning' || 'caution' => StatusTone.warning,
    'danger' || 'error' || 'negative' => StatusTone.danger,
    'critical' => StatusTone.critical,
    'info' || 'accent' || 'primary' => StatusTone.info,
    _ => StatusTone.neutral,
  };
}

/// Closed-list dropdown for backend-owned options.
///
/// Presentational only: the caller supplies already-resolved labels and the
/// list. Disabled options stay visible but cannot be chosen.
class OptionDropdown<T> extends StatelessWidget {
  const OptionDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    this.enabledOf,
    this.hint,
    this.isExpanded = true,
    super.key,
  });

  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T item) labelOf;
  final bool Function(T item)? enabledOf;
  final String? hint;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.radii.md),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: isExpanded,
          isDense: true,
          hint: hint == null ? null : Text(hint!),
          onChanged: onChanged,
          items: <DropdownMenuItem<T>>[
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                enabled: enabledOf?.call(item) ?? true,
                child: Text(
                  labelOf(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders only the allowed transition actions.
///
/// The caller passes candidate records (from `/reference/transitions/{entity}`)
/// and an [allowedOf] predicate; entries that are not allowed are not built at
/// all, so a disabled action can never be tapped.
class TransitionActions<T> extends StatelessWidget {
  const TransitionActions({
    required this.records,
    required this.labelOf,
    required this.onTap,
    this.allowedOf,
    this.iconOf,
    super.key,
  });

  final List<T> records;
  final String Function(T record) labelOf;
  final ValueChanged<T> onTap;
  final bool Function(T record)? allowedOf;
  final IconData? Function(T record)? iconOf;

  @override
  Widget build(BuildContext context) {
    final allowed = records
        .where((record) => allowedOf?.call(record) ?? true)
        .toList(growable: false);
    if (allowed.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      children: <Widget>[
        for (final record in allowed)
          AppButton(
            label: labelOf(record),
            icon: iconOf?.call(record),
            variant: AppButtonVariant.tonal,
            onPressed: () => onTap(record),
          ),
      ],
    );
  }
}
