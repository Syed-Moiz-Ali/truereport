/// Real-font screenshots of the Fieldwork shell: dock below 900, rail above.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dark_proof.dart';
import 'support/shell_sample.dart';

Future<void> _shot(
  WidgetTester tester, {
  required double width,
  required double height,
  required String name,
  required int index,
  bool rtl = false,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final data = PreviewShellData(arabic: rtl);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? darkProofTheme() : AppTheme.light,
      locale: Locale(rtl ? 'ar' : 'en'),
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: ShellPreviewScreen(data: data, initialIndex: index),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  testWidgets('shell_390', (tester) async {
    await _shot(tester, width: 390, height: 844, name: 'shell_390', index: 0);
  });

  testWidgets('shell_390_profile', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'shell_390_profile',
      index: 1,
    );
  });

  testWidgets('shell_1024', (tester) async {
    await _shot(tester, width: 1024, height: 768, name: 'shell_1024', index: 0);
  });

  testWidgets('shell_1024_profile', (tester) async {
    await _shot(
      tester,
      width: 1024,
      height: 768,
      name: 'shell_1024_profile',
      index: 1,
    );
  });

  testWidgets('shell_1440', (tester) async {
    await _shot(tester, width: 1440, height: 900, name: 'shell_1440', index: 0);
  });

  testWidgets('shell_390_rtl', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'shell_390_rtl',
      index: 0,
      rtl: true,
    );
  });

  testWidgets('shell_1024_rtl', (tester) async {
    await _shot(
      tester,
      width: 1024,
      height: 768,
      name: 'shell_1024_rtl',
      index: 1,
      rtl: true,
    );
  });

  testWidgets('shell_1440_dark', (tester) async {
    await _shot(
      tester,
      width: 1440,
      height: 900,
      name: 'shell_1440_dark',
      index: 0,
      dark: true,
    );
  });
}
