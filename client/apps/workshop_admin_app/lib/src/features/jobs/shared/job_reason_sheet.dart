import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Reason entry sheet used by cancel, unpublish and revoke flows.
/// Returns the trimmed reason, or null when dismissed.
///
/// The controller lives in [_JobReasonSheetState] so it is disposed with the
/// sheet's own widget tree, not when the route future completes: the sheet's
/// exit transition still builds the field after `pop()` (J8). Built on the
/// Workshop kit, not the legacy App widgets.
Future<String?> showJobReasonSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
}) {
  return showAppBottomSheet<String>(
    context,
    child: _JobReasonSheet(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
    ),
  );
}

class _JobReasonSheet extends StatefulWidget {
  const _JobReasonSheet({
    required this.title,
    required this.label,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String confirmLabel;

  @override
  State<_JobReasonSheet> createState() => _JobReasonSheetState();
}

class _JobReasonSheetState extends State<_JobReasonSheet> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkshopSectionHeader(title: widget.title),
          SizedBox(height: context.spacing.md),
          WorkshopTextField(
            key: const Key('job-reason-field'),
            controller: _controller,
            label: widget.label,
            onChanged: (_) {
              if (_showError) {
                setState(() => _showError = false);
              }
            },
          ),
          if (_showError) ...[
            SizedBox(height: context.spacing.xs),
            Text(
              l10n.commonReasonRequired,
              style: context.ws.meta.copyWith(color: context.ws.danger),
            ),
          ],
          SizedBox(height: context.spacing.lg),
          WorkshopButton(
            key: const Key('job-reason-confirm'),
            label: widget.confirmLabel,
            onPressed: () {
              if (_controller.text.trim().isEmpty) {
                setState(() => _showError = true);
                return;
              }
              Navigator.of(context).pop(_controller.text.trim());
            },
            expand: true,
          ),
        ],
      ),
    );
  }
}
