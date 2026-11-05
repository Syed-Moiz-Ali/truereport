import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textDirection,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  bool _focused = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocus);
    _focused = _effectiveFocusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      final oldNode = oldWidget.focusNode ?? _internalFocusNode;
      oldNode?.removeListener(_handleFocus);
      if (widget.focusNode != null && _internalFocusNode != null) {
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
      final newNode = _effectiveFocusNode..addListener(_handleFocus);
      _focused = newNode.hasFocus;
    }
  }

  void _handleFocus() {
    if (mounted) {
      setState(() => _focused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocus);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final spacing = context.spacing;
    final radii = context.radii;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(radii.xl);

    return Semantics(
      textField: true,
      label: widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: sizing.inputHeight),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textDirection: widget.textDirection,
              autofillHints: widget.autofillHints,
              validator: widget.validator,
              onFieldSubmitted: widget.onFieldSubmitted,
              onChanged: widget.onChanged,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              textInputAction: widget.textInputAction,
              textAlignVertical: widget.maxLines == 1
                  ? TextAlignVertical.center
                  : TextAlignVertical.top,
              style: texts.bodyLarge?.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceContainer,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.lg,
                  vertical: spacing.md,
                ),
                labelText: widget.label,
                hintText: widget.hint,
                helperText: widget.helperText,
                errorText: widget.errorText,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                prefixText: widget.prefixText,
                suffixText: widget.suffixText,
                alignLabelWithHint: widget.maxLines > 1,
                labelStyle: texts.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                floatingLabelStyle: texts.labelLarge?.copyWith(
                  color: _focused ? context.brand.ink : colors.onSurfaceVariant,
                ),
                hintStyle: texts.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                helperStyle: texts.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                errorStyle: texts.bodySmall?.copyWith(color: colors.error),
                prefixIconColor: colors.onSurfaceVariant,
                suffixIconColor: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
