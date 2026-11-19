import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../signin_tokens.dart';

/// A labelled credential cell for "The dock".
///
/// The label is persistent above the cell (never a placeholder), the input is
/// LTR in both locales, and validation messages render under the cell so the
/// dock grows upward from its fixed bottom edge instead of shifting the
/// primary action.
class SignInField extends StatefulWidget {
  const SignInField({
    required this.controller,
    required this.label,
    required this.validator,
    this.focusNode,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.suffix,
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final FocusNode? focusNode;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final Widget? suffix;
  final Key? fieldKey;

  @override
  State<SignInField> createState() => _SignInFieldState();
}

class _SignInFieldState extends State<SignInField> {
  FocusNode? _internalFocus;

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void dispose() {
    _internalFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final labelStyle = isArabic
        ? Fx.text(12, 16, FontWeight.w600, 0, color: scheme.onSurfaceVariant)
        : Fx.label12Wide.copyWith(color: scheme.onSurfaceVariant);

    return FormField<String>(
      validator: (_) => widget.validator(widget.controller.text),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
            const SizedBox(height: SignInDims.labelGap),
            ListenableBuilder(
              listenable: _focus,
              builder: (context, _) {
                final focused = _focus.hasFocus;
                final invalid = state.hasError;
                final borderColor = invalid
                    ? scheme.error
                    : focused
                    ? scheme.primary
                    : scheme.outlineVariant;
                return Semantics(
                  label: widget.label,
                  textField: true,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: SignInDims.cellHeight,
                    ),
                    padding: const EdgeInsetsDirectional.only(
                      start: 14,
                      end: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? scheme.surfaceContainerLowest
                          : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(
                        SignInDims.cellRadius,
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: focused || invalid ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: widget.fieldKey,
                            controller: widget.controller,
                            focusNode: _focus,
                            enabled: widget.enabled,
                            obscureText: widget.obscure,
                            keyboardType: widget.keyboardType,
                            textInputAction: widget.textInputAction,
                            textCapitalization: widget.textCapitalization,
                            autofillHints: widget.autofillHints,
                            inputFormatters: widget.inputFormatters,
                            autofocus: widget.autofocus,
                            autocorrect: widget.autocorrect,
                            enableSuggestions: widget.enableSuggestions,
                            onSubmitted: widget.onSubmitted,
                            onChanged: (value) {
                              widget.onChanged?.call(value);
                              state.didChange(value);
                            },
                            // Identifiers and codes stay LTR in both locales.
                            textDirection: TextDirection.ltr,
                            style: isArabic
                                ? Fx.text(
                                    16,
                                    24,
                                    FontWeight.w500,
                                    0,
                                    color: scheme.onSurface,
                                  )
                                : Fx.text(
                                    16,
                                    24,
                                    FontWeight.w500,
                                    -0.16,
                                    color: scheme.onSurface,
                                  ),
                            cursorColor: scheme.primary,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        ?widget.suffix,
                      ],
                    ),
                  ),
                );
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    state.errorText!,
                    maxLines: 2,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w500,
                      0,
                      color: scheme.error,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
