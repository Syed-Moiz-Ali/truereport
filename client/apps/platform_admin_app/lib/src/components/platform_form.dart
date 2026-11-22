import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform_theme.dart';

/// Consistent pill-free 16px-radius, 56px-min-height input used by every
/// Platform Admin form. The label sits above the field; the placeholder is the
/// caller's hint (or the label) and is vertically centred inside the input.
/// Validation messages wrap; inputs expand to available width.
class PlatformTextField extends StatelessWidget {
  const PlatformTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.textDirection,
    this.autofocus = false,
    this.textInputAction,
    this.inputFormatters,
    this.onFieldSubmitted,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final TextDirection? textDirection;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;
    // The label already sits above the field; only a genuinely different hint
    // belongs inside, otherwise the same text renders twice.
    final placeholder = (hint != null && hint!.isNotEmpty) ? hint : null;

    final field = TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      textDirection: textDirection,
      autofocus: autofocus,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      style: PtTheme.font(14, lineHeight: 20, color: PtTheme.ink),
      textAlignVertical: maxLines > 1
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      decoration: PtTheme.fieldDecoration(
        hint: placeholder,
        helperText: helperText,
        hintSize: 14,
      ),
    );

    if (!hasLabel) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label!,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: FontWeight.w500,
            color: PtTheme.muted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // The visible label sits above the field, so associate it explicitly:
        // without this the input has no accessible name (and `getByLabel`
        // cannot find it).
        Semantics(label: label, child: field),
      ],
    );
  }
}

/// Shared dropdown with the same frame as [PlatformTextField].
class PlatformDropdown<T> extends StatelessWidget {
  const PlatformDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: FontWeight.w500,
            color: PtTheme.muted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            decoration: PtTheme.fieldDecoration(),
            style: PtTheme.font(14, lineHeight: 20, color: PtTheme.ink),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Section title (16px w700) with optional trailing header action.
class PlatformSectionHeader extends StatelessWidget {
  const PlatformSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: PtTheme.sectionTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: PtTheme.bodyMuted,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}
