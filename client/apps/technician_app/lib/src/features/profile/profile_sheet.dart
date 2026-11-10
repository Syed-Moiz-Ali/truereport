import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

Future<void> showTechnicianProfile(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  final session = ref.read(authControllerProvider).value;
  final locale = ref.read(localeProvider);
  return showAppBottomSheet<void>(
    context,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TechnicianAvatar(
                name: session?.user.displayName ?? l10n.roleTechnician,
                size: context.sizing.technicianPrimaryHeight,
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session?.user.displayName ?? l10n.roleTechnician,
                      style: context.texts.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (session != null)
                      Text(
                        session.user.email,
                        textDirection: TextDirection.ltr,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.lg),
          TechnicianSectionTitle(title: l10n.technicianLanguage),
          SizedBox(height: context.spacing.sm),
          AppLanguageSwitch(
            englishLabel: l10n.languageEnglish,
            arabicLabel: l10n.languageArabic,
            isArabic: locale.languageCode == 'ar',
            onChanged: (isArabic) => ref
                .read(localeProvider.notifier)
                .setLocale(Locale(isArabic ? 'ar' : 'en')),
          ),
          SizedBox(height: context.spacing.lg),
          AppButton(
            label: l10n.signOut,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).signOut();
            },
            icon: Icons.logout,
            variant: AppButtonVariant.tonal,
            expand: true,
          ),
        ],
      ),
    ),
  );
}

