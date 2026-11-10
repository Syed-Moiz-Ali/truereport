import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';

/// Screen 06. Equipment Checklist.
class EquipmentView extends StatelessWidget {
  const EquipmentView({
    required this.equipment,
    required this.onProceed,
    this.onBack,
    this.onProfile,
    this.title,
    super.key,
  });

  final List<EquipmentItem> equipment;
  final VoidCallback onProceed;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final String? title;

  static const _icons = <String>['1_7667', '1_7680', '1_7693', '1_7706'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = equipment.length;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isFlexible = textScale > 1.05 ||
        Directionality.of(context) == TextDirection.rtl ||
        MediaQuery.sizeOf(context).width < 380;

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title ?? l10n.equipment,
        showBack: true,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45),
        horizontalPadding: _M.headerPad,
        titleInset: 0,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: InkResponse(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            radius: 24,
            child: const SizedBox(
              width: _M.backButton,
              height: _M.backButton,
              child: Center(
                child: FxIcon(
                  id: '1_7736',
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
            iconId: '1_7741',
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
              constraints: const BoxConstraints(minHeight: _M.statusBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: _M.statusTop,
                  bottom: _M.statusBottom,
                ),
                child: Row(
                  children: [
                    Container(
                      width: _M.stepCircle,
                      height: _M.stepCircle,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3E1EF),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '01',
                        textDirection: TextDirection.ltr,
                        style: Fx.text(11, 14, FontWeight.w600, -0.275, color: const Color(0xFF1A1B1F)),
                      ),
                    ),
                    const SizedBox(width: _M.g8),
                    Expanded(
                      child: Text(
                        l10n.technicianPreInspectionSetup,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.text(
                          12,
                          16,
                          FontWeight.w600,
                          0.24,
                          color: const Color(0xFF5E5D69),
                        ),
                      ),
                    ),
                    const SizedBox(width: _M.g8),
                    FxPill(
                      label: l10n.technicianItemsCount(count),
                      background: const Color(0xFFF4F3F8),
                      foreground: Fx.emerald,
                      height: _M.verifiedHeight,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.275,
                        color: Fx.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.headerBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.headerBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.technicianRequiredEquipment,
                      style: Fx.display26.copyWith(color: const Color(0xFF1B1B25)),
                    ),
                    const SizedBox(height: _M.g4),
                    Text(
                      l10n.technicianEquipmentIntro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.body14.copyWith(color: const Color(0xFF5E5D69)),
                    ),
                  ],
                ),
              ),
            ),
            if (count == 0) ...[
              FxCard(
                radius: _M.cardRadius,
                padding: EdgeInsets.all(context.spacing.gutter),
                child: Text(
                  l10n.noResults,
                  style: Fx.body14.copyWith(color: Fx.muted),
                ),
              ),
            ] else ...[
              ...List.generate(count, (index) {
                final item = equipment[index];
                final languageCode = Localizations.localeOf(context).languageCode;
                final label = item.labelFor(languageCode);
                final itemTitle = label.isNotEmpty
                    ? label
                    : item.code.isNotEmpty
                    ? item.code
                    : item.equipmentId;
                final itemBody = [
                  item.code,
                  item.status,
                ].where((value) => value.isNotEmpty).join(' · ');
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: index < count - 1 ? _M.cardGap : 0,
                  ),
                  child: _EquipmentCard(
                    title: itemTitle,
                    body: itemBody,
                    iconId: _icons[index % _icons.length],
                    verified: item.status == 'VERIFIED' || (item.status == 'ACTIVE' && index == 0),
                    cardHeight: index == 1 ? 98 : 88,
                  ),
                );
              }),
            ],
            const SizedBox(height: _M.g40),
            Container(
              height: isFlexible ? null : _M.standardsHeight,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F3F8),
                borderRadius: BorderRadius.circular(_M.cardRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: _M.standardsIcon,
                    height: _M.standardsIcon,
                    decoration: const BoxDecoration(
                      color: Fx.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: FxIcon(
                        id: '1_7719',
                        width: 13.33,
                        height: 16.67,
                        color: Fx.emerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: _M.g16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.technicianEquipmentStandards,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.text(
                            12,
                            16,
                            FontWeight.w600,
                            0.24,
                            color: const Color(0xFF1A1B1F),
                          ),
                        ),
                        Text(
                          l10n.technicianEquipmentStandardsBody,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.text(
                            13,
                            18,
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
            const SizedBox(height: _M.g40),
            FxButton(
              label: l10n.technicianProceed,
              onPressed: onProceed,
              icon: const FxIcon(
                id: '1_7730',
                width: 13.33,
                height: 13.33,
                color: Fx.white,
              ),
              trailingIcon: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.title,
    required this.body,
    required this.iconId,
    required this.verified,
    required this.cardHeight,
  });

  final String title;
  final String body;
  final String iconId;
  final bool verified;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isFlexible = textScale > 1.05 ||
        Directionality.of(context) == TextDirection.rtl ||
        MediaQuery.sizeOf(context).width < 380;

    return FxCard(
      radius: _M.cardRadius,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: isFlexible ? null : (cardHeight - 40),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F3F8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FxIcon(
                  id: iconId,
                  width: 22,
                  height: 22,
                  color: verified ? Fx.emerald : const Color(0xFF5E5D69),
                ),
              ),
            ),
            const SizedBox(width: _M.g16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: isFlexible ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(16, 22, FontWeight.w700, -0.16, color: const Color(0xFF1B1B25)),
                  ),
                  Text(
                    body,
                    maxLines: isFlexible ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(13, 18, FontWeight.w400, 0, color: const Color(0xFF5E5D69)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _M.g12),
            Container(
              width: _M.statusCircle,
              height: _M.statusCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: verified ? Fx.emerald : const Color(0xFFE9E7ED),
                shape: BoxShape.circle,
                boxShadow: verified
                    ? const [
                        BoxShadow(
                          color: Color(0x4010B981),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: verified
                  ? const FxIcon(
                      id: '1_7675',
                      width: 12.23,
                      height: 9.02,
                      color: Fx.white,
                    )
                  : const SizedBox.shrink(),
            ),
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

  static const double g4 = 4;
  static const double g8 = 8;
  static const double g12 = 12;
  static const double g16 = 16;
  static const double g40 = 40;
  static const double backButton = 44;

  static const double statusBlock = 60;
  static const double statusTop = 12;
  static const double statusBottom = 24;
  static const double stepCircle = 24;
  static const double verifiedHeight = 22;

  static const double headerBlock = 108;
  static const double headerBottom = 32;

  static const double cardGap = 16;
  static const double cardRadius = 32;
  static const double statusCircle = 32;

  static const double standardsHeight = 92;
  static const double standardsIcon = 40;
}
