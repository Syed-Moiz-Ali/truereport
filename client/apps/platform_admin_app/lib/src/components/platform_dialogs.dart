import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../platform_theme.dart';

/// Shared dialog shell: 18px w800 title, consistent content padding,
/// Cancel + Primary actions, max-width 560 for forms, scrollable content,
/// full-screen sheet on compact widths.
class PlatformDialogShell extends StatelessWidget {
  const PlatformDialogShell({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.maxWidth = 560,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final dialog = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(compact ? 20 : 16),
            child: Padding(
              padding: EdgeInsets.all(compact ? 20 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: PtTheme.font(
                            18,
                            lineHeight: 24,
                            weight: FontWeight.w800,
                            color: PtTheme.ink,
                            tracking: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.close ??
                            'Close',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(child: body),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        if (compact) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: SingleChildScrollView(child: dialog),
              ),
            ),
          );
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: dialog,
          ),
        );
      },
    );
  }
}

/// Shows a [PlatformDialogShell] as a real dialog route (focus-trapped by
/// the framework). Returns the value passed to `Navigator.pop`, if any.
Future<T?> showPlatformDialog<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
  double maxWidth = 560,
}) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: PlatformDialogShell(
        title: title,
        maxWidth: maxWidth,
        body: body,
        actions: actionsBuilder?.call(dialogContext) ?? const [],
      ),
    ),
  );
}

/// Standard destructive confirm dialog (e.g. retire-in-use). Returns true
/// when the primary action is tapped.
Future<bool> showPlatformConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
  final confirmed = await showPlatformDialog<bool>(
    context: context,
    title: title,
    body: Text(
      body,
      style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: Text(l10n?.cancel ?? 'Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        style: FilledButton.styleFrom(
          backgroundColor:
              destructive ? PtTheme.rose : PtTheme.deepGreen,
        ),
        child: Text(confirmLabel),
      ),
    ],
  );
  return confirmed == true;
}
