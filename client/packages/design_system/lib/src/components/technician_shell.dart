import 'dart:math' as math;

import 'package:design_system/src/components/cards.dart';
import 'package:design_system/src/components/chips.dart';
import 'package:design_system/src/components/navigation.dart';
import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

/// Original TrueReport wordmark used by the technician app. It replaces the
/// Figma sample brand and uses a drawn monogram instead of the missing Figma
/// logo asset.
class TechnicianBrandMark extends StatelessWidget {
  const TechnicianBrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? context.spacing.xxl : context.spacing.xxxl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.brand.ink,
            borderRadius: BorderRadius.circular(context.radii.lg),
          ),
          child: Text(
            'TR',
            textDirection: TextDirection.ltr,
            style: context.texts.labelLarge?.copyWith(
              color: context.colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (!compact) ...[
          SizedBox(width: context.spacing.sm),
          Text(
            'TrueReport',
            style: context.texts.headlineLarge?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

String technicianInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  final first = _firstLetter(parts.first);
  final last = parts.length == 1 ? '' : _firstLetter(parts.last);
  return (first + last).toUpperCase();
}

String _firstLetter(String value) {
  final runes = value.runes;
  if (runes.isEmpty) {
    return '';
  }
  return String.fromCharCode(runes.first);
}

class TechnicianAvatar extends StatelessWidget {
  const TechnicianAvatar({
    required this.name,
    this.size = 40,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final initials = technicianInitials(name);
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.brand.container,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials.isEmpty ? 'â€¢' : initials,
            textDirection: TextDirection.ltr,
            style: context.texts.labelLarge?.copyWith(
              color: context.brand.onContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class TechnicianAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TechnicianAppBar({
    required this.title,
    this.showBack = false,
    this.technicianName,
    this.onProfile,
    this.onSearch,
    this.leading,
    this.bottom,
    this.titleLarge = false,
    super.key,
  });

  final String title;
  final bool showBack;
  final String? technicianName;
  final VoidCallback? onProfile;
  final VoidCallback? onSearch;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool titleLarge;

  @override
  Size get preferredSize => Size.fromHeight(
    _barHeight + (bottom?.preferredSize.height ?? 0),
  );

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _barHeight,
      titleSpacing: context.spacing.gutter,
      centerTitle: false,
      backgroundColor: context.colors.surface,
      surfaceTintColor: context.colors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: showBack || leading != null ? 64 : null,
      leading: leading ?? (showBack ? const BackButton() : null),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            (titleLarge
                    ? context.texts.headlineLarge
                    : context.texts.headlineMedium)
                ?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
      ),
      actions: [
        if (onSearch != null)
          IconButton(
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onPressed: onSearch,
            icon: const Icon(Icons.search),
          ),
        if (technicianName != null)
          Padding(
            padding: EdgeInsetsDirectional.only(end: context.spacing.md),
            child: IconButton(
              tooltip: technicianName,
              onPressed: onProfile,
              icon: TechnicianAvatar(
                name: technicianName!,
                size: context.spacing.xxxl,
                semanticLabel: technicianName,
              ),
            ),
          ),
      ],
      bottom: bottom,
    );
  }
}

/// Product dock: Jobs / Sync / Profile. The Figma four-item dock is shown only
/// in the developer gallery.
class TechnicianDock extends StatelessWidget {
  const TechnicianDock({
    required this.jobsLabel,
    required this.syncLabel,
    required this.profileLabel,
    required this.selectedIndex,
    this.onSelected,
    super.key,
  });

  final String jobsLabel;
  final String syncLabel;
  final String profileLabel;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavDock(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      items: [
        AppBottomNavItem(
          label: jobsLabel,
          icon: Icons.work_outline,
          selectedIcon: Icons.work,
        ),
        AppBottomNavItem(
          label: syncLabel,
          icon: Icons.sync_outlined,
          selectedIcon: Icons.sync,
        ),
        AppBottomNavItem(
          label: profileLabel,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
        ),
      ],
    );
  }
}

/// Figma four-item dock, gallery only (Intake / Fleet / Sync / Profile).
class TechnicianFigmaDockPreview extends StatelessWidget {
  const TechnicianFigmaDockPreview({
    required this.intakeLabel,
    required this.fleetLabel,
    required this.syncLabel,
    required this.profileLabel,
    this.selectedIndex = 0,
    super.key,
  });

  final String intakeLabel;
  final String fleetLabel;
  final String syncLabel;
  final String profileLabel;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavDock(
      selectedIndex: selectedIndex,
      items: [
        AppBottomNavItem(
          label: intakeLabel,
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
        ),
        AppBottomNavItem(
          label: fleetLabel,
          icon: Icons.local_shipping_outlined,
          selectedIcon: Icons.local_shipping,
        ),
        AppBottomNavItem(
          label: syncLabel,
          icon: Icons.sync_outlined,
          selectedIcon: Icons.sync,
        ),
        AppBottomNavItem(
          label: profileLabel,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
        ),
      ],
    );
  }
}

/// Original generic vehicle-type silhouette. No Figma photo, no plate and no
/// identifiable model is drawn.
class TechnicianVehicleSilhouette extends StatelessWidget {
  const TechnicianVehicleSilhouette({
    this.height = 120,
    this.semanticLabel,
    super.key,
  });

  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = context.brand.ink;
    final window = context.colors.surface;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _VehicleSilhouettePainter(color: color, window: window),
          ),
        ),
      ),
    );
  }
}

