import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../platform_theme.dart';
import 'atlas/atlas_ui.dart';

class WorkshopReasonDialog extends StatefulWidget {
  const WorkshopReasonDialog({
    super.key,
    required this.strings,
    required this.title,
    required this.confirmLabel,
    required this.destructive,
    this.body,
  });

  final UiMessageStrings strings;
  final String title;
  final String confirmLabel;
  final bool destructive;
  final String? body;

  @override
  State<WorkshopReasonDialog> createState() => _WorkshopReasonDialogState();
}

class _WorkshopReasonDialogState extends State<WorkshopReasonDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AtlasDialogShell(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.body != null && widget.body!.isNotEmpty) ...[
            Text(
              widget.body!,
              style: Atlas.text(13, height: 1.5, color: PtTheme.muted),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            widget.strings.tKey(CommonKeys.fieldReason),
            style: Atlas.text(12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            style: Atlas.text(13.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.strings.tKey(CommonKeys.fieldReason),
              hintStyle: Atlas.text(13, color: PtTheme.muted),
              filled: true,
              fillColor: PtTheme.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              constraints: const BoxConstraints(minHeight: Atlas.fieldHeight),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Atlas.fieldRadius),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Atlas.fieldRadius),
                borderSide: const BorderSide(
                  color: PtTheme.deepGreen,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        AtlasButton(
          label: widget.strings.tKey(CommonKeys.buttonCancel),
          variant: AtlasButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AtlasButton(
          label: widget.confirmLabel,
          variant: widget.destructive
              ? AtlasButtonVariant.danger
              : AtlasButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}
