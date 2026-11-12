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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.seedDefaultChecklist,
      body: l10n.seedConfirm,
      confirmLabel: l10n.save,
    );
    if (confirmed != true) return;
    setState(() => _seeding = true);
    try {
      final result = await ref.read(platformConfigActionsProvider).seed();
      if (!mounted) return;
      _showSeedMessage(l10n.seedSuccess(result.created, result.skipped));
    } catch (error) {
      if (!mounted) return;
      _showSeedMessage('${l10n.seedFailed}: $error', isError: true);
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
        content: Text(
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.preferencesReset ??
              'Preferences reset to default values.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('snackbar-save-settings'),
        content: Text(
          Localizations.of<AppLocalizations>(
                context,
                AppLocalizations,
              )?.preferencesSaved ??
              'Platform preferences saved and propagated to edge nodes!',
        ),
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
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONFIGURATION SCOPE • GLOBAL ROOT',
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
          'Platform Settings',
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
          'Global runtime policies, regional localizations, and system authentication rules',
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
                      'Localization',
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
                      'Multilingual dictionary & typography sets',
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
                  '3 Languages',
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
            header:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enableArabicRtl ??
                'Enable Arabic (RTL) Localization',
            description:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enableArabicRtlDesc ??
                'Auto-reverses layout coordinates and inspector forms',
            value: _arabicRtlEnabled,
            onChanged: (val) {
              setState(() => _arabicRtlEnabled = val);
              if (val) {
                ref
                    .read(platformLocaleProvider.notifier)
                    .setLocale(const Locale('ar'));
              } else {
                ref
                    .read(platformLocaleProvider.notifier)
                    .setLocale(const Locale('en'));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            key: const Key('switch-spanish'),
            header:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enableSpanish ??
                'Enable Spanish Support',
            description:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enableSpanishDesc ??
                'Workshop regional standard (es-MX / es-ES)',
            value: _spanishEnabled,
            onChanged: (val) => setState(() => _spanishEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            key: const Key('switch-french'),
            header:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enableFrench ??
                'Enable French Support',
            description:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enableFrenchDesc ??
                'Quebec & European fleet inspection checklists',
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
                    'Activating a regional dialect dynamically triggers localized font subset packages via the Edge CDN to preserve 60fps rendering speed in field mobile devices.',
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
                      'Security & Access',
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
                      'Zero-trust technician permissions & token life',
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
                    'Automatic revocation after period of inactivity',
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
                  label: 'Admin Session Timeout',
                  value: _sessionTimeout,
                  onChanged: (val) {
                    if (val != null) setState(() => _sessionTimeout = val);
                  },
                  items: [
                    DropdownMenuItem(
                      value: '15 Minutes',
                      child: Text(
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.fifteenMinutes ??
                            '15 Minutes',
                      ),
                    ),
                    DropdownMenuItem(
                      value: '30 Minutes',
                      child: Text(
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.thirtyMinutes ??
                            '30 Minutes',
                      ),
                    ),
                    DropdownMenuItem(
                      value: '1 Hour',
                      child: Text(
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.oneHour ??
                            '1 Hour',
                      ),
                    ),
                    DropdownMenuItem(
                      value: '4 Hours',
                      child: Text(
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.fourHours ??
                            '4 Hours',
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
            header:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enforce2fa ??
                'Enforce 2FA (TOTP) for All Admins',
            description:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.enforce2faDesc ??
                'Mandatory hardware security key or authenticator app',
            value: _enforce2fa,
            onChanged: (val) => setState(() => _enforce2fa = val),
          ),

          const SizedBox(height: 16),

          // Control 3: IP Restriction Whitelist
          _buildToggleRow(
            key: const Key('switch-ip-whitelist'),
            header:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.ipWhitelist ??
                'IP Restriction Whitelist',
            description:
                Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.ipWhitelistDesc ??
                'Limit console access strictly to corporate diagnostic VPNs',
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
                  'Audit Token Encryption',
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
                      'Automated Fleet Dispatch & Webhooks',
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
                      'Event pipeline, real-time OBD relays, and customer certificate exports',
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
                    'Webhooks Healthy • 99.98% SLA',
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
                'Webhooks Healthy • 99.98% SLA',
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
                          'Real-Time Telematics Ingestion',
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
                            'WEBSOCKET STREAMING ACTIVE',
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
                      'Stream vehicle CAN-bus diagnostics and mileage counters live during visual lane walks.',
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
                          'Instant PDF Generation On Sign-Off',
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
                            'AUTO-DISTRIBUTION HOOK',
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
                      'Compile comprehensive inspection reports with embedded damage markup photos upon technician sign.',
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
    final l10n = AppLocalizations.of(context);
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
                      l10n.seedDefaultChecklist,
                      style: PtTheme.font(
                        16,
                        lineHeight: 22,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.seedConfirm,
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
                label: l10n.seedDefaultChecklist,
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
    final note = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_done_rounded, size: 16, color: PtTheme.muted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'All changes sync immediately to edge nodes upon save',
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
          label: 'Discard',
          onPressed: _discardChanges,
        ),
        const SizedBox(width: 12),
        PlatformPrimaryButton(
          key: const Key('btn-save-settings'),
          label: 'Save Platform Preferences',
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
