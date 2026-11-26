import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';

/// The technician pass in the Fieldwork language: one dark identity card, one
/// surface of homogeneous actions, a quiet way out and the app signature.
///
/// Presentation only: the page resolves every string, reads the session, sync
/// queue and languages, and owns navigation, the language sheet and sign-out.
/// The preview harness mounts this same widget with sample data.

class ProfileHeaderData {
  const ProfileHeaderData({
    required this.title,
    required this.subtitle,
    this.statusLabel,
    this.statusTone = StatusTone.warning,
    this.statusIcon = Icons.cloud_off_rounded,
  });

  final String title;
  final String subtitle;

  /// "Offline" when a provider says so; null hides the pill.
  final String? statusLabel;
  final StatusTone statusTone;
  final IconData statusIcon;
}

class ProfileIdentityData {
  const ProfileIdentityData({
    required this.name,
    required this.role,
    required this.email,
    required this.workshop,
  });

  final String name;
  final String role;

  /// Empty hides the line.
  final String email;

  /// Empty hides the meta item.
  final String workshop;
}

class ProfileSyncData {
  const ProfileSyncData({
    required this.title,
    required this.detail,
    this.statusLabel,
    this.tone = StatusTone.neutral,
  });

  final String title;

  /// Served detail, e.g. "3 · Pending sync".
  final String detail;

  /// Short trailing state, e.g. "Conflict"; null for an unknown queue.
  final String? statusLabel;
  final StatusTone tone;
}

class ProfileLanguageData {
  const ProfileLanguageData({required this.title, required this.detail});

  final String title;

  /// The active language's native name.
  final String detail;
}

/// The whole profile screen. The page owns providers and actions; this widget
/// owns the layout and every state.
class ProfileBoard extends StatelessWidget {
  const ProfileBoard({
    required this.header,
    required this.identity,
    required this.sync,
    required this.signOutLabel,
    required this.footerLabel,
    required this.onSync,
    required this.onSignOut,
    this.language,
    this.offlineNote,
    this.onLanguage,
    super.key,
  });

  final ProfileHeaderData header;
  final ProfileIdentityData identity;
  final ProfileSyncData sync;

  /// Null hides the language row (a single-language manifest).
  final ProfileLanguageData? language;

  /// The queued-work reassurance; null hides it.
  final String? offlineNote;

  final String signOutLabel;
  final String footerLabel;

