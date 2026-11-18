import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Calm, consumer-grade Workshop Admin sign-in.
///
/// Wide screens get a 50/50 split:
/// - Left: Deep green panel (#0F5C4A) with subtle geometric grid lines,
///   brand badge, bold headline, supporting value prop, and a realistic
///   product preview mock (mini job card with progress and tech assignment).
///   Zero fake security badges or marketing claims.
/// - Right: Warm off-white canvas with a centered 400 px form, 28/700 title,
///   eye toggle on password, 48 px full-width button, and inline error banner.
///
/// Narrow screens (< 900 px) display the logo and language toggle on top,
/// followed immediately by the form (no full-screen green slab).
class WorkshopLoginPage extends ConsumerStatefulWidget {
  const WorkshopLoginPage({super.key});

  @override
  ConsumerState<WorkshopLoginPage> createState() => _WorkshopLoginPageState();
}

class _WorkshopLoginPageState extends ConsumerState<WorkshopLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _errorKey;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorKey = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text, _password.text);
      if (!mounted) {
        return;
      }
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = _messageFor(failure.code));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = 'genericError');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _messageFor(String code) {
    return switch (code) {
      'AUTH_INVALID_CREDENTIALS' => 'invalidCredentials',
      'NETWORK' ||
      'CONNECTIONERROR' ||
      'CONNECTIONTIMEOUT' ||
      'RECEIVETIMEOUT' ||
      'SENDTIMEOUT' => 'networkError',
      _ => 'genericError',
    };
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value);
    if (required != null) {
      return required;
    }
    return Validators.email(value) == null
        ? null
        : AppLocalizations.of(context).invalidEmail;
  }

  void _toggleLanguage(bool isArabic) {
    ref.read(localeProvider.notifier).setLocale(Locale(isArabic ? 'ar' : 'en'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final errorText = switch (_errorKey) {
      'invalidCredentials' => l10n.invalidCredentials,
      'networkError' => l10n.networkError,
      'genericError' => l10n.genericError,
      _ => null,
    };

    final languageButton = WorkshopButton(
      label: isArabic ? l10n.languageEnglish : l10n.languageArabic,
      icon: Icons.language,
      variant: WorkshopButtonVariant.ghost,
      onPressed: () => _toggleLanguage(!isArabic),
    );

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final form = _buildForm(context, l10n: l10n, errorText: errorText);

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: ws.pageGutterPhone,
                      vertical: spacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: ws.surface,
                      border: BorderDirectional(
                        bottom: BorderSide(color: ws.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ws.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'TR',
                            style: ws.meta.copyWith(
                              color: ws.onAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TrueReport',
                                style: ws.sectionTitle.copyWith(
                                  color: ws.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.signInPortalLabel,
                                style: ws.meta.copyWith(color: ws.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                        languageButton,
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: ws.pagePaddingOf(context),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BrandPanel(l10n: l10n),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsetsDirectional.all(spacing.massive),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: form,
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: spacing.lg,
                        end: spacing.lg,
                        child: languageButton,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required AppLocalizations l10n,
    required String? errorText,
  }) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.signInTitle,
            style: ws.pageTitle.copyWith(letterSpacing: -0.5),
          ),
          SizedBox(height: spacing.xs),
          Text(
            l10n.signInSubtitle,
            style: ws.body.copyWith(color: ws.muted),
          ),
          SizedBox(height: spacing.xl),
          WorkshopTextField(
            key: const Key('sign-in-email'),
            controller: _email,
            label: l10n.emailLabel,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            validator: _validateEmail,
          ),
          SizedBox(height: spacing.lg),
          WorkshopTextField(
            key: const Key('sign-in-password'),
            controller: _password,
            label: l10n.passwordLabel,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: ws.muted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: _required,
            onFieldSubmitted: (_) {
              if (!_submitting) {
                _submit();
              }
            },
          ),
          if (errorText != null) ...[
            SizedBox(height: spacing.md),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: EdgeInsetsDirectional.all(spacing.sm),
                decoration: BoxDecoration(
                  color: ws.dangerSoft,
                  borderRadius: BorderRadius.circular(ws.controlRadius),
                  border: Border.all(
                    color: ws.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: ws.danger),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        errorText,
                        style: ws.body.copyWith(
                          color: ws.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: spacing.xl),
          WorkshopButton(
            key: const Key('sign-in-submit'),
            label: l10n.signInButton,
            expand: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          SizedBox(height: spacing.lg),
          Center(
            child: Text(
              l10n.signInHelp,
              style: ws.meta.copyWith(color: ws.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return CustomPaint(
      painter: const _GridPatternPainter(),
      child: Container(
        color: ws.accent,
        padding: EdgeInsetsDirectional.all(spacing.massive),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ws.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'TR',
                    style: ws.meta.copyWith(
                      color: ws.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TrueReport',
                      style: ws.sectionTitle.copyWith(
                        color: ws.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.signInPortalLabel,
                      style: ws.meta.copyWith(
                        color: ws.onAccent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Inspections your\ncustomers can trust.',
              style: ws.pageTitle.copyWith(
                color: ws.onAccent,
                fontSize: 36,
                height: 44 / 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: spacing.md),
            Text(
              l10n.signInBrandLine,
              style: ws.body.copyWith(
                color: ws.onAccent.withValues(alpha: 0.85),
                fontSize: 15,
                height: 22 / 15,
              ),
            ),
            SizedBox(height: spacing.xl),
            _ProductPreviewMock(l10n: l10n),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Realistic UI preview mock shown on the desktop brand panel.
class _ProductPreviewMock extends StatelessWidget {
  const _ProductPreviewMock({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '2023 Porsche 911 GT3',
                  style: ws.cardTitle.copyWith(color: ws.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.sm,
                  vertical: spacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: ws.warningSoft,
                  borderRadius: BorderRadius.circular(ws.chipRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ws.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: spacing.xs),
                    Text(
                      l10n.statusInProgress,
                      style: ws.eyebrow.copyWith(
                        color: ws.warning,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Row(
            children: [
              Text(
                'DXB 48291',
                style: ws.meta.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: ws.ink,
                ),
              ),
              SizedBox(width: spacing.sm),
              Text('·', style: ws.meta.copyWith(color: ws.muted)),
              SizedBox(width: spacing.sm),
              Text(
                'Rashid Al Mansoori',
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inspection checklist',
                style: ws.eyebrow.copyWith(color: ws.muted, letterSpacing: 0),
              ),
              Text(
                '18 / 24 items (75%)',
                style: ws.eyebrow.copyWith(
                  color: ws.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: 0.75,
                backgroundColor: ws.border,
                valueColor: AlwaysStoppedAnimation<Color>(ws.accent),
              ),
            ),
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              const WorkshopAvatar(
                initials: 'KA',
                semanticLabel: 'Karim Ahmed',
                size: 24,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  'Karim Ahmed · Lead Tech',
                  style: ws.meta.copyWith(color: ws.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Started 45m ago',
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Subtle geometric grid lines on the brand panel.
class _GridPatternPainter extends CustomPainter {
  const _GridPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
