import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../reference_status_lookup.dart';
import 'add_language_dialog.dart';

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
    final coverage = ref.watch(translationCoverageProvider);
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
    final hasLanguages =
        (manifest?.languages.isNotEmpty ?? false) || registryOnly.isNotEmpty;

    Future<void> addLanguage() async {
      final created = await showAddLanguageDialog(context);
      if (created == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.deepGreen,
          content: Text(strings.tKey(PlatformAdminKeys.languagesAddToastReady)),
        ),
      );
      context.go('/settings/languages/${created.code}');
    }

    return PlatformShell(
      currentRoute: '/settings/languages',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageSettingsTitle),
            onTap: () => context.go('/settings'),
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
              for (final language
                  in manifest?.languages ?? const <UiMessageLanguage>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LanguageCard(
                    key: ValueKey('language-card-${language.code}'),
                    code: language.code,
                    manifestLanguage: language,
                    registryLanguage: registryByCode[language.code],
                    isDefault:
                        registryByCode[language.code]?.isDefault ??
                        language.code == manifest?.defaultLanguage,
                  ),
                ),
              if (registryOnly.isNotEmpty) ...[
                PlatformSectionHeader(
                  title: strings.tKey(PlatformAdminKeys.languagesRegistryTitle),
                  subtitle: strings.tKey(
                    PlatformAdminKeys.languagesRegistrySubtitle,
                  ),
                ),
                const SizedBox(height: 12),
                for (final language in registryOnly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LanguageCard(
                      key: ValueKey('language-card-${language.code}'),
                      code: language.code,
                      manifestLanguage: null,
                      registryLanguage: language,
                      isDefault: language.isDefault,
                    ),
                  ),
              ],
            ],
            const SizedBox(height: 8),
            _CoverageSection(
              coverage: coverage,
              onRetry: () => ref.invalidate(translationCoverageProvider),
            ),
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
    final defaultLanguage = manifest?.defaultLanguage ?? 'en';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PlatformMetaPill(
          label: strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
          value: '$languages',
        ),
        PlatformStatusChip(
          status:
              '${strings.tKey(PlatformAdminKeys.pageLanguagesDefaultLanguage)}: $defaultLanguage',
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

/// One language row-card. [manifestLanguage] is null for languages that are
/// registered in the backend but do not ship a UI catalog file yet.
class _LanguageCard extends ConsumerWidget {
  const _LanguageCard({
    super.key,
    required this.code,
    required this.manifestLanguage,
    required this.registryLanguage,
    required this.isDefault,
  });

  final String code;
  final UiMessageLanguage? manifestLanguage;
  final PlatformLanguage? registryLanguage;
  final bool isDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final readiness = registryLanguage == null
        ? null
        : ref.watch(readinessProvider(code)).asData?.value;
    final manifest = manifestLanguage;
    final missing = manifest?.missingKeys ?? 0;
    final valid = manifest == null
        ? registryLanguage?.isLive ?? false
        : missing == 0 && manifest.placeholderMismatch == 0;
    final displayName =
        registryLanguage?.displayName ?? manifest?.displayName ?? code;

    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldLanguageCode),
                value: code,
              ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldLanguageDirection),
                value:
                    registryLanguage?.direction ?? manifest?.direction ?? 'ltr',
              ),
              PlatformStatusChip(
                status: valid
                    ? strings.tKey(CommonKeys.statusHealthy)
                    : strings.tKey(CommonKeys.statusUnhealthy),
              ),
              if (readiness != null)
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceFieldContentCoverage,
                  ),
                  value:
                      '${readiness.contentApproved}/${readiness.contentTotal}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          if (manifest != null) ...[
            const SizedBox(height: 2),
            Text(
              '${strings.tKey(PlatformAdminKeys.fieldLanguageUiMessagesPath)}: '
              '${manifest.path.isEmpty ? '-' : manifest.path}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
            const SizedBox(height: 2),
            Text(
              '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage)}: '
              '${manifest.totalKeys - manifest.missingKeys}/${manifest.totalKeys}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ] else ...[
            const SizedBox(height: 2),
            Text(
              strings.tKey(PlatformAdminKeys.languagesRegistryNoCatalog),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
            if (registryLanguage != null) ...[
              const SizedBox(height: 4),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.languagesRegistryStatus),
                value: referenceCodeLabel(
                  strings,
                  ref.watch(statusesProvider(translationStatusDomain)).value,
                  registryLanguage!.status,
                ),
              ),
            ],
          ],
          if (registryLanguage != null && !isDefault) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlatformPrimaryButton(
                  key: ValueKey('view-$code'),
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceButtonManage,
                  ),
                  icon: Icons.tune_rounded,
                  onPressed: () => context.go('/settings/languages/$code'),
                ),
                PlatformSecondaryButton(
                  key: ValueKey('translate-$code'),
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationQueueTitle,
                  ),
                  icon: Icons.translate_rounded,
                  onPressed: () =>
                      context.go('/settings/languages/$code/translations'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverageSection extends StatelessWidget {
  const _CoverageSection({required this.coverage, required this.onRetry});

  final AsyncValue<TranslationCoverage> coverage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return PlatformSectionCard(
      child: coverage.when(
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformSectionHeader(
              title: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
            ),
            const SizedBox(height: 12),
            PlatformSecondaryButton(
              label: strings.tKey(CommonKeys.buttonRetry),
              onPressed: onRetry,
            ),
          ],
        ),
        data: (data) {
          final namespaces = data.namespaces.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformSectionHeader(
                title: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in data.languages)
                    PlatformStatusChip(status: language),
                ],
              ),
              const SizedBox(height: 16),
              if (namespaces.isEmpty)
                Text(
                  strings.tKey(CommonKeys.emptyTitle),
                  style: PtTheme.font(13, color: PtTheme.muted),
                )
              else
                for (final entry in namespaces) ...[
                  Text(
                    entry.key,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${strings.tKey(PlatformAdminKeys.queueTotal)}: ${entry.value.total} · '
                    '${strings.tKey(PlatformAdminKeys.pageLanguagesMissingTranslations)}: ${entry.value.missing.length}',
                    style: PtTheme.font(12, color: PtTheme.muted),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

/// Summary card for the Settings landing (`/settings`).
///
/// Shows the manifest language count, active count, default language and
/// translation coverage state plus a single action that opens the full
/// [LanguagesScreen] (`/settings/languages`).
class LanguagesCoverageSummaryCard extends ConsumerWidget {
  const LanguagesCoverageSummaryCard({super.key, this.onOpen});

  /// Overrides the default navigation to `/settings/languages`.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final registry = ref.watch(platformLanguagesProvider);
    final coverage = ref.watch(translationCoverageProvider);

    void open() {
      if (onOpen != null) {
        onOpen!();
        return;
      }
      try {
        GoRouter.of(context).go('/settings/languages');
      } catch (_) {
        // No router in scope (e.g. isolated widget test): stay put.
      }
    }

    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
            subtitle: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
          ),
          const SizedBox(height: 12),
          if (manifest == null)
            const SizedBox.shrink()
          else
            coverage.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => PlatformErrorView(
                message: strings.tKey(CommonKeys.statusUnhealthy),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: () => ref.invalidate(translationCoverageProvider),
              ),
              data: (data) {
                var missing = 0;
                for (final namespace in data.namespaces.values) {
                  missing += namespace.missing.length;
                }
                final healthy = missing == 0;
                var defaultName = manifest.defaultLanguage;
                for (final language
                    in registry.asData?.value ?? const <PlatformLanguage>[]) {
                  if (language.code == manifest.defaultLanguage) {
                    defaultName = language.displayName;
                    break;
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.pageLanguagesTitle,
                          ),
                          value: '${manifest.languages.length}',
                        ),
                        PlatformStatusChip(
                          status:
                              '${strings.tKey(PlatformAdminKeys.pageLanguagesDefaultLanguage)}: $defaultName',
                        ),
                        PlatformStatusChip(
                          status: healthy
                              ? strings.tKey(CommonKeys.statusHealthy)
                              : strings.tKey(CommonKeys.statusUnhealthy),
                        ),
                        if (missing > 0)
                          PlatformMetaPill(
                            label: strings.tKey(
                              PlatformAdminKeys
                                  .pageLanguagesMissingTranslations,
                            ),
                            value: '$missing',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PlatformSecondaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys.pageLanguagesTitle,
                          ),
                          icon: Icons.translate_rounded,
                          onPressed: open,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
