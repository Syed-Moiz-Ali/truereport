import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_shell.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../languages/languages_screen.dart';

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
    return PlatformShell(
      currentRoute: '/settings',
      showSearch: false,
      child: PlatformPage(
        maxWidth: 1040,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(isCompact),
                const SizedBox(height: 24),
                LanguagesCoverageSummaryCard(
                  onOpen: () => context.go('/settings/languages'),
                ),
                const SizedBox(height: 24),
                _buildDeveloperCard(),
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
    final titleBlock = Column(
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

    final envBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: PtTheme.emerald,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x6610B981), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Production Cluster EU-West',
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 14), envBadge],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        envBadge,
      ],
    );
  }

  Widget _buildDeveloperCard() {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: const Center(
                  child: Icon(
                    Icons.cloud_download_outlined,
                    color: PtTheme.deepGreen,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.buttonSeedLoadDefault),
                      style: PtTheme.font(
                        16,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tKey(PlatformAdminKeys.dialogSeedConfirm),
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w400,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: [
              PlatformPrimaryButton(
                key: const Key('btn-developer-seed'),
                label: strings.tKey(PlatformAdminKeys.buttonSeedLoadDefault),
                icon: Icons.cloud_download_outlined,
                isLoading: _seeding,
                onPressed: _seeding ? null : _seedChecklist,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