  final VoidCallback onSync;
  final VoidCallback onSignOut;
  final VoidCallback? onLanguage;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final hPad = screen >= 600 ? 24.0 : 16.0;
    return Column(
      children: [
        _ProfileHeader(data: header, hPad: hPad),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(hPad, 4, hPad, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ConstrainedBox(
                    // Short content anchors the sign-out and the footer to the
                    // bottom of the viewport instead of leaving a dead field.
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 28).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfilePass(data: identity),
                          const SizedBox(height: 12),
                          ProfileActions(
                            sync: sync,
                            language: language,
                            onSync: onSync,
                            onLanguage: onLanguage,
                          ),
                          if (offlineNote != null) ...[
                            const SizedBox(height: 10),
                            FieldworkNote(
                              message: offlineNote!,
                              tone: StatusTone.warning,
                              icon: Icons.cloud_off_rounded,
                            ),
                          ],
                          const SizedBox(height: 24),
                          const FieldworkDivider(),
                          const SizedBox(height: 10),
                          ProfileSignOut(
                            label: signOutLabel,
                            onPressed: onSignOut,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            footerLabel,
                            textAlign: TextAlign.center,
                            style: fieldworkText(
                              context,
                              11.5,
                              weight: FontWeight.w500,
                              height: 15,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data, required this.hPad});

  final ProfileHeaderData data;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(hPad, 8, hPad, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: fieldworkText(
                        context,
                        22,
                        weight: FontWeight.w800,
                        height: 27,
                        tracking: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        height: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.statusLabel != null) ...[
                const SizedBox(width: 10),
                FieldworkPill(
                  label: data.statusLabel!,
                  tone: data.statusTone,
                  icon: data.statusIcon,
                  dense: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The one dark surface: initials, name, email, role and workshop, with a quiet
/// ring pattern that never becomes a second brand.
class ProfilePass extends StatelessWidget {
  const ProfilePass({required this.data, super.key});

  final ProfileIdentityData data;

  @override
  Widget build(BuildContext context) {
    final ink = context.brand.ink;
    // The light build is a dark ink card; the proof-only dark palette flips the
    // brand ink to a light mint, so the foreground follows the fill, not the
    // brightness assumption. White-on-mint would fail contrast, so a bright
    // fill gets the dark ink instead.
    final onInk = ThemeData.estimateBrightnessForColor(ink) == Brightness.dark
        ? Colors.white
        : context.brand.onFill.computeLuminance() > 0.5
        ? const Color(0xFF0B0F14)
        : context.brand.onFill;
    final metaColor = onInk.withValues(alpha: 0.82);
    final email = data.email.trim();
    final workshop = data.workshop.trim();
    return FieldworkCard(
      color: ink,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _PassRingsPainter(
                  color: onInk.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: onInk.withValues(alpha: 0.3)),
                      ),
                      child: ExcludeSemantics(
                        child: TechnicianAvatar(
                          name: data.name,
                          size: 62,
                          semanticLabel: data.name,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.name,
                            style: fieldworkText(
                              context,
                              27,
                              weight: FontWeight.w800,
                              height: 32,
                              tracking: -0.7,
                              color: onInk,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              textDirection: TextDirection.ltr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: fieldworkText(
                                context,
                                12.5,
                                weight: FontWeight.w500,
                                height: 17,
                                color: metaColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: onInk.withValues(alpha: 0.14)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PassMeta(
                      icon: Icons.verified_outlined,
                      label: data.role,
                      style: fieldworkText(
                        context,
                        13,
                        weight: FontWeight.w700,
                        height: 17,
                        color: onInk,
                      ),
                    ),
                    if (workshop.isNotEmpty)
                      _PassMeta(
                        icon: Icons.storefront_outlined,
                        label: workshop,
                        style: fieldworkText(
                          context,
                          12.5,
                          weight: FontWeight.w600,
                          height: 17,
                          color: metaColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassMeta extends StatelessWidget {
  const _PassMeta({
    required this.icon,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: style.color),
        const SizedBox(width: 5),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}

/// A single quiet surface for homogeneous actions, separated by hairlines.
class ProfileActions extends StatelessWidget {
  const ProfileActions({
    required this.sync,
    required this.onSync,
    this.language,
    this.onLanguage,
    super.key,
  });

  final ProfileSyncData sync;
  final ProfileLanguageData? language;
  final VoidCallback onSync;
  final VoidCallback? onLanguage;

  @override
  Widget build(BuildContext context) {
    final syncPair = context.statusColors.forTone(sync.tone);
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileActionRow(
            icon: Icons.sync_rounded,
            iconBackground: syncPair.background,
            iconForeground: syncPair.foreground,
            title: sync.title,
            detail: sync.detail,
            statusLabel: sync.statusLabel,
            statusTone: sync.tone,
            showStatus: true,
            semanticLabel: [
              sync.title,
              sync.detail,
              if (sync.statusLabel != null) sync.statusLabel!,
            ].join('. '),
            onTap: onSync,
          ),
          if (language != null) ...[
            const FieldworkDivider(),
            ProfileActionRow(
              icon: Icons.translate_rounded,
              iconBackground: context.brand.container,
              iconForeground: context.brand.onContainer,
              title: language!.title,
              detail: language!.detail,
              semanticLabel: '${language!.title}. ${language!.detail}',
              onTap: onLanguage,
            ),
          ],
        ],
      ),
    );
  }
}

/// One tappable action line: icon tile, title, served detail, optional state
/// dot + label, chevron.
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    required this.title,
    required this.detail,
    required this.semanticLabel,
    required this.onTap,
    this.statusLabel,
    this.statusTone = StatusTone.neutral,
    this.showStatus = false,
    super.key,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String title;
  final String detail;
  final String? statusLabel;
  final StatusTone statusTone;

  /// A neutral dot still shows when the state is not known yet.
  final bool showStatus;
  final String semanticLabel;

  /// Null makes the row presentational.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(statusTone);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return FieldworkPress(
      onTap: onTap,
      radius: 0,
      semanticLabel: semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: iconForeground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        14,
                        weight: FontWeight.w700,
                        height: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        12,
                        weight: FontWeight.w500,
                        height: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showStatus) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: pair.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (statusLabel != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        statusLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fieldworkText(
                          context,
                          11.5,
                          weight: FontWeight.w600,
                          height: 15,
                          color: pair.foreground,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet outline destructive action, separated at the bottom.
class ProfileSignOut extends StatelessWidget {
  const ProfileSignOut({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final danger = context.statusColors.danger;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceLowest,
          borderRadius: BorderRadius.circular(FieldworkMetrics.controlRadius),
          border: Border.all(color: danger.foreground.withValues(alpha: 0.32)),
        ),
        clipBehavior: Clip.antiAlias,
        child: FieldworkPress(
          onTap: onPressed,
          radius: FieldworkMetrics.controlRadius,
          semanticLabel: label,
          child: ExcludeSemantics(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.flip(
                    flipX: rtl,
                    child: Icon(
                      Icons.logout_rounded,
                      size: 17,
                      color: danger.foreground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fieldworkText(
                      context,
                      14,
                      weight: FontWeight.w700,
                      height: 18,
                      color: danger.foreground,
                    ),
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

/// Rings that read as a pass watermark, never as a second brand.
class _PassRingsPainter extends CustomPainter {
  const _PassRingsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final topRight = Offset(size.width + 16, -12);
    for (var index = 1; index <= 4; index++) {
      canvas.drawCircle(topRight, 52.0 * index, paint);
    }
    final soft = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final bottomLeft = Offset(-16, size.height + 10);
    for (var index = 1; index <= 2; index++) {
      canvas.drawCircle(bottomLeft, 46.0 + 58.0 * index, soft);
    }
  }

  @override
  bool shouldRepaint(covariant _PassRingsPainter oldDelegate) =>
      oldDelegate.color != color;
}
