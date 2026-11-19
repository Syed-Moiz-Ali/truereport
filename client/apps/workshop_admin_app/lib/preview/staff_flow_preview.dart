// THROWAWAY design-preview — deleted after the direction is chosen.
// query: d=a|b|c, v=member|create|tile, rtl=1, dark=1
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';

void main() {
  final q = Uri.base.queryParameters;
  runApp(
    _App(
      direction: q['d'] ?? 'a',
      view: q['v'] ?? 'member',
      rtl: q['rtl'] == '1',
      dark: q['dark'] == '1',
    ),
  );
}

const _member = StaffMember(
  userId: 'u-1',
  displayName: 'Youssef Abdelrahman El-Sayed',
  emailMasked: 'y.e***@truereport.app',
  role: 'TECHNICIAN',
  status: 'ACTIVE',
);

class _App extends StatelessWidget {
  const _App({
    required this.direction,
    required this.view,
    required this.rtl,
    required this.dark,
  });

  final String direction;
  final String view;
  final bool rtl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(dark: dark, isArabic: rtl),
      locale: Locale(rtl ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: view == 'tile'
          ? _TilePage(direction: direction)
          : _Frame(direction: direction, view: view),
    );
  }
}

ThemeData _theme({required bool dark, required bool isArabic}) {
  final base = AppTheme.build(isArabic: isArabic);
  if (!dark) {
    return base;
  }
  final ws = WorkshopTokens.standard(base.textTheme, isArabic: isArabic);
  final d = ws.copyWith(
    canvas: const Color(0xFF101310),
    surface: const Color(0xFF171B17),
    ink: const Color(0xFFF1F1EA),
    muted: const Color(0xFF9AA199),
    border: const Color(0xFF29302A),
    accent: const Color(0xFF47BE94),
    accentHover: const Color(0xFF5FD3A9),
    accentSoft: const Color(0xFF15352B),
    onAccent: const Color(0xFF08120E),
    success: const Color(0xFF52C296),
    successSoft: const Color(0xFF143128),
    warning: const Color(0xFFE0A55B),
    warningSoft: const Color(0xFF33260F),
    danger: const Color(0xFFE8776B),
    dangerSoft: const Color(0xFF3A1B18),
    focus: const Color(0xFF7FB2FF),
  );
  return base.copyWith(
    scaffoldBackgroundColor: d.canvas,
    extensions: [
      ...base.extensions.values.where((e) => e is! WorkshopTokens),
      d,
    ],
  );
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

class _Frame extends StatelessWidget {
  const _Frame({required this.direction, required this.view});

  final String direction;
  final String view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final memberView = view == 'member';
    final title = memberView ? _member.displayName : l10n.createTechnicianTitle;
    final body = memberView
        ? switch (direction) {
            'b' => const _MemberWorkbench(),
            'c' => const _MemberCanvas(),
            _ => const _MemberDossier(),
          }
        : switch (direction) {
            'b' => const _CreateWorkbench(),
            'c' => const _CreateCanvas(),
            _ => const _CreateDossier(),
          };
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: SizedBox(
                height: ws.topBarHeight,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                      child: Row(
                        children: [
                          WorkshopIconButton(
                            icon: isRtl
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            semanticLabel: l10n.commonBack,
                            onPressed: () {},
                          ),
                          SizedBox(width: context.spacing.sm),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ws.bodyStrong.copyWith(color: ws.ink),
                            ),
                          ),
                          if (memberView)
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: context.spacing.sm,
                              ),
                              child: _StatusPill(status: _member.status),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final label = memberStatusLabel(AppLocalizations.of(context), status);
    final color = status == 'ACTIVE'
        ? ws.success
        : status == 'PENDING'
        ? ws.warning
        : ws.danger;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: status == 'ACTIVE'
            ? ws.successSoft
            : status == 'PENDING'
            ? ws.warningSoft
            : ws.dangerSoft,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: ws.eyebrow.copyWith(color: color, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.name, this.size = 44, this.filled = false});
  final String name;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? ws.accent : ws.accentSoft,
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Text(
        _initials(name),
        style: ws.bodyStrong.copyWith(
          color: filled ? ws.onAccent : ws.accent,
          fontSize: size * 0.32,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  final first = parts.first.characters.first;
  if (!RegExp(r'[A-Za-z]').hasMatch(first)) {
    return first;
  }
  if (parts.length == 1) {
    return first.toUpperCase();
  }
  return (first + parts[1].characters.first).toUpperCase();
}

Widget _rule(BuildContext context) =>
    Container(height: 1, width: double.infinity, color: context.ws.border);

/// Surface used by every block in these directions.
class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = 24, super.key});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        border: Border.all(color: ws.border),
      ),
      child: child,
    );
  }
}

