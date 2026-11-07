import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  String? consequence,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      final consequenceColor = destructive
          ? dialogContext.statusColors.danger.foreground
          : colors.onSurfaceVariant;
      return AlertDialog(
        title: Text(title, style: dialogContext.texts.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: dialogContext.texts.bodyMedium),
              if (consequence != null) ...[
                SizedBox(height: dialogContext.spacing.sm),
                Text(
                  consequence,
                  style: dialogContext.texts.bodyMedium?.copyWith(
                    color: consequenceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              cancelLabel ??
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Modal bottom sheet with explicit Esc-to-close and focus return.
///
/// Esc is handled by an explicit [Shortcuts]/[Actions] pair (the framework
/// route also dismisses on system back); focus returns to the invoker via
/// [FocusManager.primaryFocus] capture, matching [WorkshopSideSheet].
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) async {
  final previouslyFocused = FocusManager.instance.primaryFocus;
  try {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.colors.surfaceContainerLowest,
      barrierColor: context.colors.scrim,
      builder: (sheetContext) => Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                Navigator.of(sheetContext).maybePop();
                return null;
              },
            ),
          },
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: sheetContext.spacing.lg,
              end: sheetContext.spacing.lg,
              bottom:
                  MediaQuery.viewInsetsOf(sheetContext).bottom +
                  sheetContext.spacing.lg,
            ),
            child: child,
          ),
        ),
      ),
    );
  } finally {
    previouslyFocused?.requestFocus();
  }
}

abstract final class AppSnackBar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colors = context.colors;
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: context.sizing.iconMd,
                color: colors.onInverseSurface,
              ),
              SizedBox(width: context.spacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  IconData? icon,
  Duration duration = const Duration(seconds: 4),
}) {
  return AppSnackBar.show(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    icon: icon,
    duration: duration,
  );
}
