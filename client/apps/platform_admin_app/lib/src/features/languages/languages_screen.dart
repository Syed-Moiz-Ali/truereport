import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'add_language_dialog.dart';
import 'language_cards.dart';
import 'language_registry_card.dart';

/// Language registry: shipped UI-message languages plus backend-registered
/// languages that do not have a UI catalog file yet.
///
/// Static languages and their JSON catalogs come from the backend manifest.
/// Dynamic content coverage is shown per language when the language has a
/// registry row. Adding or retiring a language is a registry action; shipping
/// its interface text still requires a catalog file.
class LanguagesScreen extends ConsumerWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final registry = ref.watch(platformLanguagesProvider);
    final registryLanguages =
        registry.asData?.value ?? const <PlatformLanguage>[];
    final registryByCode = <String, PlatformLanguage>{
      for (final language in registryLanguages) language.code: language,
    };
    final manifestCodes = <String>{
      for (final language in manifest?.languages ?? const <UiMessageLanguage>[])
        language.code,
    };
    // Registry rows without a catalog file. Retired rows are not part of the
    // shipped product, so they stay out of the list; re-adding reactivates.
    final registryOnly = registryLanguages
        .where((language) => !manifestCodes.contains(language.code))
        .where((language) => !language.isRetired)
        .toList(growable: false);
    // The source language is not a translation target: it gets its own strip
    // above the grid so the grid holds only cards with coverage to review.
    final defaultCode = manifest?.defaultLanguage ?? 'en';
    final manifestLanguages =
        manifest?.languages ?? const <UiMessageLanguage>[];
    UiMessageLanguage? defaultLanguage;
    for (final language in manifestLanguages) {
      if (language.code == defaultCode) defaultLanguage = language;
    }
    final translatableLanguages = manifestLanguages
        .where((language) => language.code != defaultCode)
        .toList(growable: false);
    final hasLanguages =
        manifestLanguages.isNotEmpty || registryOnly.isNotEmpty;

    Future<void> addLanguage() async {
      final created = await showAddLanguageDialog(context);
      if (created == null || !context.mounted) return;
      // Stay on the list: the new language is already live, in languages.json
      // and in the manifest, so its card appears here (the old per-language
      // workspace route no longer exists).
      ref.invalidate(platformLanguagesProvider);
      ref.invalidate(languageCatalogProvider);
      ref.invalidate(platformUiManifestProvider);
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.deepGreen,
          content: Text(strings.tKey(PlatformAdminKeys.languagesAddToastReady)),
        ),
      );
    }

    return PlatformShell(
      currentRoute: '/profile/languages',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageProfileTitle),
            onTap: () => context.go('/profile'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
          ),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
              subtitle: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
              actions: [
                PlatformSecondaryButton(
                  key: const Key('btn-content-review'),
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewTitle,
                  ),
                  icon: Icons.rate_review_outlined,
                  onPressed: () => context.go('/configuration/translations'),
                ),
                PlatformPrimaryButton(
                  key: const Key('btn-add-language'),
                  label: strings.tKey(PlatformAdminKeys.languagesAddButton),
                  icon: Icons.add_rounded,
                  onPressed: addLanguage,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StaticManifestNotice(child: _manifestSummary(strings, manifest)),
            if (registry.hasError) ...[
              const SizedBox(height: 16),
              PlatformErrorView(
                message: strings.tKey(CommonKeys.statusUnhealthy),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: () => ref.invalidate(platformLanguagesProvider),
              ),
            ],
            const SizedBox(height: 16),
            if (!hasLanguages && manifest != null)
              PlatformEmptyView(
                icon: Icons.translate_rounded,
                title: strings.tKey(CommonKeys.emptyTitle),
              )
            else ...[
              if (defaultLanguage != null) ...[
                _SourceLanguageStrip(
                  strings: strings,
                  code: defaultLanguage.code,
                  name: defaultLanguage.displayName,
                ),
                const SizedBox(height: 16),
              ],
              LanguageGrid(
                children: [
                  for (final language in translatableLanguages)
                    LanguageRegistryCard(
                      key: ValueKey('language-card-${language.code}'),
                      code: language.code,
                      manifestLanguage: language,
                      registryLanguage: registryByCode[language.code],
                      isDefault: false,
                    ),
                ],
              ),
              if (registryOnly.isNotEmpty) ...[
                const SizedBox(height: 20),
                PlatformSectionHeader(
                  title: strings.tKey(PlatformAdminKeys.languagesRegistryTitle),
                  subtitle: strings.tKey(
                    PlatformAdminKeys.languagesRegistrySubtitle,
                  ),
                ),
                const SizedBox(height: 12),
                LanguageGrid(
                  children: [
                    for (final language in registryOnly)
                      LanguageRegistryCard(
                        key: ValueKey('language-card-${language.code}'),
                        code: language.code,
                        manifestLanguage: null,
                        registryLanguage: language,
                        isDefault: language.isDefault,
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _manifestSummary(
    UiMessageStrings strings,
    UiMessageManifest? manifest,
  ) {
    final languages = manifest?.languages.length ?? 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PlatformMetaPill(
          label: strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
          value: '$languages',
        ),
      ],
    );
  }
}

class _StaticManifestNotice extends StatelessWidget {
  const _StaticManifestNotice({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return PlatformSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.translate_rounded,
                color: PtTheme.deepGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(
                    14,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.tKey(PlatformAdminKeys.languagesRegistryNotice),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(12, color: PtTheme.muted),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The source language, kept out of the translation grid: it has nothing to
/// review and would otherwise sit as an empty card next to full ones.
class _SourceLanguageStrip extends StatelessWidget {
  const _SourceLanguageStrip({
    required this.strings,
    required this.code,
    required this.name,
  });

  final UiMessageStrings strings;
  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    return PlatformSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.language_rounded,
                color: PtTheme.deepGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$name · $code',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        14,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PtTheme.canvas,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: PtTheme.border),
                      ),
                      child: Text(
                        strings.tKey(
                          PlatformAdminKeys.pageLanguagesSourceDefault,
                        ),
                        style: PtTheme.font(
                          10.5,
                          lineHeight: 14,
                          weight: FontWeight.w700,
                          color: PtTheme.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.tKey(PlatformAdminKeys.languagesSourceLanguage),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(12, color: PtTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