Widget _label(BuildContext context, String text) => Text(
  text.toUpperCase(),
  style: context.ws.eyebrow.copyWith(color: context.ws.muted),
);

/// Page scroller that mirrors the app's pushed-page gutters.
class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.children, this.maxWidth});
  final List<Widget> children;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      padding: ws.pagePadding(width),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? ws.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.hint,
    this.helper,
    this.error,
    this.obscure = false,
    this.width,
    this.suffix,
  });

  final String label;
  final String hint;
  final String? helper;
  final String? error;
  final bool obscure;
  final double? width;
  final Widget? suffix;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopTextField(
          controller: _controller,
          label: widget.label,
          hint: widget.hint,
          obscureText: widget.obscure,
          suffixIcon: widget.suffix,
        ),
        const SizedBox(height: 6),
        if (widget.error != null)
          Text(widget.error!, style: ws.meta.copyWith(color: ws.danger))
        else if (widget.helper != null)
          Text(widget.helper!, style: ws.meta.copyWith(color: ws.muted))
        else
          const SizedBox(height: 0),
      ],
    );
    if (widget.width == null) {
      return field;
    }
    return SizedBox(width: widget.width, child: field);
  }
}

// ---------------------------------------------------------------------------
// A — Dossier (numbered document sections)
// ---------------------------------------------------------------------------