class _VehicleSilhouettePainter extends CustomPainter {
  const _VehicleSilhouettePainter({required this.color, required this.window});

  final Color color;
  final Color window;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = color;
    final glass = Paint()..color = window;
    final w = size.width;
    final h = size.height;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.42, w * 0.84, h * 0.38),
      Radius.circular(h * 0.12),
    );
    canvas.drawRRect(bodyRect, body);
    final cabin = Path()
      ..moveTo(w * 0.26, h * 0.44)
      ..lineTo(w * 0.36, h * 0.2)
      ..quadraticBezierTo(w * 0.38, h * 0.16, w * 0.44, h * 0.16)
      ..lineTo(w * 0.62, h * 0.16)
      ..quadraticBezierTo(w * 0.68, h * 0.16, w * 0.7, h * 0.2)
      ..lineTo(w * 0.8, h * 0.44)
      ..close();
    canvas.drawPath(cabin, body);
    final windshield = Path()
      ..moveTo(w * 0.31, h * 0.41)
      ..lineTo(w * 0.39, h * 0.23)
      ..lineTo(w * 0.49, h * 0.23)
      ..lineTo(w * 0.49, h * 0.41)
      ..close();
    canvas.drawPath(windshield, glass);
    final rear = Path()
      ..moveTo(w * 0.53, h * 0.41)
      ..lineTo(w * 0.53, h * 0.23)
      ..lineTo(w * 0.64, h * 0.23)
      ..lineTo(w * 0.71, h * 0.41)
      ..close();
    canvas.drawPath(rear, glass);
    final wheel = Paint()..color = color;
    final rim = Paint()..color = window;
    for (final cx in [w * 0.26, w * 0.74]) {
      canvas.drawCircle(Offset(cx, h * 0.8), h * 0.12, wheel);
      canvas.drawCircle(Offset(cx, h * 0.8), h * 0.055, rim);
    }
    final lamp = Paint()..color = window;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.58, w * 0.06, h * 0.05),
        Radius.circular(h * 0.025),
      ),
      lamp,
    );
  }

  @override
  bool shouldRepaint(covariant _VehicleSilhouettePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.window != window;
}

class TechnicianLabeledValue extends StatelessWidget {
  const TechnicianLabeledValue({
    required this.label,
    required this.value,
    this.valueTextDirection,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String value;
  final TextDirection? valueTextDirection;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          value,
          textDirection: valueTextDirection,
          style:
              (emphasized
                      ? context.texts.titleLarge
                      : context.texts.bodyLarge)
                  ?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                  ),
        ),
      ],
    );
  }
}

class TechnicianSectionTitle extends StatelessWidget {
  const TechnicianSectionTitle({
    required this.title,
    this.trailing,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: context.spacing.xxs),
                Text(
                  subtitle!,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: context.spacing.sm),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

class TechnicianMetaPill extends StatelessWidget {
  const TechnicianMetaPill({
    required this.label,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: context.spacing.xxl),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? context.brand.container
            : context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: context.texts.labelMedium?.copyWith(
          color: emphasized
              ? context.brand.onContainer
              : context.colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Coverage ring: counts only, never a condition score.
class TechnicianCoverageRing extends StatelessWidget {
  const TechnicianCoverageRing({
    required this.done,
    required this.total,
    required this.label,
    required this.ofLabel,
    required this.semanticsLabel,
    this.size = 176,
    super.key,
  });

  final int done;
  final int total;
  final String label;
  final String ofLabel;
  final String semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: '$done / $total',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            ExcludeSemantics(
              child: CustomPaint(
                size: Size.square(size),
                painter: _CoverageArcPainter(
                  fraction: fraction,
                  track: context.colors.surfaceContainerHighest,
                  arc: context.brand.fill,
                  strokeWidth: context.spacing.md,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.all(context.spacing.md),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$done',
                      textDirection: TextDirection.ltr,
                      style: context.texts.displayMedium?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      ofLabel,
                      textDirection: TextDirection.ltr,
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: context.texts.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageArcPainter extends CustomPainter {
  const _CoverageArcPainter({
    required this.fraction,
    required this.track,
    required this.arc,
    required this.strokeWidth,
  });

  final double fraction;
  final Color track;
  final Color arc;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final arcPaint = Paint()
      ..color = arc
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoverageArcPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.track != track ||
      oldDelegate.arc != arc ||
      oldDelegate.strokeWidth != strokeWidth;
}

class TechnicianModuleCard extends StatelessWidget {
  const TechnicianModuleCard({
    required this.title,
    required this.countLabel,
    required this.stateLabel,
    required this.icon,
    this.onTap,
    super.key,
  });

  final String title;
  final String countLabel;
  final String stateLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: context.radii.cardLarge,
      padding: EdgeInsetsDirectional.all(context.spacing.gutter),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.spacing.xxl,
            height: context.spacing.xxl,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(context.radii.lg),
            ),
            child: Icon(
              icon,
              size: context.sizing.iconMd,
              color: context.brand.ink,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            countLabel,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            stateLabel,
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicianResultChip extends StatelessWidget {
  const TechnicianResultChip({
    required this.label,
    this.tone = StatusTone.neutral,
    this.count,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: count == null ? label : '$count $label', tone: tone);
  }
}





