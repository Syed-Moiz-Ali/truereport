import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
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
  // Localization states
  bool _arabicRtlEnabled = true;
  bool _spanishEnabled = true;
  bool _frenchEnabled = true;

  // Security & Access states
  String _sessionTimeout = '30 Minutes';
  bool _enforce2fa = true;
  bool _ipWhitelistEnabled = false;
  String _auditTokenEncryption = 'ED25519-SHA512';

  // Automated Fleet Dispatch & Webhooks states
  bool _telematicsIngestion = true;
  bool _instantPdfGeneration = true;

  // Developer seed state (moved out of the Checklist UI).
  bool _seeding = false;

  Future<void> _seedChecklist() async {
    final strings = ref.watch(uiStringsProvider);
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
      _showSeedMessage(
        strings.tArgsKey(PlatformAdminKeys.toastSeedSuccess, {
          'created': result.created,
          'skipped': result.skipped,
        }),
      );
    } catch (error) {
      if (!mounted) return;
      _showSeedMessage(
        '${strings.tKey(PlatformAdminKeys.toastSeedFailed)}: $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  void _showSeedMessage(String message, {bool isError = false}) {
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

  void _discardChanges() {
    final strings = ref.read(uiStringsProvider);
    setState(() {
      _arabicRtlEnabled = true;
      _spanishEnabled = true;
      _frenchEnabled = true;
      _sessionTimeout = '30 Minutes';
      _enforce2fa = true;
      _ipWhitelistEnabled = false;
      _auditTokenEncryption = 'ED25519-SHA512';
      _telematicsIngestion = true;
      _instantPdfGeneration = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.tKey(PlatformAdminKeys.settingsPreferencesReset)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _savePreferences() {
    final strings = ref.read(uiStringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('snackbar-save-settings'),
        content: Text(strings.tKey(PlatformAdminKeys.settingsPreferencesSaved)),
        backgroundColor: PtTheme.emerald,
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
                // 1. Header & Scope Badge
                _buildHeaderSection(isCompact),
                const SizedBox(height: 24),

                // 2. Languages & Coverage summary (sub-page: /settings/languages)
                // Kept prominent at the top: it is the entry point to the
                // language registry, translation coverage and queue.
                LanguagesCoverageSummaryCard(
                  onOpen: () => context.go('/settings/languages'),
                ),

                const SizedBox(height: 24),

                // 3. Main Settings Cards (Bento layout)
                if (constraints.maxWidth >= 960)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildLocalizationCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildSecurityCard()),
                    ],
                  )
                else ...[
                  _buildLocalizationCard(),
                  const SizedBox(height: 20),
                  _buildSecurityCard(),
                ],

                const SizedBox(height: 24),

                // 4. Automated Fleet Dispatch & Webhooks (Full-width spanning)
                _buildWebhooksCard(isCompact),

                const SizedBox(height: 24),

                // 5. Developer seed section (moved out of the Checklist UI).
                _buildDeveloperCard(),

                const SizedBox(height: 32),

                // 6. Action Bar / Bottom Confirmation
                _buildActionBar(isCompact),
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

  Widget _buildLocalizationCard() {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.settingsLocalizationTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        16,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tKey(PlatformAdminKeys.settingsLocalizationDesc),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: PtTheme.border),
                ),
                child: Text(
                  strings.tArgsKey(
                    PlatformAdminKeys.settingsLocalizationCount,
                    const {'count': 3},
                  ),
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w700,
                    color: PtTheme.emerald,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: PtTheme.border),
          const SizedBox(height: 16),

          // Toggles
          _buildToggleRow(
            key: const Key('switch-arabic-rtl'),
            header: strings.tKey(PlatformAdminKeys.settingsEnableArabicRtl),
            description: strings.tKey(
              PlatformAdminKeys.settingsEnableArabicRtlDesc,
            ),
            value: _arabicRtlEnabled,
            onChanged: (val) async {
              setState(() => _arabicRtlEnabled = val);
              final manifest = ref.read(platformUiManifestProvider);
              final fallback = manifest?.defaultLanguage ?? 'en';
              var target = fallback;
              if (val && manifest != null) {
                for (final language in manifest.languages) {
                  if (language.isRtl) {
                    target = language.code;
                    break;
                  }
                }
              }
              await ref.read(uiMessageSwitcherProvider).switchTo(target);
            },
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            key: const Key('switch-spanish'),
            header: strings.tKey(PlatformAdminKeys.settingsEnableSpanish),
            description: strings.tKey(
              PlatformAdminKeys.settingsEnableSpanishDesc,
            ),
            value: _spanishEnabled,
            onChanged: (val) => setState(() => _spanishEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            key: const Key('switch-french'),
            header: strings.tKey(PlatformAdminKeys.settingsEnableFrench),
            description: strings.tKey(
              PlatformAdminKeys.settingsEnableFrenchDesc,
            ),
            value: _frenchEnabled,
            onChanged: (val) => setState(() => _frenchEnabled = val),
          ),

          const SizedBox(height: 20),

          // Footnote Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PtTheme.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: PtTheme.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.tKey(
                      PlatformAdminKeys.settingsLocalizationFootnote,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: PtTheme.font(
                      11,
                      lineHeight: 16,
                      weight: FontWeight.w400,
                      color: PtTheme.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    Icons.shield_outlined,
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
                      strings.tKey(PlatformAdminKeys.settingsSecurityTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        16,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tKey(PlatformAdminKeys.settingsSecurityDesc),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 20),
          const Divider(height: 1, color: PtTheme.border),
          const SizedBox(height: 16),

          // Control 1: Session Timeout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    strings.tKey(PlatformAdminKeys.settingsSessionTimeoutDesc),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: PtTheme.font(
                      12,
                      lineHeight: 16,
                      weight: FontWeight.w400,
                      color: PtTheme.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: PlatformDropdown<String>(
                  key: const Key('dropdown-session-timeout'),
                  label: strings.tKey(
                    PlatformAdminKeys.settingsSessionTimeoutLabel,
                  ),
                  value: _sessionTimeout,
                  onChanged: (val) {
                    if (val != null) setState(() => _sessionTimeout = val);
                  },
                  items: [
                    DropdownMenuItem(
                      value: '15 Minutes',
                      child: Text(
                        strings.tKey(PlatformAdminKeys.settingsFifteenMinutes),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '30 Minutes',
                      child: Text(
                        strings.tKey(PlatformAdminKeys.settingsThirtyMinutes),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '1 Hour',
                      child: Text(
                        strings.tKey(PlatformAdminKeys.settingsOneHour),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '4 Hours',
                      child: Text(
                        strings.tKey(PlatformAdminKeys.settingsFourHours),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Control 2: 2FA
          _buildToggleRow(
            key: const Key('switch-2fa'),
            header: strings.tKey(PlatformAdminKeys.settingsEnforce2fa),
            description: strings.tKey(PlatformAdminKeys.settingsEnforce2faDesc),
            value: _enforce2fa,
            onChanged: (val) => setState(() => _enforce2fa = val),
          ),

          const SizedBox(height: 16),

          // Control 3: IP Restriction Whitelist
          _buildToggleRow(
            key: const Key('switch-ip-whitelist'),
            header: strings.tKey(PlatformAdminKeys.settingsIpWhitelist),
            description: strings.tKey(
              PlatformAdminKeys.settingsIpWhitelistDesc,
            ),
            value: _ipWhitelistEnabled,
            onChanged: (val) => setState(() => _ipWhitelistEnabled = val),
          ),

          const SizedBox(height: 16),

          // Control 4: Audit Token Encryption
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.tKey(
                    PlatformAdminKeys.settingsAuditTokenEncryptionLabel,
                  ),
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PtTheme.border),
                ),
                child: Text(
                  _auditTokenEncryption,
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                    tracking: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebhooksCard(bool isCompact) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    Icons.cloud_sync_outlined,
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
                      strings.tKey(PlatformAdminKeys.settingsWebhooksTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        16,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tKey(PlatformAdminKeys.settingsWebhooksDesc),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
              if (!isCompact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PtTheme.canvas,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: PtTheme.border),
                  ),
                  child: Text(
                    strings.tKey(PlatformAdminKeys.settingsWebhooksStatus),
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.emerald,
                    ),
                  ),
                ),
            ],
          ),

          if (isCompact) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: PtTheme.border),
              ),
              child: Text(
                strings.tKey(PlatformAdminKeys.settingsWebhooksStatus),
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.emerald,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1, color: PtTheme.border),
          const SizedBox(height: 16),

          // Row 1: Real-Time Telematics Ingestion
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          strings.tKey(
                            PlatformAdminKeys.settingsTelematicsTitle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            14,
                            lineHeight: 20,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PtTheme.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            strings.tKey(
                              PlatformAdminKeys.settingsTelematicsBadge,
                            ),
                            style: PtTheme.font(
                              9,
                              lineHeight: 12,
                              weight: FontWeight.w700,
                              color: PtTheme.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tKey(PlatformAdminKeys.settingsTelematicsDesc),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 12),
              Switch.adaptive(
                key: const Key('switch-telematics'),
                value: _telematicsIngestion,
                activeTrackColor: PtTheme.deepGreen,
                onChanged: (val) => setState(() => _telematicsIngestion = val),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Instant PDF Generation
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          strings.tKey(PlatformAdminKeys.settingsPdfTitle),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            14,
                            lineHeight: 20,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PtTheme.canvas,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: PtTheme.border),
                          ),
                          child: Text(
                            strings.tKey(PlatformAdminKeys.settingsPdfBadge),
                            style: PtTheme.font(
                              9,
                              lineHeight: 12,
                              weight: FontWeight.w700,
                              color: PtTheme.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tKey(PlatformAdminKeys.settingsPdfDesc),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 12),
              Switch.adaptive(
                key: const Key('switch-pdf-generation'),
                value: _instantPdfGeneration,
                activeTrackColor: PtTheme.deepGreen,
                onChanged: (val) => setState(() => _instantPdfGeneration = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required Key key,
    required String header,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  header,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 12),
          Switch.adaptive(
            key: key,
            value: value,
            activeTrackColor: PtTheme.deepGreen,
            onChanged: onChanged,
          ),
        ],
      ),
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

  Widget _buildActionBar(bool isCompact) {
    final strings = ref.watch(uiStringsProvider);
    final note = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_done_rounded, size: 16, color: PtTheme.muted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            strings.tKey(PlatformAdminKeys.settingsActionBarNote),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w500,
              color: PtTheme.muted,
            ),
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformSecondaryButton(
          key: const Key('btn-discard-settings'),
          label: strings.tKey(CommonKeys.buttonDiscard),
          onPressed: _discardChanges,
        ),
        const SizedBox(width: 12),
        PlatformPrimaryButton(
          key: const Key('btn-save-settings'),
          label: strings.tKey(PlatformAdminKeys.settingsPreferencesSave),
          icon: Icons.check_rounded,
          onPressed: _savePreferences,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          note,
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: actions,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: note),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }
}
