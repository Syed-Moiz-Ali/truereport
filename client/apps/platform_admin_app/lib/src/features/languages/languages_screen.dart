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

/// Read-only language registry.
///
/// Static languages and their JSON catalogs come from the backend manifest.
/// There is no add, generate, review, approve or publish action: adding a
/// language means adding a JSON file and a manifest entry, then restarting the
/// backend. Dynamic content coverage is shown per language when the language
/// has a dynamic translation registry row.
class LanguagesScreen extends ConsumerWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final manifest = ref.watch(platformUiManifestProvider);
    final registry = ref.watch(platformLanguagesProvider);
    final coverage = ref.watch(translationCoverageProvider);
    final registryByCode = <String, PlatformLanguage>{
      for (final language
          in registry.asData?.value ?? const <PlatformLanguage>[])
        language.code: language,
    };

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
            ),
            const SizedBox(height: 12),
            _StaticManifestNotice(child: _manifestSummary(strings, manifest)),
            const SizedBox(height: 16),
            if (manifest == null)
              const SizedBox.shrink()
            else if (manifest.languages.isEmpty)
              PlatformEmptyView(
                icon: Icons.translate_rounded,
                title: strings.tKey(CommonKeys.emptyTitle),
              )
            else
              for (final language in manifest.languages) ...[
                _StaticLanguageCard(
                  language: language,
                  dynamicLanguage: registryByCode[language.code],
                ),
                const SizedBox(height: 12),
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
                  strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
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

class _StaticLanguageCard extends ConsumerWidget {
  const _StaticLanguageCard({
    required this.language,
    required this.dynamicLanguage,
  });

  final UiMessageLanguage language;
  final PlatformLanguage? dynamicLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final readiness = dynamicLanguage == null
        ? null
        : ref.watch(readinessProvider(language.code)).asData?.value;
    final missing = language.missingKeys;
    final valid = missing == 0 && language.placeholderMismatch == 0;

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
                value: language.code,
              ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldLanguageDirection),
                value: language.direction,
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
            language.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${strings.tKey(PlatformAdminKeys.fieldLanguageUiMessagesPath)}: '
            '${language.path.isEmpty ? '-' : language.path}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
          const SizedBox(height: 2),
          Text(
            '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage)}: '
            '${language.totalKeys - language.missingKeys}/${language.totalKeys}'
            '${language.placeholderMismatch > 0 ? ' · ${strings.tKey(CommonKeys.statusUnhealthy)}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
          if (dynamicLanguage != null && !dynamicLanguage!.isDefault) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlatformPrimaryButton(
                  key: ValueKey('view-${language.code}'),
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceButtonManage,
                  ),
                  icon: Icons.tune_rounded,
                  onPressed: () =>
                      context.go('/settings/languages/${language.code}'),
                ),
                PlatformSecondaryButton(
                  key: ValueKey('translate-${language.code}'),
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationQueueTitle,
                  ),
                  icon: Icons.translate_rounded,
                  onPressed: () => context.go(
                    '/settings/languages/${language.code}/translations',
                  ),
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
