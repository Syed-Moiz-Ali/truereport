import 'package:design_system/src/components/workshop_ui.dart';
import 'package:design_system/src/tokens.dart';
import 'package:design_system/src/workshop_tokens.dart';
import 'package:flutter/material.dart';

/// The shell's identity strip (direction C "The dock").
///
/// 44 px tall: the brand mark, the workshop name, the language control, the
/// notification action and the account menu. It is the only place the workshop is
/// named, and the only place the language can be changed without opening a menu.
///
/// At phone widths the wordmark text is dropped first (the mark stays), then the
/// workshop name ellipsizes; nothing wraps and the strip never grows.
class ShellIdentityStrip extends StatelessWidget {
  const ShellIdentityStrip({
    required this.workshopName,
    required this.accountInitials,
    required this.accountName,
    required this.accountEmail,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    required this.settingsLabel,
    required this.signOutLabel,
    this.notificationsAction,
    super.key,
  });

  final String workshopName;
  final String accountInitials;
  final String accountName;
  final String accountEmail;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;
  final String settingsLabel;
  final String signOutLabel;
  final Widget? notificationsAction;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        return Container(
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? spacing.md : spacing.xl,
          ),
          decoration: BoxDecoration(
            border: BorderDirectional(bottom: BorderSide(color: ws.border)),
          ),
          child: Row(
            children: [
              const ShellBrandMark(),
              if (!compact) ...[
                SizedBox(width: spacing.sm),
                Text(
                  'TrueReport',
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
                SizedBox(width: spacing.md),
                Container(width: 1, height: 18, color: ws.border),
                SizedBox(width: spacing.md),
              ] else
                SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  workshopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
              // English-only product: no language switcher in the shell.
              if (notificationsAction != null) ...[
                notificationsAction!,
                SizedBox(width: spacing.sm),
              ],
              WorkshopAccountMenu(
                compact: true,
                initials: accountInitials,
                displayName: accountName,
                email: accountEmail,
                onSettings: onSettings,
                onSignOut: onSignOut,
                onToggleLanguage: onToggleLanguage,
                languageLabel: languageLabel,
                settingsLabel: settingsLabel,
                signOutLabel: signOutLabel,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The product mark: a 26 px accent tile with the initials.
class ShellBrandMark extends StatelessWidget {
  const ShellBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ws.accent,
        borderRadius: BorderRadius.circular(ws.chipRadius),
      ),
      child: Text(
        'TR',
        style: ws.meta.copyWith(
          color: ws.onAccent,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Visible language switch: one tap, labelled with the language it switches *to*.
class ShellLanguageControl extends StatelessWidget {
  const ShellLanguageControl({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: true,
          borderRadius: BorderRadius.circular(ws.chipRadius),
          child: Container(
            constraints: BoxConstraints(minHeight: ws.touchTarget),
            padding: EdgeInsets.symmetric(horizontal: spacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: ws.border),
              borderRadius: BorderRadius.circular(ws.chipRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate, size: 14, color: ws.muted),
                SizedBox(width: spacing.xs),
                Text(
                  label,
                  style: ws.meta.copyWith(
                    color: ws.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
