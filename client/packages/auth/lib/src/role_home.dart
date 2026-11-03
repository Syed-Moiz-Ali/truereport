import 'package:auth/src/auth_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class RoleHomeScaffold extends StatelessWidget {
  const RoleHomeScaffold({
    required this.role,
    required this.onSignOut,
    required this.onLanguageChanged,
    required this.locale,
    super.key,
  });

  final Role role;
  final VoidCallback onSignOut;
  final ValueChanged<Locale> onLanguageChanged;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          AppButton(
            label: locale.languageCode == 'ar'
                ? l10n.languageEnglish
                : l10n.languageArabic,
            onPressed: () => onLanguageChanged(
              locale.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar'),
            ),
            variant: AppButtonVariant.text,
          ),
          IconButton(
            tooltip: l10n.signOut,
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 900
              ? constraints.maxWidth * 0.58
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: width,
              child: ListView(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                children: [
                  FadeInCard(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusChip(
                            label: _roleLabel(l10n, role),
                            tone: StatusTone.info,
                            icon: Icons.badge_outlined,
                          ),
                          SizedBox(height: context.spacing.lg),
                          Text(
                            l10n.homeTitle,
                            style: context.texts.headlineMedium,
                          ),
                          SizedBox(height: context.spacing.sm),
                          Text(
                            l10n.homeBody,
                            style: context.texts.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, Role role) => switch (role) {
    Role.technician => l10n.roleTechnician,
    Role.workshopAdmin => l10n.roleWorkshopAdmin,
    Role.platformAdmin => l10n.rolePlatformAdmin,
  };
}

class RoleHomeShell extends ConsumerWidget {
  const RoleHomeShell({required this.role, super.key});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return RoleHomeScaffold(
      role: role,
      locale: locale,
      onLanguageChanged: ref.read(localeProvider.notifier).setLocale,
      onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
    );
  }
}
