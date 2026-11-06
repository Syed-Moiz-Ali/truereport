import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';

/// Screen 6. The server returns equipment IDs only, so the layout is shown with
/// those IDs and an explicit "name unavailable" line; no name, spec,
/// calibration or verification state is invented.
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
    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title ?? l10n.equipment,
        showBack: onBack != null,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45),
        horizontalPadding: _M.headerPad,
        actions: [
          FxProfileButton(
            initials: 'TR',
            iconId: '1_7741',
            onPressed: onProfile,
            semanticLabel: l10n.technicianProfileTitle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          context.spacing.gutter,
          0,
          context.spacing.gutter,
          context.spacing.xxxl,
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
                        color: Fx.baseline,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '01',
                        textDirection: TextDirection.ltr,
                        style: Fx.caption.copyWith(color: Fx.inkStrong),
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
                          color: Fx.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: _M.g8),
                    Flexible(
                      child: FxPill(
                        label: l10n.technicianItemsCount(count),
                        background: Fx.container,
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
                      style: Fx.display26.copyWith(color: Fx.inkStrong),
                    ),
                    const SizedBox(height: _M.g4),
                    Text(
                      l10n.technicianEquipmentIntro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.body14.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ),
            if (count == 0)
              FxCard(
                radius: _M.cardRadius,
                padding: EdgeInsets.all(context.spacing.gutter),
                child: Text(
                  l10n.noResults,
                  style: Fx.body14.copyWith(color: Fx.muted),
                ),
              )
            else
              ...List.generate(count, (index) {
                final item = equipment[index];
                final languageCode = Localizations.localeOf(context)
                    .languageCode;
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
                  padding: const EdgeInsetsDirectional.only(bottom: _M.cardGap),
                  child: _EquipmentCard(
                    title: itemTitle,
                    body: itemBody,
                    iconId: _icons[index % _icons.length],
                    verified: false,
                    innerHeight: index == 1 ? _M.innerTall : _M.innerShort,
                  ),
                );
              }),
            const SizedBox(height: _M.g40),
            SizedBox(
              height: _M.standardsBlock,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: context.spacing.xxl,
                ),
                child: Container(
                  height: _M.standardsHeight,
                  padding: EdgeInsets.all(context.spacing.gutter),
                  decoration: BoxDecoration(
                    color: Fx.container,
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
                          boxShadow: Fx.pillShadow,
                        ),
                        child: const Center(
                          child: FxIcon(
                            id: '1_7719',
                            size: 16.67,
                            color: Fx.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: _M.g16),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.technicianEquipmentStandards,
                                style: Fx.text(
                                  12,
                                  16,
                                  FontWeight.w600,
                                  0.24,
                                  color: Fx.inkStrong,
                                ),
                              ),
                              Text(
                                l10n.technicianEquipmentStandardsBody,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Fx.body13.copyWith(color: Fx.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: _M.g6),
            FxButton(
              label: l10n.technicianProceed,
              onPressed: onProceed,
              icon: const FxIcon(id: '1_7730', size: 13.33, color: Fx.white),
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
    required this.innerHeight,
  });

  final String title;
  final String body;
  final String iconId;
  final bool verified;
  final double innerHeight;

  @override
  Widget build(BuildContext context) {
    return FxCard(
      radius: _M.cardRadius,
      padding: EdgeInsets.all(context.spacing.gutter),
      child: SizedBox(
        height: innerHeight,
        child: Row(
          children: [
            FxIconTile(
              iconId: iconId,
              size: _M.iconTile,
              iconSize: _M.iconGlyph,
              color: verified ? Fx.emerald : Fx.muted,
            ),
            const SizedBox(width: _M.g16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.title16.copyWith(color: Fx.inkStrong),
                    ),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.body13.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: _M.g12),
            Container(
              width: _M.statusCircle,
              height: _M.statusCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: verified ? Fx.emerald : Fx.surfaceHighest,
                shape: BoxShape.circle,
                boxShadow: verified ? Fx.softShadow : null,
              ),
              child: verified
                  ? const FxIcon(id: '1_7675', size: 12.23, color: Fx.white)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _M {
  static const double headerPad = 16;

  static const double g4 = 4;
  static const double g6 = 6;
  static const double g8 = 8;
  static const double g12 = 12;
  static const double g16 = 16;

  static const double g40 = 40;
  static const double statusBlock = 60;
  static const double statusTop = 12;
  static const double statusBottom = 24;
  static const double stepCircle = 24;
  static const double verifiedHeight = 22;
  static const double headerBlock = 108;
  static const double headerBottom = 32;
  static const double cardGap = 16;
  static const double cardRadius = 32;
  static const double iconTile = 48;
  static const double iconGlyph = 22;
  static const double statusCircle = 32;
  static const double innerShort = 48;
  static const double innerTall = 58;
  static const double standardsBlock = 110;
  static const double standardsHeight = 92;
  static const double standardsIcon = 40;
}
