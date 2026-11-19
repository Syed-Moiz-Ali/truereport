import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Scoped house style for the queue.
///
/// The workshop kit is frozen at 10 px controls / 14 px cards. Instant UI asks
/// for a rounded family on this screen only, so the tokens are overridden for
/// the queue subtree: 14 px controls at 48 px, 16 px cards, pill chips, 20 px
/// dialogs, 24 px sheet corners. Nothing else in the app changes.
class QueueTheme extends StatelessWidget {
  const QueueTheme({required this.child, this.base, super.key});

  final Widget child;

  /// Optional base tokens (the dark evidence harness supplies its own).
  final WorkshopTokens? base;

  /// House-style radii and heights applied on top of [source].
  static WorkshopTokens rounded(WorkshopTokens source) => source.copyWith(
    controlRadius: 14,
    cardRadius: 16,
    cardLargeRadius: 20,
    chipRadius: 999,
    controlHeight: 48,
    touchTarget: 48,
    cardPadding: 18,
    cardPaddingDesktop: 20,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = rounded(
      base ??
          theme.extension<WorkshopTokens>() ??
          WorkshopTokens.standard(theme.textTheme),
    );
    return Theme(
      data: theme.copyWith(extensions: <ThemeExtension<dynamic>>[tokens]),
      child: child,
    );
  }
}
