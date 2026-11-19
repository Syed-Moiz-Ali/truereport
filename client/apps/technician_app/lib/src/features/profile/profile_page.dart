import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Full-screen technician profile: identity badge, language, sign out.
class TechnicianProfilePage extends ConsumerWidget {
  const TechnicianProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final session = ref.watch(authControllerProvider).value;
    final role = l10n.roleTechnician;
    final name = session?.user.displayName ?? role;
    final email = session?.user.email;
    final locale = ref.watch(localeProvider);

    return AppScaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: Column(
        children: [
          Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      l10n.technicianProfileTitle,
                      style: context.texts.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipPath(
                        clipper: const _BadgeClip(),
                        child: Container(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            20,
                            26,
                            20,
                            20,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              TechnicianAvatar(name: name, size: 72),
                              const SizedBox(height: 12),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: context.texts.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (email != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  textDirection: TextDirection.ltr,
                                  style: context.texts.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                height: 28,
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_outlined,
                                      size: 14,
                                      color: context.brand.ink,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      role,
                                      style: context.texts.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: context.brand.ink,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsetsDirectional.all(14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.technicianLanguage,
                              style: context.texts.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _LanguagePill(
                              englishLabel: l10n.languageEnglish,
                              arabicLabel: l10n.languageArabic,
                              isArabic: locale.languageCode == 'ar',
                              onChanged: (isArabic) => ref
                                  .read(localeProvider.notifier)
                                  .setLocale(Locale(isArabic ? 'ar' : 'en')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(height: 1, color: colors.outlineVariant),
                      const SizedBox(height: 16),
                      Center(
                        child: _SignOutButton(
                          label: l10n.signOut,
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'TrueReport · $role',
                          style: context.texts.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final danger = context.statusColors.danger;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: context.motionDuration(const Duration(milliseconds: 140)),
            height: 48,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: _hovered ? danger.background : context.colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _focused ? context.colors.focus : danger.background,
                width: _focused ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: context.texts.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: danger.foreground,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.logout_rounded, size: 18, color: danger.foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.englishLabel,
    required this.arabicLabel,
    required this.isArabic,
    required this.onChanged,
  });

  final String englishLabel;
  final String arabicLabel;
  final bool isArabic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _LanguageSeg(
            label: englishLabel,
            selected: !isArabic,
            onTap: () => onChanged(false),
          ),
          _LanguageSeg(
            label: arabicLabel,
            selected: isArabic,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _LanguageSeg extends StatelessWidget {
  const _LanguageSeg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: context.motionDuration(const Duration(milliseconds: 150)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: selected
                  ? Border.all(color: colors.outlineVariant)
                  : null,
            ),
            child: Text(
              label,
              style: context.texts.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeClip extends CustomClipper<Path> {
  const _BadgeClip();

  @override
  Path getClip(Size size) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    return Path.combine(
      PathOperation.difference,
      body,
      Path()..addOval(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 10),
      ),
    );
  }

  @override
  bool shouldReclip(_BadgeClip oldClipper) => false;
}
