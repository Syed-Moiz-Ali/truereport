import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
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
          Localizations.of<AppLocalizations>(context, AppLocalizations)?.preferencesReset ??
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
          Localizations.of<AppLocalizations>(context, AppLocalizations)?.preferencesSaved ??
              'Platform preferences saved and propagated to edge nodes!',
        ),
        backgroundColor: PtTheme.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isCompact = constraints.maxWidth < 620;

        return Scaffold(
          backgroundColor: PtTheme.white,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                const PlatformSidebar(currentRoute: '/settings'),
              Expanded(
                child: Column(
                  children: [
                    const PlatformHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 16 : 32,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Header & Scope Badge
                                _buildHeaderSection(isCompact),
                                const SizedBox(height: 24),

                                // 2. Main Settings Cards (Bento layout)
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

                                // 3. Automated Fleet Dispatch & Webhooks (Full-width spanning)
                                _buildWebhooksCard(isCompact),

                                const SizedBox(height: 32),

                                // 4. Action Bar / Bottom Confirmation
                                _buildActionBar(isCompact),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isCompact) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONFIGURATION SCOPE • GLOBAL ROOT',
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
              boxShadow: [
                BoxShadow(
                  color: Color(0x6610B981),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Production Cluster EU-West',
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 14),
          envBadge,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        envBadge,
      ],
    );
  }

  Widget _buildLocalizationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            header: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enableArabicRtl ??
                'Enable Arabic (RTL) Localization',
            description: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enableArabicRtlDesc ??
                'Auto-reverses layout coordinates and inspector forms',
            value: _arabicRtlEnabled,
            onChanged: (val) {
              setState(() => _arabicRtlEnabled = val);
              if (val) {
                ref.read(platformLocaleProvider.notifier).setLocale(const Locale('ar'));
              } else {
                ref.read(platformLocaleProvider.notifier).setLocale(const Locale('en'));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            key: const Key('switch-spanish'),
            header: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enableSpanish ??
                'Enable Spanish Support',
            description: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enableSpanishDesc ??
                'Workshop regional standard (es-MX / es-ES)',
            value: _spanishEnabled,
            onChanged: (val) => setState(() => _spanishEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            key: const Key('switch-french'),
            header: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enableFrench ??
                'Enable French Support',
            description: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enableFrenchDesc ??
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Session Timeout',
                      style: PtTheme.font(
                        14,
                        lineHeight: 20,
                        weight: FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatic revocation after period of inactivity',
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
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PtTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('dropdown-session-timeout'),
                    value: _sessionTimeout,
                    icon: const Icon(Icons.arrow_drop_down, color: PtTheme.muted),
                    style: PtTheme.font(
                      12,
                      lineHeight: 16,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _sessionTimeout = val);
                    },
                    items: [
                      DropdownMenuItem(
                        value: '15 Minutes',
                        child: Text(
                          Localizations.of<AppLocalizations>(context, AppLocalizations)?.fifteenMinutes ??
                              '15 Minutes',
                        ),
                      ),
                      DropdownMenuItem(
                        value: '30 Minutes',
                        child: Text(
                          Localizations.of<AppLocalizations>(context, AppLocalizations)?.thirtyMinutes ??
                              '30 Minutes',
                        ),
                      ),
                      DropdownMenuItem(
                        value: '1 Hour',
                        child: Text(
                          Localizations.of<AppLocalizations>(context, AppLocalizations)?.oneHour ??
                              '1 Hour',
                        ),
                      ),
                      DropdownMenuItem(
                        value: '4 Hours',
                        child: Text(
                          Localizations.of<AppLocalizations>(context, AppLocalizations)?.fourHours ??
                              '4 Hours',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Control 2: 2FA
          _buildToggleRow(
            key: const Key('switch-2fa'),
            header: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enforce2fa ??
                'Enforce 2FA (TOTP) for All Admins',
            description: Localizations.of<AppLocalizations>(context, AppLocalizations)?.enforce2faDesc ??
                'Mandatory hardware security key or authenticator app',
            value: _enforce2fa,
            onChanged: (val) => setState(() => _enforce2fa = val),
          ),

          const SizedBox(height: 16),

          // Control 3: IP Restriction Whitelist
          _buildToggleRow(
            key: const Key('switch-ip-whitelist'),
            header: Localizations.of<AppLocalizations>(context, AppLocalizations)?.ipWhitelist ??
                'IP Restriction Whitelist',
            description: Localizations.of<AppLocalizations>(context, AppLocalizations)?.ipWhitelistDesc ??
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          style: PtTheme.font(
                            14,
                            lineHeight: 20,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                          style: PtTheme.font(
                            14,
                            lineHeight: 20,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
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
    );
  }

  Widget _buildActionBar(bool isCompact) {
    final note = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_done_rounded,
          size: 16,
          color: PtTheme.muted,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'All changes sync immediately to edge nodes upon save',
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
        // Discard Button
        OutlinedButton(
          key: const Key('btn-discard-settings'),
          onPressed: _discardChanges,
          style: OutlinedButton.styleFrom(
            backgroundColor: PtTheme.canvas,
            foregroundColor: PtTheme.ink,
            side: const BorderSide(color: PtTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Discard',
            style: PtTheme.font(
              13,
              lineHeight: 18,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Save Button (Chunky Solid Emerald CTA)
        ElevatedButton.icon(
          key: const Key('btn-save-settings'),
          onPressed: _savePreferences,
          icon: const Icon(Icons.check_rounded, size: 18, color: PtTheme.white),
          label: Text(
            'Save Platform Preferences',
            style: PtTheme.font(
              13,
              lineHeight: 18,
              weight: FontWeight.w600,
              color: PtTheme.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: PtTheme.emerald,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: note),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }
}
