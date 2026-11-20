import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.build(),
    home: Scaffold(body: Builder(builder: (_) => child)),
  );
}

void main() {
  test('statusToneFromToken maps the contract tokens', () {
    expect(statusToneFromToken('neutral'), StatusTone.neutral);
    expect(statusToneFromToken('info'), StatusTone.info);
    expect(statusToneFromToken('success'), StatusTone.success);
    expect(statusToneFromToken('warning'), StatusTone.warning);
    expect(statusToneFromToken('danger'), StatusTone.danger);
    expect(statusToneFromToken('critical'), StatusTone.critical);
    expect(statusToneFromToken('unknown'), StatusTone.neutral);
  });

  testWidgets('OptionDropdown renders the closed list and reports selection', (
    tester,
  ) async {
    String? selected = 'A';
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            return OptionDropdown<String>(
              key: const Key('dropdown'),
              items: const <String>['A', 'B', 'C'],
              value: selected,
              labelOf: (value) => 'Option $value',
              onChanged: (value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );

    expect(find.text('Option A'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('Option B'), findsOneWidget);
    expect(find.text('Option C'), findsOneWidget);
    await tester.tap(find.text('Option C').last);
    await tester.pumpAndSettle();
    expect(selected, 'C');
  });

  testWidgets('TransitionActions builds only allowed transitions', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      _app(
        TransitionActions<String>(
          records: const <String>['APPROVE', 'REJECT', 'PUBLISH'],
          allowedOf: (code) => code != 'PUBLISH',
          labelOf: (code) => code,
          onTap: tapped.add,
        ),
      ),
    );

    expect(find.text('APPROVE'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
    expect(find.text('PUBLISH'), findsNothing);

    await tester.tap(find.text('APPROVE'));
    await tester.pump();
    expect(tapped, <String>['APPROVE']);
  });
}
