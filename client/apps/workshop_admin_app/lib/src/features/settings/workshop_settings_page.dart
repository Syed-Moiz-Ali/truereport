import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Workshop settings: only real session data and real preferences.
///
/// No feature toggles, no security options and no invented account fields —
/// the workshop, account, language and sign-out rows are all wired to live
/// providers.
class WorkshopSettingsPage extends ConsumerWidget {
  const WorkshopSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final session = ref.watch(authControllerProvider).value;
    final displayName = session?.user.displayName.trim() ?? '';
    final email = session?.user.email.trim() ?? '';
    final workshopName = session != null && session.memberships.isNotEmpty
        ? session.memberships.first.workshopName
        : l10n.workshopAdminTitle;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return WorkshopPageScroll(
      key: const Key('settings-screen'),
      children: [
        WorkshopPageHeader(
          title: l10n.settings,
          subtitle: l10n.settingsSubtitle,
        ),
        SizedBox(height: spacing.lg),
        WorkshopSectionHeader(title: l10n.settingsWorkshop),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: _ValueRow(label: l10n.wsName, value: workshopName),
        ),
        SizedBox(height: spacing.lg),
        WorkshopSectionHeader(title: l10n.settingsAccount),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkshopAvatar(
                initials: _initials(displayName),
                semanticLabel: displayName.isEmpty
                    ? l10n.roleWorkshopAdmin
                    : displayName,
                size: 44,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName.isEmpty
                          ? l10n.roleWorkshopAdmin
                          : displayName,
                      style: ws.bodyStrong,
                    ),
                    if (email.isNotEmpty) ...[
                      SizedBox(height: spacing.xxs),
                      Text(email, style: ws.meta.copyWith(color: ws.muted)),
                    ],
                    SizedBox(height: spacing.xxs),
                    Text(
                      l10n.roleWorkshopAdmin,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        WorkshopSectionHeader(title: l10n.settingsPreferences),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LanguageOption(
                label: l10n.languageEnglish,
                selected: !isArabic,
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en')),
              ),
              const WorkshopDivider(),
              _LanguageOption(
                key: const Key('settings-language-ar'),
                label: l10n.languageArabic,
                selected: isArabic,
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('ar')),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        WorkshopSectionHeader(title: l10n.settingsSession),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsSignOutBody,
                style: ws.body.copyWith(color: ws.ink),
              ),
              SizedBox(height: spacing.md),
              WorkshopButton(
                key: const Key('settings-sign-out'),
                label: l10n.signOut,
                icon: Icons.logout,
                variant: WorkshopButtonVariant.danger,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ws.meta.copyWith(color: ws.muted)),
        SizedBox(height: context.spacing.xxs),
        Text(value, style: ws.bodyStrong),
      ],
    );
  }
}

class _LanguageOption extends StatefulWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LanguageOption> createState() => _LanguageOptionState();
}

class _LanguageOptionState extends State<_LanguageOption> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(const Duration(milliseconds: 140)),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ws.cardRadius),
          boxShadow: _focused ? context.shadows.focusRing : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: BorderRadius.circular(ws.cardRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: ws.touchTarget),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ws.cardPadding,
                  vertical: spacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: widget.selected ? ws.accent : ws.muted,
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: widget.selected ? ws.bodyStrong : ws.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}
