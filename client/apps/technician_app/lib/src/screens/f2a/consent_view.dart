import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

class ConsentView extends StatelessWidget {
  const ConsentView({
    required this.selectedType,
    required this.selectedStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSave,
    this.saving = false,
    this.figmaText = false,
    this.figmaPreview = false,
    this.onBack,
    this.onProfile,
    this.title,
    super.key,
  });

  final String? selectedType;
  final bool? selectedStatus;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onStatusChanged;
  final Future<void> Function() onSave;
  final bool saving;
  final bool figmaText;
  final bool figmaPreview;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave = selectedType != null && selectedStatus != null && !saving;
    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title ?? l10n.consent,
        showBack: onBack != null,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45),
        horizontalPadding: _M.headerPad,
        actions: [
          FxProfileButton(
            initials: 'TR',
            iconId: '1_7642',
            onPressed: onProfile,
            semanticLabel: l10n.technicianProfileTitle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          _M.gutter,
          0,
          _M.gutter,
          _M.bodyBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.headerBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: _M.headerTop,
                  bottom: _M.headerBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: _M.stepIcon,
                          height: _M.stepIcon,
                          decoration: const BoxDecoration(
                            color: Fx.tintEmerald,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FxIcon(
                              id: '1_7539',
                              size: 12.5,
                              color: Fx.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: _M.g8),
                        Expanded(
                          child: Text(
                            figmaText
                                ? 'STEP 4 OF 4 • FINAL SIGN-OFF'
                                : l10n.technicianConsentStep,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Fx.text(
                              12,
                              16,
                              FontWeight.w600,
                              0.3,
                              color: Fx.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _M.g8),
                    Text(
                      figmaText ? 'Authorizations' : l10n.consent,
                      style: Fx.display26.copyWith(color: Fx.ink),
                    ),
                    const SizedBox(height: _M.g4),
                    Text(
                      l10n.technicianConsentIntro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.body14.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ),
            _ConsentCard(
              key: const Key('consent-type-public-link'),
              iconId: '1_7551',
              title: figmaText ? 'Allow PDF sharing' : l10n.consentPublicLink,
              body: figmaText
                  ? 'Send detailed diagnostic report via email'
                  : l10n.technicianConsentPublicLinkBody,
              selected: selectedType == 'PUBLIC_LINK',
              granted:
                  (selectedType == 'PUBLIC_LINK' && selectedStatus == true) ||
                  figmaPreview,
              onTap: () => onTypeChanged('PUBLIC_LINK'),
              onToggle: (value) {
                onTypeChanged('PUBLIC_LINK');
                onStatusChanged(value);
              },
            ),
            const SizedBox(height: _M.cardGap),
            _ConsentCard(
              key: const Key('consent-type-processing'),
              iconId: '1_7563',
              title: figmaText ? 'Customer road test consent' : l10n.consentProcessing,
              body: figmaText
                  ? 'Authorize certified technician dynamic evaluation'
                  : l10n.technicianConsentProcessingBody,
              selected: selectedType == 'PROCESSING',
              granted:
                  (selectedType == 'PROCESSING' && selectedStatus == true) ||
                  figmaPreview,
              onTap: () => onTypeChanged('PROCESSING'),
              onToggle: (value) {
                onTypeChanged('PROCESSING');
                onStatusChanged(value);
              },
            ),
            const SizedBox(height: _M.cardGap),
            _ConsentCard(
              iconId: '1_7575',
              title: figmaText ? 'Data storage authorization' : l10n.technicianDataStorage,
              body: figmaText
                  ? 'Encrypt telemetry logs and secure fleet cloud backups'
                  : l10n.technicianUnavailable,
              selected: false,
              granted: false,
              enabled: false,
              onTap: null,
              onToggle: null,
            ),
            const SizedBox(height: _M.cardGap),
            _DecisionSection(
              selectedStatus: selectedStatus,
              figmaText: figmaText,
              onStatusChanged: onStatusChanged,
            ),
            const SizedBox(height: _M.g24),
            _SignerCard(
              figmaText: figmaText,
              selectedStatus: selectedStatus,
            ),
            const SizedBox(height: _M.g16),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.actionBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: _M.g16,
                  bottom: _M.g8,
                ),
                child: FxButton(
                  key: const Key('consent-save'),
                  label: figmaText ? 'Save Consent' : l10n.technicianConsentSave,
                  onPressed: canSave ? onSave : null,
                  icon: const FxIcon(
                    id: '1_7629',
                    size: 16.67,
                    color: Fx.white,
                  ),
                  trailingIcon: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.iconId,
    required this.title,
    required this.body,
    required this.selected,
    required this.granted,
    required this.onTap,
    required this.onToggle,
    this.enabled = true,
    super.key,
  });

  final String iconId;
  final String title;
  final String body;
  final bool selected;
  final bool granted;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: onTap != null,
      label: '$title. $body',
      child: FxCard(
        radius: _M.cardRadius,
        padding: const EdgeInsets.all(_M.cardPad),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _M.cardInner),
          child: Row(
            children: [
              FxIconTile(
                iconId: iconId,
                size: _M.iconTile,
                iconSize: _M.iconTileGlyph,
                color: Fx.ink,
                circle: true,
              ),
              const SizedBox(width: _M.g14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.title16.copyWith(color: Fx.ink),
                    ),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.body13.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _M.g8),
              _FxSwitch(
                value: granted,
                enabled: enabled,
                onChanged: onToggle,
                semanticLabel: title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FxSwitch extends StatelessWidget {
  const _FxSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _M.switchHit,
          height: _M.cardInner,
          child: OverflowBox(
            maxHeight: _M.switchHit,
            child: Center(
              child: AnimatedContainer(
              duration: context.motionDuration(context.motion.fast),
              width: _M.switchWidth,
              height: _M.switchHeight,
              padding: const EdgeInsets.all(_M.switchPad),
              decoration: BoxDecoration(
                color: value ? Fx.emerald : Fx.surfaceHighest,
                borderRadius: BorderRadius.circular(_M.pill),
              ),
              child: AnimatedAlign(
                duration: context.motionDuration(context.motion.fast),
                alignment: value
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: _M.thumb,
                  height: _M.thumb,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    shape: BoxShape.circle,
                    boxShadow: Fx.pillShadow,
                  ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({
    required this.selectedStatus,
    required this.figmaText,
    required this.onStatusChanged,
  });

  final bool? selectedStatus;
  final bool figmaText;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _M.decisionHeader),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  figmaText
                      ? 'Digital Signature'
                      : l10n.technicianConsentDecision,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.label14.copyWith(color: Fx.ink),
                ),
              ),
              const SizedBox(width: _M.g8),
              FxPill(
                label: 'Required',
                background: Fx.tintEmerald,
                foreground: Fx.emerald,
                height: _M.requiredHeight,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                style: Fx.caption.copyWith(color: Fx.emerald),
              ),
              const SizedBox(width: _M.g8),
              Expanded(
                flex: 5,
                child: Text(
                  figmaText
                      ? 'Sign with finger or stylus'
                      : l10n.technicianConsentHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Fx.body13.copyWith(color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _M.g12),
        Container(
          constraints: const BoxConstraints(minHeight: _M.decisionBox),
          decoration: BoxDecoration(
            color: Fx.container99,
            borderRadius: BorderRadius.circular(_M.cardRadius),
            boxShadow: Fx.cardShadow,
          ),
          padding: EdgeInsets.all(context.spacing.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSelectableText(
                      key: const Key('consent-granted'),
                      label: l10n.consentGranted,
                      selected: selectedStatus == true,
                      onTap: () => onStatusChanged(true),
                    ),
                  ),
                  const SizedBox(width: _M.g12),
                  Expanded(
                    child: AppSelectableText(
                      key: const Key('consent-refused'),
                      label: l10n.consentRefused,
                      selected: selectedStatus == false,
                      onTap: () => onStatusChanged(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _M.g16),
              Text(
                figmaText
                    ? 'Sign Above Line'
                    : l10n.technicianNoSignature,
                style: Fx.caption.copyWith(color: Fx.ink),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _M.timestampRow),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: _M.g10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.technicianTimestamp}: ${l10n.technicianConsentNotRecorded}',
                    style: Fx.body13.copyWith(color: Fx.muted),
                  ),
                ),
                Text(
                  figmaText ? 'Clear' : l10n.technicianClear,
                  style: Fx.label12.copyWith(color: Fx.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignerCard extends StatelessWidget {
  const _SignerCard({required this.figmaText, required this.selectedStatus});

  final bool figmaText;
  final bool? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = figmaText
        ? 'Alex Lindqvist'
        : l10n.technicianAuthorizedRepresentative;
    final subtitle = figmaText
        ? 'Authorized Representative • VIN 4782'
        : selectedStatus == null
        ? l10n.technicianConsentNotRecorded
        : selectedStatus == true
        ? l10n.consentGranted
        : l10n.consentRefused;
    return FxCard(
      radius: _M.cardRadius,
      padding: EdgeInsets.all(context.spacing.lg),
      child: Row(
        children: [
          Container(
            width: _M.signerAvatar,
            height: _M.signerAvatar,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Fx.tintEmerald,
              shape: BoxShape.circle,
            ),
            child: Text(
              figmaText ? 'AL' : '—',
              textDirection: TextDirection.ltr,
              style: Fx.text(
                16,
                22,
                FontWeight.w700,
                -0.16,
                color: Fx.darkInk,
              ),
            ),
          ),
          const SizedBox(width: _M.g12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.title16.copyWith(color: Fx.ink),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.body13.copyWith(color: Fx.muted),
                ),
              ],
            ),
          ),
          const FxIcon(
            id: '1_7625',
            size: 16.67,
            color: Fx.sage,
          ),
        ],
      ),
    );
  }
}

abstract final class _M {
  static const double gutter = 20;
  static const double headerPad = 16;
  static const double bodyBottom = 32;
  static const double pill = 999;
  static const double g4 = 4;
  static const double g8 = 8;
  static const double g10 = 10;
  static const double g12 = 12;
  static const double g14 = 14;
  static const double g16 = 16;

  static const double g24 = 24;
  static const double headerBlock = 144;
  static const double headerTop = 12;
  static const double headerBottom = 24;
  static const double stepIcon = 24;
  static const double cardGap = 16;
  static const double cardRadius = 32;
  static const double cardPad = 20;
  static const double cardInner = 40;
  static const double iconTile = 40;
  static const double iconTileGlyph = 16.67;
  static const double switchHit = 52;
  static const double switchWidth = 52;
  static const double switchHeight = 32;
  static const double switchPad = 4;
  static const double thumb = 24;
  static const double decisionHeader = 30;
  static const double requiredHeight = 18;
  static const double decisionBox = 176;
  static const double timestampRow = 34;
  static const double signerAvatar = 40;
  static const double actionBlock = 80;
}
