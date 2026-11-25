import 'package:auth/src/auth_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import 'signin/signin_keys.dart';

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
    final t = UiStrings.of(context);
    return AppScaffold(
      appBar: AppBar(
        title: Text(t(SignInKeys.appTitle)),
        actions: [
          IconButton(
            tooltip: t(SignInKeys.signOut),
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
                            label: _roleLabel(t, role),
                            tone: StatusTone.info,
                            icon: Icons.badge_outlined,
                          ),
                          SizedBox(height: context.spacing.lg),
                          Text(
                            t(SignInKeys.homeTitle),
                            style: context.texts.headlineMedium,
                          ),
                          SizedBox(height: context.spacing.sm),
                          Text(
                            t(SignInKeys.homeBody),
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

  String _roleLabel(UiStrings t, Role role) => switch (role) {
    Role.technician => t(SignInKeys.roleTechnician),
    Role.workshopAdmin => t(SignInKeys.roleWorkshopAdmin),
    Role.platformAdmin => t(SignInKeys.rolePlatformAdmin),
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
