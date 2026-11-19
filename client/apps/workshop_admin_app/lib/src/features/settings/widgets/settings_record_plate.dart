import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'settings_geometry.dart';
import 'settings_primitives.dart';

/// The signature region: the active workshop printed as a record.
///
/// Ink surface, a hairline form grid and two concentric seal rings — the only
/// dark surface on the screen and the page's single focal point. Real data
/// only: workshop name, account holder, email (omitted when absent) and role.
class SettingsRecordPlate extends StatelessWidget {
  const SettingsRecordPlate({
    required this.workshopName,
    required this.personName,
    required this.email,
    required this.roleLabel,
    required this.isCompact,
    super.key,
  });

  final String workshopName;
  final String personName;
  final String email;
  final String roleLabel;

  /// Stacked (single column) layout uses a tighter plate.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final initials = settingsInitials(personName);
    final padding = isCompact ? 22.0 : 24.0;

    return Semantics(
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SettingsGeometry.surfaceRadius),
        child: ColoredBox(
          color: ws.ink,
          child: CustomPaint(
            painter: _RecordGridPainter(
              line: ws.surface.withValues(alpha: 0.055),
              ring: ws.surface.withValues(alpha: 0.09),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SettingsSeal(
                        icon: Icons.storefront_outlined,
                        size: isCompact ? 46 : 52,
                        onInk: true,
                      ),
                      const Spacer(),
                      Text(
                        l10n.settingsWorkshop.toUpperCase(),
                        style: ws.eyebrow.copyWith(
                          color: ws.surface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 18 : 20),
                  Semantics(
                    header: true,
                    child: Text(
                      workshopName,
                      style: ws.pageTitle.copyWith(
                        fontSize: isCompact ? 30 : 34,
                        height: isCompact ? 36 / 30 : 40 / 34,
                        color: ws.surface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: ws.surface.withValues(alpha: 0.16),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.settingsAccount.toUpperCase(),
                    style: ws.eyebrow.copyWith(
                      color: ws.surface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (initials.isNotEmpty) ...[
                        SettingsAvatar(
                          initials: initials,
                          size: 40,
                          onInk: true,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              personName,
                              style: ws.bodyStrong.copyWith(
                                fontSize: 15,
                                color: ws.surface,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              SelectableText(
                                email,
                                style: ws.meta.copyWith(
                                  color: ws.surface.withValues(alpha: 0.66),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingsPill(
                    label: roleLabel,
                    tone: SettingsPillTone.onInk,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hairline form grid that fades out of the ink plate, plus two seal rings in
/// the bottom corner. Decorative: excluded from semantics by the parent.
class _RecordGridPainter extends CustomPainter {
  const _RecordGridPainter({required this.line, required this.ring});

  final Color line;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 1;
    final start = size.width * 0.22;
    for (var x = start; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
    }
    for (var y = 40.0; y < size.height; y += 40) {
      canvas.drawLine(Offset(start, y), Offset(size.width, y), stroke);
    }
    final circle = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centre = Offset(size.width - 8, size.height + 16);
    canvas.drawCircle(centre, 92, circle);
    canvas.drawCircle(centre, 124, circle);
  }

  @override
  bool shouldRepaint(covariant _RecordGridPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.ring != ring;
}
