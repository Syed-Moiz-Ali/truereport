import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

enum AdminPortalType { workshop, platform }

class AdminFeatureHighlight {
  const AdminFeatureHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// Every visible string rendered by [AdminSignInView].
///
/// Platform Admin builds this from backend UI strings; Workshop Admin uses
/// [AdminSignInCopy.legacy] until its own static-text migration phase.
class AdminSignInCopy {
  const AdminSignInCopy({
    required this.appName,
    required this.portalBadge,
    required this.portalTitle,
    required this.cardEyebrow,
    required this.signInTitle,
    required this.signInSubtitle,
    required this.showcaseEyebrow,
    required this.showcaseHeadline,
    required this.showcaseSubtitle,
    required this.features,
    required this.emailLabel,
    required this.emailHint,
    required this.passwordLabel,
    required this.passwordHint,
    required this.rememberTerminal,
    required this.needHelp,
    required this.challengeTitle,
    required this.challengeBody,
    required this.codeLabel,
    required this.codeHint,
    required this.signInButton,
    required this.verifyButton,
    required this.footer,
    required this.languageLabel,
    required this.statusLabel,
    required this.statusDetails,
    required this.statusSecured,
  });

  final String appName;
  final String portalBadge;
  final String portalTitle;
  final String cardEyebrow;
  final String signInTitle;
  final String signInSubtitle;
  final String showcaseEyebrow;
  final String showcaseHeadline;
  final String showcaseSubtitle;
  final List<AdminFeatureHighlight> features;
  final String emailLabel;
  final String emailHint;
  final String passwordLabel;
  final String passwordHint;
  final String rememberTerminal;
  final String needHelp;
  final String challengeTitle;
  final String challengeBody;
  final String codeLabel;
  final String codeHint;
  final String signInButton;
  final String verifyButton;
  final String footer;
  final String languageLabel;
  final String statusLabel;
  final String statusDetails;
  final String statusSecured;

  /// Legacy Workshop Admin copy resolved from ARB localizations.
  factory AdminSignInCopy.legacy(AppLocalizations l10n, AdminPortalType type) {
    final isWorkshop = type == AdminPortalType.workshop;
    return AdminSignInCopy(
      appName: 'TrueReport',
      portalBadge: isWorkshop
          ? 'WORKSHOP OPERATIONS'
          : 'PLATFORM ADMINISTRATION',
      portalTitle: isWorkshop
          ? 'Workshop Admin Portal'
          : 'Platform Admin Gateway',
      cardEyebrow: 'AUTHORIZED ACCESS ONLY',
      signInTitle: 'Sign in to Portal',
      signInSubtitle: isWorkshop
          ? 'Enter your corporate credentials to access Workshop Admin Portal.'
          : 'Enter your corporate credentials to access Platform Admin Gateway.',
      showcaseEyebrow: isWorkshop
          ? 'HIGH-THROUGHPUT BAY DISPATCH'
          : 'MULTI-TENANT GOVERNANCE',
      showcaseHeadline: isWorkshop
          ? 'Precision Vehicle Diagnostics & Workshop Orchestration'
          : 'Global Automotive Diagnostic Network Administration',
      showcaseSubtitle: isWorkshop
          ? 'Unified operational portal for bay allocation, live inspection workflows, dynamic SOP protocols, and cryptographically verified customer reports.'
          : 'Central command hub for multi-tenant workshop networks, master checkpoint libraries, standardized data catalogues, and regulatory audit archives.',
      features: isWorkshop
          ? [
              AdminFeatureHighlight(
                icon: Icons.garage_rounded,
                title: l10n.adminFeatureTelemetry,
                description: 'Real-time job sequencing, automated bay routing, and live technician throughput dispatch.',
              ),
              AdminFeatureHighlight(
                icon: Icons.assignment_turned_in_rounded,
                title: l10n.adminFeatureSop,
                description: 'Multi-version inspection templates with required photo evidence and strict severity policies.',
              ),
              AdminFeatureHighlight(
                icon: Icons.verified_rounded,
                title: l10n.adminFeatureAudit,
                description: 'Instant client-ready report generation with tamper-evident blockchain verification.',
              ),
            ]
          : [
              AdminFeatureHighlight(
                icon: Icons.apartment_rounded,
                title: l10n.adminFeatureHierarchy,
                description: 'Workshop onboarding, staff accounts, and template assignment.',
              ),
              AdminFeatureHighlight(
                icon: Icons.menu_book_rounded,
                title: l10n.adminFeatureCatalog,
                description: 'Centralized catalog of standardized diagnostic checkpoints with bilingual labels.',
              ),
              AdminFeatureHighlight(
                icon: Icons.shield_rounded,
                title: l10n.adminFeatureLedger,
                description: 'SOC-2 compliant chronological audit events logging all platform mutations and credential resets.',
              ),
            ],
      emailLabel: 'Corporate Email Address',
      emailHint: 'name@truereport.local',
      passwordLabel: 'Password',
      passwordHint: '••••••••••••',
      rememberTerminal: 'Remember terminal',
      needHelp: 'Need help?',
      challengeTitle: 'Two-Factor Authentication Required',
      challengeBody: 'Enter the 6-digit verification code from your security authenticator.',
      codeLabel: 'Security Code',
      codeHint: '000000',
      signInButton: 'Sign In to Portal',
      verifyButton: 'Verify Security Code',
      footer: '256-bit TLS Encrypted · SOC-2 Certified',
      languageLabel: 'Language',
      statusLabel: 'GRID V4.2 ACTIVE',
      statusDetails: '·  Latency 14ms  ·  TLS 1.3',
      statusSecured: 'SECURED',
    );
  }
}

class AdminSignInView extends StatefulWidget {
  const AdminSignInView({
    super.key,
    required this.portalType,
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.formKey,
    this.isArabic,
    this.onLocaleChanged,
    this.languages,
    this.selectedLanguageCode,
    this.onLanguageSelected,
    this.copy,
    required this.onSubmit,
    required this.onValidateEmail,
    required this.onValidateRequired,
    this.challenge = false,
    this.submitting = false,
    this.errorText,
  });

