import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'language_failures.dart';
import 'language_form_rules.dart';

/// Opens the Add-language dialog and returns the created/reactivated language.
///
/// The dialog owns the POST so a 409 can keep the typed values on screen; the
/// calling page only navigates and confirms.
Future<PlatformLanguage?> showAddLanguageDialog(BuildContext context) {
  return showDialog<PlatformLanguage>(
    context: context,
    builder: (dialogContext) => const Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: AddLanguageDialog(),
    ),
  );
}

class AddLanguageDialog extends ConsumerStatefulWidget {
  const AddLanguageDialog({super.key});

  @override
  ConsumerState<AddLanguageDialog> createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends ConsumerState<AddLanguageDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _direction = 'ltr';
  String? _serverError;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(platformConfigActionsProvider)
          .createLanguage(
            code: normalizeLanguageCode(_codeController.text),
            nativeName: _nameController.text.trim(),
            direction: _direction,
          );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      setState(() => _serverError = languageCreateErrorText(strings, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformDialogShell(
      title: strings.tKey(PlatformAdminKeys.languagesAddButton),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformTextField(
              key: const Key('add-language-code'),
              controller: _codeController,
              autofocus: true,
              label: strings.tKey(PlatformAdminKeys.languagesAddFieldCode),
              hint: strings.tKey(PlatformAdminKeys.languagesAddFieldCodeHint),
              helperText: strings.tKey(
                PlatformAdminKeys.languagesAddFieldCodeHelper,
              ),
              inputFormatters: const [_LowercaseFormatter()],
              validator: (value) => validateLanguageCode(strings, value),
            ),
            const SizedBox(height: 14),
            PlatformTextField(
              key: const Key('add-language-native-name'),
              controller: _nameController,
              label: strings.tKey(
                PlatformAdminKeys.languagesAddFieldNativeName,
              ),
              hint: strings.tKey(
                PlatformAdminKeys.languagesAddFieldNativeNameHint,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => validateLanguageNativeName(strings, value),
            ),
            const SizedBox(height: 14),
            PlatformDropdown<String>(
              key: const Key('add-language-direction'),
              label: strings.tKey(PlatformAdminKeys.languagesAddFieldDirection),
              value: _direction,
              items: [
                DropdownMenuItem(
                  value: 'ltr',
                  child: Text(
                    strings.tKey(PlatformAdminKeys.labelDirectionLtr),
                  ),
                ),
                DropdownMenuItem(
                  value: 'rtl',
                  child: Text(
                    strings.tKey(PlatformAdminKeys.labelDirectionRtl),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _direction = value ?? 'ltr'),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 14),
              _DialogError(message: _serverError!),
            ],
          ],
        ),
      ),
      actions: [
        PlatformGhostButton(
          key: const Key('add-language-cancel'),
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        PlatformPrimaryButton(
          key: const Key('add-language-submit'),
          label: strings.tKey(PlatformAdminKeys.languagesAddSubmit),
          isLoading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Server rejection (409 / 422) shown inside the still-open dialog.
class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('add-language-error'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: PtTheme.rose.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PtTheme.rose.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: PtTheme.rose,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: PtTheme.font(12, lineHeight: 17, color: PtTheme.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language tags are stored lowercase; fix casing as the admin types so the
/// validation error is about the shape of the tag, not the shift key.
class _LowercaseFormatter extends TextInputFormatter {
  const _LowercaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    if (lower == newValue.text) return newValue;
    final offset = newValue.selection.baseOffset;
    return newValue.copyWith(
      text: lower,
      selection: TextSelection.collapsed(
        offset: offset < 0 ? lower.length : offset.clamp(0, lower.length),
      ),
      composing: TextRange.empty,
    );
  }
}
