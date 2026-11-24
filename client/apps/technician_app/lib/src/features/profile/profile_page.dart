import 'dart:math' as math;

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart' show Membership;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/technician_providers.dart';

/// The technician's card: who they are on a dark identity panel, then the two
/// things they can act on — the sync queue and the language — and the way out.
class TechnicianProfilePage extends ConsumerWidget {
  const TechnicianProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final session = ref.watch(authControllerProvider).value;
    final role = t(TechnicianKeys.roleTechnician);
    final name = session?.user.displayName ?? role;
    final email = session?.user.email;
    final memberships = session?.memberships ?? const <Membership>[];
    final workshop = memberships.isEmpty ? '' : memberships.first.workshopName;
    final languages = ref.watch(
      supportedLocalesProvider(technicianUiMessageClient),
    );
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    final waiting = (sync?.pending ?? 0) + (sync?.failed ?? 0);
    final conflicts = sync?.conflicts ?? 0;
    final tone = conflicts > 0
        ? StatusTone.danger
        : waiting > 0
        ? StatusTone.warning
        : StatusTone.success;
    final syncDetail = conflicts > 0
        ? t(TechnicianKeys.technicianSyncConflictsCount, {'count': conflicts})
        : waiting > 0
        ? '$waiting · ${t(TechnicianKeys.technicianSyncPending)}'
        : t(TechnicianKeys.technicianAllSynced);

    return AppScaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ScreenBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ConstrainedBox(
                        // Content is short: anchor the footer to the bottom of
                        // the viewport so the screen reads as designed rather
                        // than top-heavy.
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 26,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeroCard(
                                name: name,
                                email: email,
                                role: role,
                                workshop: workshop,
                              ),
                              const SizedBox(height: 14),
                              // The queue is the one action a profile usually hides.
                              _ActionCard(
                                icon: Icons.sync_rounded,
                                iconTone: tone,
                                title: t(TechnicianKeys.technicianSyncTitle),
                                detail: syncDetail,
                                onTap: () => context.push('/sync'),
                              ),
                              if (languages.length > 1) ...[
                                const SizedBox(height: 10),
                                _LanguageCard(
                                  label: t(TechnicianKeys.settingsLanguage),
                                ),
                              ],
                              if (constraints.maxWidth < 760) const Spacer(),
                              const SizedBox(height: 26),
                              _SignOutButton(
                                label: t(TechnicianKeys.signOut),
                                onPressed: () => _signOut(context, ref),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '${t(TechnicianKeys.appTitle)} · $role',
                                textAlign: TextAlign.center,
                                style: context.texts.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final t = UiStrings.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: t(TechnicianKeys.signOut),
      message: t(TechnicianKeys.technicianSignOutBody),
      confirmLabel: t(TechnicianKeys.signOut),
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _ScreenBar extends StatelessWidget {
  const _ScreenBar();

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          child: Row(
            children: [
              Text(
                t(TechnicianKeys.technicianProfileTitle),
                style: context.texts.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The identity panel: ink, a ring behind the avatar, and the facts that
/// identify this technician at a bay door.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.email,
    required this.role,
    required this.workshop,
  });

  final String name;
  final String? email;
  final String role;
  final String workshop;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ink = context.brand.ink;
    const white = Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingsPainter(
                color: white.withValues(alpha: 0.06),
                passes: 4,
              ),
            ),
          ),
          ColoredBox(
            color: ink,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(TechnicianKeys.technicianSignedInAs).toUpperCase(),
                    style: context.texts.labelSmall?.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: TechnicianAvatar(name: name, size: 56),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                                color: white,
                              ),
                            ),
                            if (email != null && email!.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: context.texts.bodySmall?.copyWith(
                                  color: white.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassPill(icon: Icons.verified_outlined, label: role),
                      if (workshop.isNotEmpty)
                        _GlassPill(
                          icon: Icons.storefront_outlined,
                          label: workshop,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.color, required this.passes});

  final Color color;
  final int passes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final centre = Offset(size.width + 10, -8);
    for (var index = 1; index <= passes; index++) {
      canvas.drawCircle(centre, 46.0 * index, paint);
    }
    // A second, fainter fan from the bottom-left corner.
    final soft = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var index = 1; index <= 3; index++) {
      canvas.drawCircle(
        Offset(-14, size.height + 6),
        40.0 + 34.0 * index,
        soft,
      );
    }
    if (math.max(size.width, size.height) < 0) {
      // Keeps the import honest on platforms without cupertino shapes.
      canvas.drawRect(Rect.zero, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.passes != passes;
}

/// One tappable row, given room to breathe: icon tile, title, detail.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    required this.iconTone,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final StatusTone iconTone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(iconTone);
    return Semantics(
      button: true,
      label: '$title, $detail',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pair.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: pair.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.brand.container,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.translate_rounded,
              size: 19,
              color: context.brand.onContainer,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: BackendLanguageSelector(
              client: technicianUiMessageClient,
              keyPrefix: 'profile-language',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final danger = context.statusColors.danger;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: danger.background),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 17, color: danger.foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.texts.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: danger.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