  final AdminPortalType portalType;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final GlobalKey<FormState> formKey;
  final bool? isArabic;
  final ValueChanged<bool>? onLocaleChanged;
  final List<LanguageOption>? languages;
  final String? selectedLanguageCode;
  final ValueChanged<String>? onLanguageSelected;
  final AdminSignInCopy? copy;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> onValidateEmail;
  final FormFieldValidator<String> onValidateRequired;
  final bool challenge;
  final bool submitting;
  final String? errorText;

  bool get useLanguageOptions =>
      languages != null && languages!.isNotEmpty && onLanguageSelected != null;

  @override
  State<AdminSignInView> createState() => _AdminSignInViewState();
}

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.displayName,
    this.direction = 'ltr',
  });

  final String code;
  final String displayName;
  final String direction;
}

class _AdminSignInViewState extends State<AdminSignInView> {
  bool _obscurePassword = true;
  bool _rememberTerminal = true;

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy ?? _legacyCopy(context);
    final isWorkshop = widget.portalType == AdminPortalType.workshop;
    final portalBadge = copy.portalBadge;
    final showcaseEyebrow = copy.showcaseEyebrow;
    final showcaseHeadline = copy.showcaseHeadline;
    final showcaseSubtitle = copy.showcaseSubtitle;
    final features = copy.features;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          if (isDesktop) {
            return Row(
              children: [
                // Left Brand Showcase Panel (45% width)
                Expanded(
                  flex: 45,
                  child: _buildShowcasePanel(
                    copy: copy,
                    portalBadge: portalBadge,
                    showcaseEyebrow: showcaseEyebrow,
                    showcaseHeadline: showcaseHeadline,
                    showcaseSubtitle: showcaseSubtitle,
                    features: features,
                    icon: isWorkshop
                        ? Icons.precision_manufacturing_rounded
                        : Icons.hub_rounded,
                  ),
                ),

                // Right Authentication Form Panel (55% width)
                Expanded(
                  flex: 55,
                  child: _buildFormCanvas(copy: copy, isDesktop: true),
                ),
              ],
            );
          }

