// THROWAWAY screenshot harness for the real staff pages — deleted after QA.
// query: v=member|member-disabled|create, rtl=1, dark=1
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_create_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_member_page.dart';
import 'package:workshop_admin_app/src/models.dart';

void main() {
  final q = Uri.base.queryParameters;
  final rtl = q['rtl'] == '1';
  final view = q['v'] ?? 'member';
  runApp(
    ProviderScope(
      overrides: [
        staffProvider.overrideWith(
          (ref) async => _sample(rtl, disabled: view == 'member-disabled'),
        ),
      ],
      child: _App(view: view, rtl: rtl, dark: q['dark'] == '1'),
    ),
  );
}

const _enNames = <String>[
  'Youssef Abdelrahman El-Sayed',
  'Nadia Farouk',
  'Omar Haddad',
];

const _arNames = <String>['يوسف عبد الرحمن السيد', 'نادية فاروق', 'عمر حداد'];

List<StaffMember> _sample(bool arabic, {required bool disabled}) {
  final names = arabic ? _arNames : _enNames;
  return [
    StaffMember(
      userId: 'u-1',
      displayName: names[0],
      emailMasked: 'y.e***@truereport.app',
      role: 'TECHNICIAN',
      status: disabled ? 'DISABLED' : 'ACTIVE',
    ),
    StaffMember(
      userId: 'u-2',
      displayName: names[1],
      emailMasked: 'n***@truereport.app',
      role: 'WORKSHOP_ADMIN',
      status: 'ACTIVE',
    ),
    StaffMember(
      userId: 'u-3',
      displayName: names[2],
      emailMasked: 'o***@gmail.com',
      role: 'TECHNICIAN',
      status: 'PENDING',
    ),
  ];
}

String _initialName(bool arabic) => arabic ? _arNames[0] : _enNames[0];

class _App extends StatelessWidget {
  const _App({required this.view, required this.rtl, required this.dark});

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
      home: view == 'create'
          ? const StaffCreatePage()
          : StaffMemberPage(memberId: 'u-1', initialName: _initialName(rtl)),
    );
  }
}

ThemeData _theme({required bool dark, required bool isArabic}) {
  final base = AppTheme.build(isArabic: isArabic);
  if (!dark) {
    return base;
  }
  // Harness-only: the app ships light-only (AppTheme asserts Brightness.light).
  // A real dark palette would ship a dark text theme; the primitive field
  // labels inherit their colour from it.
  final darkText = base.textTheme.apply(
    bodyColor: const Color(0xFFF1F1EA),
    displayColor: const Color(0xFFF1F1EA),
  );
  final ws = WorkshopTokens.standard(darkText, isArabic: isArabic);
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
    textTheme: darkText,
    scaffoldBackgroundColor: d.canvas,
    extensions: [
      ...base.extensions.values.where((e) => e is! WorkshopTokens),
      d,
    ],
  );
}
