import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hdr2 dump', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(isArabic: false),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: WorkshopHeader(
              title: 'Dashboard',
              search: const SizedBox(height: 48, child: Text('search')),
              actions: [
                AppButton(label: 'New', onPressed: () {}),
              ],
              user: const WorkshopUserChip(
                initials: 'DV',
                displayName: 'David Vance',
                workshopName: 'Workshop',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
