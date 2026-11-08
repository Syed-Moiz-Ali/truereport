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
    this.onBack,
    this.onProfile,
    this.title,
    this.isFigma = false,
    super.key,
  });

  final String? selectedType;
  final bool? selectedStatus;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onStatusChanged;
  final Future<void> Function() onSave;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final String? title;
  final bool isFigma;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave = (selectedType != null && selectedStatus != null && !saving) || isFigma;
    final pageTitle = title ?? (isFigma ? 'Vehicle Walkaround Inspection' : l10n.consent);

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: pageTitle,
        showBack: true,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45),
        horizontalPadding: _M.headerPad,
        titleInset: isFigma ? 4 : 0,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: InkResponse(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            radius: 24,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: FxIcon(
                  id: '1_7637',
                  size: 20,
                  color: Fx.ink,
                ),
              ),
            ),
          ),
        ),
        actions: [
          const SizedBox(width: _M.g4),
          FxProfileButton(
            initials: '',
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
                            l10n.technicianConsentStep,
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
                      l10n.consent,
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
              title: l10n.consentPublicLink,
              body: l10n.technicianConsentPublicLinkBody,
              selected: isFigma ? true : (selectedType == 'PUBLIC_LINK'),
              granted: isFigma ? true : (selectedType == 'PUBLIC_LINK' && selectedStatus == true),
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
              title: l10n.consentProcessing,
              body: l10n.technicianConsentProcessingBody,
              selected: isFigma ? true : (selectedType == 'PROCESSING'),
              granted: isFigma ? true : (selectedType == 'PROCESSING' && selectedStatus == true),
              onTap: () => onTypeChanged('PROCESSING'),
              onToggle: (value) {
                onTypeChanged('PROCESSING');
                onStatusChanged(value);
              },
            ),
            const SizedBox(height: _M.cardGap),
            _ConsentCard(
              iconId: '1_7575',
              title: l10n.technicianDataStorage,
              body: l10n.technicianUnavailable,
              selected: false,
              granted: false,
              enabled: false,
              onTap: null,
              onToggle: null,
            ),
            const SizedBox(height: 32),
            _DecisionSection(
              selectedStatus: selectedStatus,
              onStatusChanged: onStatusChanged,
              isFigma: isFigma,
            ),
            const SizedBox(height: 20),
            _SignerCard(
              selectedStatus: selectedStatus,
              isFigma: isFigma,
            ),
            const SizedBox(height: 32),
            FxButton(
              key: const Key('consent-save'),
              label: l10n.technicianConsentSave,
              onPressed: canSave ? onSave : null,
              icon: const FxIcon(
                id: '1_7629',
                size: 16.67,
                color: Fx.white,
              ),
              trailingIcon: false,
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isFlexible = textScale > 1.05 || Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      selected: selected,
      button: onTap != null,
      label: '$title. $body',
      child: FxCard(
        radius: _M.cardRadius,
        padding: const EdgeInsets.all(_M.cardPad),
        onTap: onTap,
        child: SizedBox(
          height: isFlexible ? null : _M.cardInner,
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
                      maxLines: isFlexible ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.title16.copyWith(color: Fx.ink),
                    ),
                    Text(
                      body,
                      maxLines: isFlexible ? 3 : 1,
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
          child: Center(
            child: AnimatedContainer(
              duration: context.motionDuration(context.motion.fast),
              width: _M.switchWidth,
              height: _M.switchHeight,
              padding: const EdgeInsets.all(_M.switchPad),
              decoration: BoxDecoration(
                color: value ? Fx.emerald : const Color(0xFFE9E7ED),
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
    );
  }
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({
    required this.selectedStatus,
    required this.onStatusChanged,
    this.isFigma = false,
  });

  final bool? selectedStatus;
  final ValueChanged<bool> onStatusChanged;
  final bool isFigma;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale > 1.1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLargeText)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4, end: 4),
            child: Wrap(
              spacing: _M.g6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.technicianConsentDecision,
                  style: Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.ink),
                ),
                FxPill(
                  label: l10n.consentRequired,
                  background: Fx.tintEmerald,
                  foreground: Fx.emerald,
                  height: _M.requiredHeight,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.emerald),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: _M.decisionHeader,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 12, start: 4, end: 4),
              child: Row(
                children: [
                  Text(
                    l10n.technicianConsentDecision,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.ink),
                  ),
                  const SizedBox(width: _M.g6),
                  FxPill(
                    label: l10n.consentRequired,
                    background: Fx.tintEmerald,
                    foreground: Fx.emerald,
                    height: _M.requiredHeight,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.emerald),
                  ),
                  const SizedBox(width: _M.g8),
                  Expanded(
                    child: Text(
                      l10n.technicianConsentHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Fx.body13.copyWith(color: Fx.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          height: _M.decisionBox,
          decoration: BoxDecoration(
            color: const Color(0x99F4F3F8),
            borderRadius: BorderRadius.circular(_M.cardRadius),
            boxShadow: Fx.cardShadow,
          ),
          child: isFigma
              ? Stack(
                  children: [
                    Positioned(
                      left: 32,
                      right: 32,
                      top: 135,
                      height: 1,
                      child: Container(color: const Color(0xFFE3E1EF)),
                    ),
                    Positioned(
                      left: 32,
                      top: 146,
                      child: Text(
                        'Sign Above Line',
                        style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
                      ),
                    ),
                    const Positioned(
                      left: 56.5,
                      top: 66.5,
                      width: 236,
                      height: 49,
                      child: Opacity(
                        opacity: 0.8,
                        child: FxIcon(
                          id: '1_7607',
                          width: 236,
                          height: 49,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 120.56,
                      top: 100.17,
                      width: 79.72,
                      height: 5.33,
                      child: Opacity(
                        opacity: 0.8,
                        child: FxIcon(
                          id: '1_7608',
                          width: 79.72,
                          height: 5.33,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        height: 22,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Fx.whiteE5,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: Fx.pillShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FxIcon(
                              id: '1_7611',
                              size: 10,
                              color: Fx.emerald,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recorded',
                              style: Fx.text(11, 14, FontWeight.w600, -0.275, color: Fx.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
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
                        l10n.technicianNoSignature,
                        style: Fx.caption.copyWith(color: Fx.ink),
                      ),
                    ],
                  ),
                ),
        ),
        if (isLargeText)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8, start: 4, end: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  isFigma
                      ? 'Timestamp: Today, 14:38 EST'
                      : '${l10n.technicianTimestamp}: ${l10n.technicianConsentNotRecorded}',
                  style: Fx.body13.copyWith(color: Fx.muted),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FxIcon(
                        id: '1_7599',
                        width: 10.67,
                        height: 12.3,
                        color: Fx.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.technicianClear,
                        style: Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: _M.timestampRow,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 10, start: 4, end: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isFigma
                          ? 'Timestamp: Today, 14:38 EST'
                          : '${l10n.technicianTimestamp}: ${l10n.technicianConsentNotRecorded}',
                      style: Fx.body13.copyWith(color: Fx.muted),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FxIcon(
                          id: '1_7599',
                          width: 10.67,
                          height: 12.3,
                          color: Fx.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.technicianClear,
                          style: Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                        ),
                      ],
                    ),
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
  const _SignerCard({required this.selectedStatus, this.isFigma = false});

  final bool? selectedStatus;
  final bool isFigma;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale > 1.1;
    final title = l10n.technicianAuthorizedRepresentative;
    final subtitle = selectedStatus == null
        ? l10n.technicianConsentNotRecorded
        : selectedStatus == true
        ? l10n.consentGranted
        : l10n.consentRefused;
    return FxCard(
      radius: _M.cardRadius,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: isLargeText ? null : 40,
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
                isFigma ? 'AL' : '—',
                textDirection: TextDirection.ltr,
                style: Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.darkInk),
              ),
            ),
            const SizedBox(width: _M.g12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFigma ? 'Alex Lindqvist' : title,
                    maxLines: isLargeText ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
                  ),
                  Text(
                    isFigma ? 'Authorized Representative • VIN 4782' : subtitle,
                    maxLines: isLargeText ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const FxIcon(id: '1_7625', size: 16.67, color: Color(0xFFBBCABF)),
          ],
        ),
      ),
    );
  }
}

abstract final class _M {
  static const double gutter = 20;
  static const double headerPad = 16;
  static const double bodyBottom = 40;
  static const double pill = 999;
  static const double g4 = 4;
  static const double g6 = 6;
  static const double g8 = 8;
  static const double g12 = 12;
  static const double g14 = 14;
  static const double g16 = 16;
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
}