          // Tablet / Mobile Stack
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildMobileHeader(
                  copy: copy,
                  portalBadge: portalBadge,
                  icon: isWorkshop
                      ? Icons.precision_manufacturing_rounded
                      : Icons.hub_rounded,
                ),
                _buildFormCanvas(copy: copy, isDesktop: false),
              ],
            ),
          );
        },
      ),
    );
  }

  AdminSignInCopy _legacyCopy(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('en'));
    return AdminSignInCopy.legacy(l10n, widget.portalType);
  }

  Widget _buildShowcasePanel({
    required AdminSignInCopy copy,
    required String portalBadge,
    required String showcaseEyebrow,
    required String showcaseHeadline,
    required String showcaseSubtitle,
    required List<AdminFeatureHighlight> features,
    required IconData icon,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003824), Color(0xFF005438), Color(0xFF006C49)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Branding Header
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6FFBBE)
                                  .withValues(alpha: 0.40),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: const Color(0xFF6FFBBE),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              copy.appName,
                              style: Fx.text(
                                18,
                                22,
                                FontWeight.w800,
                                -0.3,
                                color: Fx.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              portalBadge,
                              style: Fx.text(
                                10,
                                12,
                                FontWeight.w700,
                                0.8,
                                color: const Color(0xFF6FFBBE),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 2. Center Value Proposition
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Fx.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: Fx.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6FFBBE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            showcaseEyebrow,
                            style: Fx.text(
                              10,
                              12,
                              FontWeight.w700,
                              0.6,
                              color: const Color(0xFF6FFBBE),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      showcaseHeadline,
                      style: Fx.text(
                        30,
                        36,
                        FontWeight.w800,
                        -0.6,
                        color: Fx.white,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      showcaseSubtitle,
                      style: Fx.text(
                        13,
                        20,
                        FontWeight.w400,
                        0,
                        color: Fx.white.withValues(alpha: 0.78),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. Feature Highlight Cards
                    for (final f in features) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Fx.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Fx.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  f.icon,
                                  color: const Color(0xFF6FFBBE),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.title,
                                    style: Fx.text(
                                      13,
                                      16,
                                      FontWeight.w700,
                                      0,
                                      color: Fx.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    f.description,
                                    style: Fx.text(
                                      11,
                                      15,
                                      FontWeight.w400,
                                      0,
                                      color: Fx.white.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // 4. Live System Status Strip
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: Fx.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              copy.statusLabel,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w700,
                                0.5,
                                color: const Color(0xFF6FFBBE),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              copy.statusDetails,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w400,
                                0,
                                color: Fx.white.withValues(alpha: 0.60),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF6FFBBE),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              copy.statusSecured,
                              style: Fx.text(
                                10,
                                12,
                                FontWeight.w800,
                                0.5,
                                color: const Color(0xFF6FFBBE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileHeader({
    required AdminSignInCopy copy,
    required String portalBadge,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003824), Color(0xFF006C49)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF6FFBBE), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.appName,
                style: Fx.text(18, 22, FontWeight.w800, -0.2, color: Fx.white),
              ),
              Text(
                portalBadge,
                style: Fx.text(
                  10,
                  12,
                  FontWeight.w700,
                  0.6,
                  color: const Color(0xFF6FFBBE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCanvas({
    required AdminSignInCopy copy,
    required bool isDesktop,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Switcher bar
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE9E7ED)),
                  ),
                  child: _LanguageSwitcher(
                    useOptions: widget.useLanguageOptions,
                    languages: widget.languages ?? const <LanguageOption>[],
                    selectedCode:
                        widget.selectedLanguageCode ??
                        (widget.isArabic == true ? 'ar' : 'en'),
                    legacyLabel: widget.isArabic == true
                        ? 'English'
                        : 'العربية',
                    onOptionSelected: widget.onLanguageSelected,
                    onLegacyToggle: widget.onLocaleChanged == null
                        ? null
                        : () => widget.onLocaleChanged!(
                            !(widget.isArabic ?? false),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Elevated Card
              Container(
                padding: EdgeInsets.all(isDesktop ? 36 : 22),
                decoration: BoxDecoration(
                  color: Fx.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9E7ED)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: widget.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card Eyebrow
                      Text(
                        copy.cardEyebrow,
                        style: Fx.text(
                          10,
                          14,
                          FontWeight.w700,
                          0.8,
                          color: const Color(0xFF006C49),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        copy.signInTitle,
                        style: Fx.text(
                          24,
                          30,
                          FontWeight.w700,
                          -0.4,
                          color: const Color(0xFF1A1B1F),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        copy.signInSubtitle,
                        style: Fx.text(
                          13,
                          18,
                          FontWeight.w400,
                          0,
                          color: const Color(0xFF5E5D69),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Error Banner
                      if (widget.errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFB91A24),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.errorText!,
                                  style: Fx.text(
                                    12,
                                    16,
                                    FontWeight.w500,
                                    0,
                                    color: const Color(0xFFB91A24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form Fields
                      if (!widget.challenge) ...[
                        // Email Field
                        Text(
                          copy.emailLabel,
                          style: Fx.text(
                            12,
                            16,
                            FontWeight.w600,
                            0,
                            color: const Color(0xFF1A1B1F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE9E7ED)),
                          ),
                          child: TextFormField(
                            key: const Key('sign-in-email'),
                            controller: widget.emailController,
                            validator: widget.onValidateEmail,
                            keyboardType: TextInputType.emailAddress,
                            style: Fx.text(
                              13,
                              18,
                              FontWeight.w500,
                              0,
                              color: const Color(0xFF1A1B1F),
                            ),
                            decoration: InputDecoration(
                              hintText: copy.emailHint,
                              hintStyle: Fx.text(
                                13,
                                18,
                                FontWeight.w400,
                                0,
                                color: const Color(0xFF5E5D69),
                              ),
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 18,
                                color: Color(0xFF5E5D69),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        Text(
                          copy.passwordLabel,
                          style: Fx.text(
                            12,
                            16,
                            FontWeight.w600,
                            0,
                            color: const Color(0xFF1A1B1F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE9E7ED)),
                          ),
                          child: TextFormField(
                            key: const Key('sign-in-password'),
                            controller: widget.passwordController,
                            validator: widget.onValidateRequired,
                            obscureText: _obscurePassword,
                            style: Fx.text(
                              13,
                              18,
                              FontWeight.w500,
                              0,
                              color: const Color(0xFF1A1B1F),
                            ),
                            decoration: InputDecoration(
                              hintText: copy.passwordHint,
                              hintStyle: Fx.text(
                                13,
                                18,
                                FontWeight.w400,
                                0,
                                color: const Color(0xFF5E5D69),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: Color(0xFF5E5D69),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: const Color(0xFF5E5D69),
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Remember terminal & Forgot password
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: _rememberTerminal,
                                    activeColor: const Color(0xFF006C49),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(
                                        () => _rememberTerminal = val ?? true,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  copy.rememberTerminal,
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w400,
                                    0,
                                    color: const Color(0xFF5E5D69),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              copy.needHelp,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0,
                                color: const Color(0xFF006C49),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 2FA Security Challenge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006C49)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF006C49)
                                  .withValues(alpha: 0.20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF006C49),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      copy.challengeTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF006C49),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                copy.challengeBody,
                                style: Fx.text(
                                  11,
                                  16,
                                  FontWeight.w400,
                                  0,
                                  color: const Color(0xFF5E5D69),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          copy.codeLabel,
                          style: Fx.text(
                            12,
                            16,
                            FontWeight.w600,
                            0,
                            color: const Color(0xFF1A1B1F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE9E7ED)),
                          ),
                          child: TextFormField(
                            key: const Key('sign-in-code'),
                            controller: widget.codeController,
                            validator: widget.onValidateRequired,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: Fx.text(
                              18,
                              24,
                              FontWeight.w700,
                              4.0,
                              color: const Color(0xFF1A1B1F),
                            ),
                            decoration: InputDecoration(
                              hintText: copy.codeHint,
                              hintStyle: Fx.text(
                                18,
                                24,
                                FontWeight.w400,
                                4.0,
                                color: const Color(0xFF5E5D69),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        key: const Key('sign-in-submit'),
                        onPressed: widget.submitting ? null : widget.onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006C49),
                          foregroundColor: Fx.white,
                          disabledBackgroundColor: const Color(0xFF006C49)
                              .withValues(alpha: 0.50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0x33006C49),
                        ),
                        child: widget.submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Fx.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.challenge
                                        ? copy.verifyButton
                                        : copy.signInButton,
                                    style: Fx.text(
                                      14,
                                      18,
                                      FontWeight.w700,
                                      0,
                                      color: Fx.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Fx.white,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Footer security disclaimer
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: Color(0xFF5E5D69),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              copy.footer,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w400,
                                0,
                                color: const Color(0xFF5E5D69),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.useOptions,
    required this.languages,
    required this.selectedCode,
    required this.legacyLabel,
    required this.onOptionSelected,
    required this.onLegacyToggle,
  });

  final bool useOptions;
  final List<LanguageOption> languages;
  final String selectedCode;
  final String legacyLabel;
  final ValueChanged<String>? onOptionSelected;
  final VoidCallback? onLegacyToggle;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF006C49);
    if (useOptions) {
      var selected = languages.first;
      for (final option in languages) {
        if (option.code == selectedCode) selected = option;
      }
      return PopupMenuButton<String>(
        key: const Key('sign-in-language-menu'),
        borderRadius: BorderRadius.circular(8),
        onSelected: onOptionSelected,
        itemBuilder: (menuContext) {
          return [
            for (final option in languages)
              PopupMenuItem<String>(
                key: Key('sign-in-language-${option.code}'),
                value: option.code,
                child: Row(
                  children: [
                    Expanded(child: Text(option.displayName)),
                    if (option.code == selected.code)
                      const Icon(Icons.check_rounded, size: 16, color: accent),
                  ],
                ),
              ),
          ];
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                selected.displayName,
                style: Fx.text(12, 16, FontWeight.w700, 0, color: accent),
              ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onLegacyToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              legacyLabel,
              style: Fx.text(12, 16, FontWeight.w700, 0, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
