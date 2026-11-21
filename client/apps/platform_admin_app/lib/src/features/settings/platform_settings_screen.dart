import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_shell.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../languages/languages_screen.dart';
import '../workshops/workshop_activity.dart';

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState
    extends ConsumerState<PlatformSettingsScreen> {
  bool _seeding = false;

  Future<void> _seedChecklist() async {
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(PlatformAdminKeys.buttonSeedLoadDefault),
      body: strings.tKey(PlatformAdminKeys.dialogSeedConfirm),
      confirmLabel: strings.tKey(CommonKeys.buttonSave),
    );
    if (confirmed != true) return;
    setState(() => _seeding = true);
    try {
      final result = await ref.read(platformConfigActionsProvider).seed();
      if (!mounted) return;
      _showMessage(
        strings.tArgsKey(PlatformAdminKeys.toastSeedSuccess, {
          'created': result.created,
          'skipped': result.skipped,
        }),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        '${strings.tKey(PlatformAdminKeys.toastSeedFailed)}: $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(
          message,
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final audit = ref.watch(auditEventsProvider);
    final health = ref.watch(configHealthProvider);
    return PlatformShell(
      currentRoute: '/settings',
      showSearch: false,
      child: PlatformPage(
        maxWidth: 1040,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final cardWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - 16) / 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(isCompact),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: LanguagesCoverageSummaryCard(
                        onOpen: () => context.go('/settings/languages'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildAuditCard(strings, audit),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildHealthCard(strings, health),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildDeveloperCard(strings),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildTaxonomyCard(strings),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildTranslationReviewCard(strings),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isCompact) {
    final strings = ref.watch(uiStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.settingsScopeBadge),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PtTheme.font(
            11,
            lineHeight: 14,
            weight: FontWeight.w700,
            color: PtTheme.emerald,
            tracking: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.tKey(PlatformAdminKeys.pageSettingsHeading),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PtTheme.font(
            isCompact ? 22 : 28,
            lineHeight: 34,
            weight: FontWeight.w700,
            color: PtTheme.ink,
            tracking: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.tKey(PlatformAdminKeys.pageSettingsSubtitle),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: PtTheme.font(
            13,
            lineHeight: 18,
            weight: FontWeight.w400,
            color: PtTheme.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildAuditCard(
    UiMessageStrings strings,
    AsyncValue<List<PlatformAuditEvent>> audit,
  ) {
    final data = audit.when(
      loading: () => Text(strings.tKey(CommonKeys.stateLoading)),
      error: (_, _) => Text(strings.tKey(CommonKeys.stateError)),
      data: (events) {
        if (events.isEmpty) {
          return Text(strings.tKey(PlatformAdminKeys.settingsAuditNoEvents));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              events.length == 1
                  ? strings.tKey(PlatformAdminKeys.settingsAuditEventOne)
                  : strings.tArgsKey(
                      PlatformAdminKeys.settingsAuditEventsCount,
                      {'count': '${events.length}'},
                    ),
              style: PtTheme.font(
                12,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${strings.tKey(PlatformAdminKeys.filterAuditAction)}: '
              '${auditActionLabel(strings, events.first.action)}',
              style: PtTheme.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
    return _SettingsHubCard(
      icon: Icons.policy_outlined,
      title: strings.tKey(PlatformAdminKeys.settingsAuditTitle),
      body: strings.tKey(PlatformAdminKeys.settingsAuditBody),
      data: data,
      action: PlatformSecondaryButton(
        label: strings.tKey(PlatformAdminKeys.buttonAuditViewAll),
        icon: Icons.arrow_outward_rounded,
        onPressed: () => context.go('/audit-log'),
      ),
    );
  }

  Widget _buildHealthCard(
    UiMessageStrings strings,
    AsyncValue<ConfigHealth> health,
  ) {
    final data = health.when(
      loading: () => Text(strings.tKey(CommonKeys.stateLoading)),
      error: (_, _) => Text(strings.tKey(CommonKeys.stateError)),
      data: (data) {
        final issues = data.checks.where((check) => !check.ok).length;
        return Text(
          '${strings.tKey(PlatformAdminKeys.checklistHealthTotalChecks)}: '
          '${data.checks.length} · '
          '${strings.tKey(PlatformAdminKeys.checklistHealthIssuesFound)}: '
          '$issues',
          style: PtTheme.bodyMuted,
        );
      },
    );
    return _SettingsHubCard(
      icon: Icons.health_and_safety_outlined,
      title: strings.tKey(PlatformAdminKeys.pageHealthTitle),
      body: strings.tKey(PlatformAdminKeys.settingsHealthBody),
      data: data,
      action: PlatformSecondaryButton(
        label: strings.tKey(PlatformAdminKeys.buttonHealthReview),
        icon: Icons.fact_check_outlined,
        onPressed: () => context.go('/checklist/health'),
      ),
    );
  }

  Widget _buildTranslationReviewCard(UiMessageStrings strings) {
    return _SettingsHubCard(
      icon: Icons.translate_rounded,
      title: strings.tKey(PlatformAdminKeys.settingsTranslationReviewTitle),
      body: strings.tKey(PlatformAdminKeys.settingsTranslationReviewBody),
      data: const SizedBox.shrink(),
      action: PlatformGhostButton(
        key: const Key('open-translation-review'),
        label: strings.tKey(PlatformAdminKeys.settingsTranslationReviewAction),
        onPressed: () => context.go('/configuration/translations'),
      ),
    );
  }

  Widget _buildTaxonomyCard(UiMessageStrings strings) {
    return _SettingsHubCard(
      icon: Icons.account_tree_outlined,
      title: strings.tKey(PlatformAdminKeys.taxonomySectionTitle),
      body: strings.tKey(PlatformAdminKeys.taxonomyPageTitle),
      data: Text(
        <String>[
          strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
          strings.tKey(PlatformAdminKeys.referenceTransitionsTitle),
        ].join(' · '),
        style: PtTheme.bodyMuted,
      ),
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          PlatformGhostButton(
            key: const Key('open-option-sets'),
            label: strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
            onPressed: () => context.go('/checklist/option-sets'),
          ),
          PlatformGhostButton(
            key: const Key('open-reference-transitions'),
            label: strings.tKey(PlatformAdminKeys.referenceTransitionsTitle),
            onPressed: () => context.go('/configuration/transitions'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(UiMessageStrings strings) {
    return _SettingsHubCard(
      icon: Icons.construction_outlined,
      title: strings.tKey(PlatformAdminKeys.settingsMaintenanceTitle),
      body: strings.tKey(PlatformAdminKeys.settingsMaintenanceBody),
      data: Text(
        strings.tKey(PlatformAdminKeys.dialogSeedConfirm),
        style: PtTheme.bodyMuted,
      ),
      action: PlatformPrimaryButton(
        key: const Key('btn-developer-seed'),
        label: strings.tKey(PlatformAdminKeys.buttonSeedLoadDefault),
        icon: Icons.cloud_download_outlined,
        isLoading: _seeding,
        onPressed: _seeding ? null : _seedChecklist,
      ),
    );
  }
}

class _SettingsHubCard extends StatelessWidget {
  const _SettingsHubCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.data,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget data;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return PlatformSectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, color: PtTheme.deepGreen, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: PtTheme.font(
                    15,
                    lineHeight: 21,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: PtTheme.bodyMuted),
          const SizedBox(height: 10),
          data,
          const SizedBox(height: 14),
          Align(alignment: AlignmentDirectional.centerStart, child: action),
        ],
      ),
    );
  }
}