class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.number,
    required this.title,
    this.trailing,
  });
  final String number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Row(
      children: [
        Text(
          number,
          style: ws.eyebrow.copyWith(
            color: ws.accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: ws.eyebrow.copyWith(color: ws.ink),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MemberDossier extends StatelessWidget {
  const _MemberDossier();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final role = memberRoleLabel(l10n, _member.role);
    return _PageScroll(
      maxWidth: 760,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Monogram(name: _member.displayName, size: 84, filled: true),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _member.displayName,
                    style: ws.pageTitle.copyWith(
                      fontSize: 34,
                      letterSpacing: -0.8,
                      color: ws.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(role, style: ws.meta.copyWith(color: ws.muted)),
                  const SizedBox(height: 6),
                  Text(
                    _member.emailMasked,
                    textDirection: TextDirection.ltr,
                    style: ws.bodyStrong.copyWith(fontSize: 14, color: ws.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _rule(context),
        const SizedBox(height: 24),
        _SectionHead(number: '01', title: l10n.status),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatusPill(status: _member.status),
            const SizedBox(width: 20),
            WorkshopButton(
              label: l10n.deactivate,
              variant: WorkshopButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 28),
        _rule(context),
        const SizedBox(height: 24),
        _SectionHead(number: '02', title: l10n.staffResetPassword),
        const SizedBox(height: 16),
        _WideRow(
          children: [
            _Field(
              label: l10n.staffResetPassword,
              hint: l10n.temporaryPassword,
              obscure: true,
            ),
            _Field(
              label: l10n.confirmPasswordLabel,
              hint: l10n.confirmPasswordHint,
              obscure: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [WorkshopButton(label: l10n.save, onPressed: () {})],
        ),
        const SizedBox(height: 28),
        _rule(context),
        const SizedBox(height: 24),
        _SectionHead(number: '03', title: l10n.details),
        const SizedBox(height: 14),
        _Fact(label: l10n.displayName, value: _member.displayName),
        _Fact(label: l10n.emailLabel, value: _member.emailMasked, ltr: true),
        _Fact(label: l10n.role, value: role),
        _Fact(
          label: l10n.status,
          value: memberStatusLabel(l10n, _member.status),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({
    required this.children,
    this.gap = 16,
    this.breakpoint = 620,
  });

  final List<Widget> children;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= breakpoint;
        final spaced = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) {
            spaced.add(SizedBox(width: wide ? gap : 0, height: wide ? 0 : gap));
          }
          spaced.add(wide ? Expanded(child: children[i]) : children[i]);
        }
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: spaced,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: spaced,
              );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.ltr = false});
  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: ws.meta.copyWith(color: ws.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: ws.body.copyWith(color: ws.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateDossier extends StatelessWidget {
  const _CreateDossier();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: _PageScroll(
            maxWidth: 760,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.createTechnicianTitle,
                style: ws.pageTitle.copyWith(
                  fontSize: 34,
                  letterSpacing: -0.8,
                  color: ws.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.createTechnicianSubtitle,
                style: ws.body.copyWith(color: ws.muted),
              ),
              const SizedBox(height: 28),
              _rule(context),
              const SizedBox(height: 24),
              _SectionHead(number: '01', title: l10n.details),
              const SizedBox(height: 16),
              _Field(label: l10n.fullNameLabel, hint: l10n.fullNameHint),
              const SizedBox(height: 16),
              _Field(label: l10n.emailLabel, hint: 'name@workshop.com'),
              const SizedBox(height: 28),
              _rule(context),
              const SizedBox(height: 24),
              _SectionHead(number: '02', title: l10n.temporaryPassword),
              const SizedBox(height: 16),
              _Field(
                label: l10n.temporaryPassword,
                hint: l10n.temporaryPassword,
                obscure: true,
              ),
              const SizedBox(height: 16),
              _Field(
                label: l10n.confirmPasswordLabel,
                hint: l10n.confirmPasswordHint,
                obscure: true,
              ),
              const SizedBox(height: 28),
              _rule(context),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(l10n.role, style: ws.meta.copyWith(color: ws.muted)),
                  const SizedBox(width: 16),
                  Text(
                    l10n.roleTechnician,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        _FooterBar(
          children: [
            WorkshopButton(
              label: l10n.cancel,
              variant: WorkshopButtonVariant.ghost,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            WorkshopButton(label: l10n.create, onPressed: () {}),
          ],
        ),
      ],
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({required this.children, this.leading});
  final List<Widget> children;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(width),
        vertical: 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Row(
            children: [
              if (leading != null) Expanded(child: leading!),
              if (leading != null) const SizedBox(width: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B — Workbench (sticky identity rail + action modules)
// ---------------------------------------------------------------------------

class _MemberWorkbench extends StatelessWidget {
  const _MemberWorkbench();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final rail = _IdentityRail(
          name: _member.displayName,
          role: memberRoleLabel(l10n, _member.role),
          email: _member.emailMasked,
          status: _member.status,
        );
        final modules = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CredentialsModule(),
            const SizedBox(height: 20),
            _LifecycleModule(),
          ],
        );
        return _PageScroll(
          children: [
            const SizedBox(height: 8),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 300, child: rail),
                  const SizedBox(width: 24),
                  Expanded(child: modules),
                ],
              )
            else ...[
              rail,
              const SizedBox(height: 20),
              modules,
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class _IdentityRail extends StatelessWidget {
  const _IdentityRail({
    required this.name,
    required this.role,
    required this.email,
    required this.status,
  });

  final String name;
  final String role;
  final String email;
  final String status;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Monogram(name: name, size: 72, filled: true),
          const SizedBox(height: 16),
          Text(
            name,
            style: ws.sectionTitle.copyWith(fontSize: 22, color: ws.ink),
          ),
          const SizedBox(height: 6),
          Text(role, style: ws.meta.copyWith(color: ws.muted)),
          const SizedBox(height: 14),
          _StatusPill(status: status),
          const SizedBox(height: 18),
          _rule(context),
          const SizedBox(height: 14),
          _label(context, l10n.emailLabel),
          const SizedBox(height: 6),
          Text(
            email,
            textDirection: TextDirection.ltr,
            style: ws.bodyStrong.copyWith(fontSize: 13.5, color: ws.ink),
          ),
        ],
      ),
    );
  }
}

class _CredentialsModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(context, l10n.staffResetPassword),
          const SizedBox(height: 8),
          Text(
            l10n.temporaryPassword,
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 18),
          _WideRow(
            children: [
              _Field(
                label: l10n.staffResetPassword,
                hint: l10n.temporaryPassword,
                obscure: true,
                suffix: const Icon(Icons.visibility_outlined, size: 18),
              ),
              _Field(
                label: l10n.confirmPasswordLabel,
                hint: l10n.confirmPasswordHint,
                obscure: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [WorkshopButton(label: l10n.save, onPressed: () {})],
          ),
        ],
      ),
    );
  }
}

class _LifecycleModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(context, l10n.status),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${memberStatusLabel(l10n, _member.status)} — ${l10n.staffSubtitle}',
                  style: ws.body.copyWith(color: ws.muted),
                ),
              ),
              const SizedBox(width: 16),
              WorkshopButton(
                label: l10n.deactivate,
                variant: WorkshopButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ws.dangerSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(ws.cardRadius - 4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(label: l10n.deactivateReason, hint: l10n.reason),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    WorkshopButton(
                      label: l10n.cancel,
                      variant: WorkshopButtonVariant.ghost,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    WorkshopButton(
                      label: l10n.deactivate,
                      variant: WorkshopButtonVariant.danger,
                      onPressed: () {},
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

class _CreateWorkbench extends StatelessWidget {
  const _CreateWorkbench();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final form = _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, l10n.details),
              const SizedBox(height: 16),
              _Field(label: l10n.fullNameLabel, hint: l10n.fullNameHint),
              const SizedBox(height: 16),
              _Field(label: l10n.emailLabel, hint: 'name@workshop.com'),
              const SizedBox(height: 24),
              _rule(context),
              const SizedBox(height: 24),
              _label(context, l10n.temporaryPassword),
              const SizedBox(height: 16),
              _Field(
                label: l10n.temporaryPassword,
                hint: l10n.temporaryPassword,
                obscure: true,
                suffix: const Icon(Icons.visibility_outlined, size: 18),
              ),
              const SizedBox(height: 16),
              _Field(
                label: l10n.confirmPasswordLabel,
                hint: l10n.confirmPasswordHint,
                obscure: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  WorkshopButton(
                    label: l10n.cancel,
                    variant: WorkshopButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  const Spacer(),
                  WorkshopButton(label: l10n.create, onPressed: () {}),
                ],
              ),
            ],
          ),
        );
        final summary = _Surface(
          padding: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, l10n.role),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Monogram(name: l10n.roleTechnician, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.roleTechnician,
                          style: ws.bodyStrong.copyWith(
                            fontSize: 15,
                            color: ws.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StatusPill(status: 'PENDING'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _rule(context),
              const SizedBox(height: 14),
              _Fact(label: l10n.role, value: l10n.roleTechnician),
              _Fact(
                label: l10n.status,
                value: memberStatusLabel(l10n, 'PENDING'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
        return _PageScroll(
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.createTechnicianTitle,
              style: ws.pageTitle.copyWith(
                fontSize: 32,
                letterSpacing: -0.8,
                color: ws.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createTechnicianSubtitle,
              style: ws.body.copyWith(color: ws.muted),
            ),
            const SizedBox(height: 24),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 24),
                  SizedBox(width: 320, child: summary),
                ],
              )
            else ...[
              form,
              const SizedBox(height: 20),
              summary,
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: ws.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: ws.meta.copyWith(color: ws.muted)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// C — Canvas (hero band + dense tool rows)
// ---------------------------------------------------------------------------

class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.monogram,
  });

  final String title;
  final String subtitle;
  final String meta;

  /// Null when the page is not about one person (e.g. creating an account).
  final String? monogram;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: double.infinity,
      color: ws.accentSoft,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
        vertical: 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Row(
            children: [
              if (monogram != null)
                _Monogram(name: monogram!, size: 92, filled: true)
              else
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ws.surface,
                    borderRadius: BorderRadius.circular(92 * 0.36),
                    border: Border.all(color: ws.border),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 34,
                    color: ws.accent,
                  ),
                ),
              const SizedBox(width: 26),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ws.pageTitle.copyWith(
                        fontSize: 40,
                        height: 1.1,
                        letterSpacing: -1.2,
                        color: ws.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(subtitle, style: ws.meta.copyWith(color: ws.muted)),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      textDirection: TextDirection.ltr,
                      style: ws.bodyStrong.copyWith(
                        fontSize: 13.5,
                        color: ws.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.label,
    required this.description,
    required this.child,
  });

  final String label;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 760;
        return Container(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 22),
          decoration: BoxDecoration(
            border: BorderDirectional(top: BorderSide(color: ws.border)),
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(context, label),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(child: child),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(context, label),
                    const SizedBox(height: 6),
                    Text(description, style: ws.meta.copyWith(color: ws.muted)),
                    const SizedBox(height: 14),
                    child,
                  ],
                ),
        );
      },
    );
  }
}

class _MemberCanvas extends StatelessWidget {
  const _MemberCanvas();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _HeroBand(
          monogram: _member.displayName,
          title: _member.displayName,
          subtitle: memberRoleLabel(l10n, _member.role),
          meta: _member.emailMasked,
        ),
        Expanded(
          child: _PageScroll(
            children: [
              _ToolRow(
                label: l10n.status,
                description: l10n.staffSubtitle,
                child: Row(
                  children: [
                    _StatusPill(status: _member.status),
                    const Spacer(),
                    WorkshopButton(
                      label: l10n.deactivate,
                      variant: WorkshopButtonVariant.secondary,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              _ToolRow(
                label: l10n.staffResetPassword,
                description: l10n.temporaryPassword,
                child: _WideRow(
                  breakpoint: 900,
                  children: [
                    _Field(
                      label: l10n.temporaryPassword,
                      hint: l10n.temporaryPassword,
                      obscure: true,
                      suffix: const Icon(Icons.visibility_outlined, size: 18),
                    ),
                    _Field(
                      label: l10n.confirmPasswordLabel,
                      hint: l10n.confirmPasswordHint,
                      obscure: true,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 24),
                      child: WorkshopButton(label: l10n.save, onPressed: () {}),
                    ),
                  ],
                ),
              ),
              _ToolRow(
                label: l10n.details,
                description: '',
                child: Column(
                  children: [
                    _Fact(
                      label: l10n.role,
                      value: memberRoleLabel(l10n, _member.role),
                    ),
                    _Fact(
                      label: l10n.emailLabel,
                      value: _member.emailMasked,
                      ltr: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateCanvas extends StatelessWidget {
  const _CreateCanvas();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return Column(
      children: [
        _HeroBand(
          title: l10n.createTechnicianTitle,
          subtitle: l10n.createTechnicianSubtitle,
          meta: l10n.roleTechnician,
        ),
        Expanded(
          child: _PageScroll(
            children: [
              const SizedBox(height: 8),
              _Surface(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 700;
                    final a = _Field(
                      label: l10n.fullNameLabel,
                      hint: l10n.fullNameHint,
                    );
                    final b = _Field(
                      label: l10n.emailLabel,
                      hint: 'name@workshop.com',
                    );
                    final d = _Field(
                      label: l10n.temporaryPassword,
                      hint: l10n.temporaryPassword,
                      obscure: true,
                      suffix: const Icon(Icons.visibility_outlined, size: 18),
                    );
                    final e = _Field(
                      label: l10n.confirmPasswordLabel,
                      hint: l10n.confirmPasswordHint,
                      obscure: true,
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          a,
                          const SizedBox(height: 16),
                          b,
                          const SizedBox(height: 22),
                          _rule(context),
                          const SizedBox(height: 22),
                          d,
                          const SizedBox(height: 16),
                          e,
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: a),
                            const SizedBox(width: 20),
                            Expanded(child: b),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _rule(context),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: d),
                            const SizedBox(width: 20),
                            Expanded(child: e),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        Container(
          color: ws.ink,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 18,
                    color: ws.canvas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.createTechnicianSubtitle,
                      style: ws.meta.copyWith(color: ws.canvas),
                    ),
                  ),
                  const SizedBox(width: 16),
                  WorkshopButton(
                    label: l10n.cancel,
                    variant: WorkshopButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  WorkshopButton(label: l10n.create, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Style tile
// ---------------------------------------------------------------------------

class _TilePage extends StatelessWidget {
  const _TilePage({required this.direction});
  final String direction;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final name = switch (direction) {
      'b' => 'B — Workbench',
      'c' => 'C — Canvas',
      _ => 'A — Dossier',
    };
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'DIRECTION $name',
                  style: ws.eyebrow.copyWith(color: ws.accent),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Staff account',
                      style: ws.pageTitle.copyWith(fontSize: 34, color: ws.ink),
                    ),
                    const Spacer(),
                    _StatusPill(status: 'ACTIVE'),
                  ],
                ),
                const SizedBox(height: 22),
                _Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label(context, 'type'),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '01',
                            style: ws.pageTitle.copyWith(
                              fontSize: 44,
                              height: 1,
                              letterSpacing: -1.4,
                              color: ws.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Display 34/700',
                                  style: ws.pageTitle.copyWith(
                                    fontSize: 30,
                                    color: ws.ink,
                                  ),
                                ),
                                Text(
                                  'Section 22/700',
                                  style: ws.sectionTitle.copyWith(
                                    fontSize: 22,
                                    color: ws.ink,
                                  ),
                                ),
                                Text(
                                  'Body 14/400',
                                  style: ws.body.copyWith(color: ws.ink),
                                ),
                                Text(
                                  'Meta 12.5/500',
                                  style: ws.meta.copyWith(color: ws.muted),
                                ),
                                Text(
                                  'EYEBROW 11/600',
                                  style: ws.eyebrow.copyWith(color: ws.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _rule(context),
                      const SizedBox(height: 18),
                      _label(context, 'palette'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (n, c) in [
                            ('canvas', ws.canvas),
                            ('surface', ws.surface),
                            ('ink', ws.ink),
                            ('muted', ws.muted),
                            ('accent', ws.accent),
                            ('success', ws.success),
                            ('warning', ws.warning),
                            ('danger', ws.danger),
                          ])
                            _Swatch(label: n, color: c),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _rule(context),
                      const SizedBox(height: 18),
                      _label(context, 'field anatomy'),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              label: l10n.fullNameLabel,
                              hint: l10n.fullNameHint,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _Field(
                              label: l10n.emailLabel,
                              hint: 'name@workshop.com',
                              error: l10n.invalidEmail,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          WorkshopButton(label: l10n.create, onPressed: () {}),
                          WorkshopButton(
                            label: l10n.save,
                            variant: WorkshopButtonVariant.secondary,
                            onPressed: () {},
                          ),
                          WorkshopButton(
                            label: l10n.deactivate,
                            variant: WorkshopButtonVariant.danger,
                            onPressed: () {},
                          ),
                          _StatusPill(status: 'ACTIVE'),
                          _StatusPill(status: 'PENDING'),
                          _StatusPill(status: 'DISABLED'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: ws.border),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: ws.meta.copyWith(color: ws.muted, fontSize: 10.5)),
      ],
    );
  }
}
