import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/components/platform_form.dart';
import 'package:platform_admin_app/src/platform_theme.dart';
import 'package:platform_admin_app/src/reference_status_lookup.dart';

Widget _app(Widget child, {List<Override> overrides = const <Override>[]}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

InputDecoration? _innerDecoration(WidgetTester tester) {
  return tester
      .widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.byType(TextField),
        ),
      )
      .decoration;
}

BorderRadiusGeometry? _buttonRadius(ElevatedButton button) {
  final shape = button.style?.shape?.resolve(<WidgetState>{});
  return shape is RoundedRectangleBorder ? shape.borderRadius : null;
}

void main() {
  testWidgets('primary button is a 48px pill', (tester) async {
    await tester.pumpWidget(
      _app(const PlatformPrimaryButton(label: 'Save', onPressed: _noop)),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.style!.minimumSize!.resolve(<WidgetState>{})!.height, 48);
    expect(_buttonRadius(button), BorderRadius.circular(PtTheme.controlRadius));
    expect(tester.getSize(find.byType(ElevatedButton)).height, 48);
  });

  testWidgets('secondary button is a 48px pill', (tester) async {
    await tester.pumpWidget(
      _app(const PlatformSecondaryButton(label: 'Cancel', onPressed: _noop)),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.style!.minimumSize!.resolve(<WidgetState>{})!.height, 48);
    expect(tester.getSize(find.byType(OutlinedButton)).height, 48);
  });

  testWidgets('text field puts the label above and the hint inside', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 320,
          child: PlatformTextField(label: 'Workshop name', hint: 'Acme Ltd'),
        ),
      ),
    );

    final decoration = _innerDecoration(tester);
    expect(decoration?.labelText, isNull);
    expect(decoration?.hintText, 'Acme Ltd');
    expect(decoration?.constraints?.minHeight, 56);
    final border = decoration?.enabledBorder as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(PtTheme.fieldRadius));
    expect(find.text('Workshop name'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Workshop name')).dy,
      lessThan(tester.getTopLeft(find.byType(TextFormField)).dy),
    );
    expect(tester.getSize(find.byType(TextFormField)).height, 56);
  });

  testWidgets('field keeps the inner hint empty when no distinct hint exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(width: 320, child: PlatformTextField(label: 'Email')),
      ),
    );

    final decoration = _innerDecoration(tester);
    expect(decoration?.labelText, isNull);
    // The label is rendered above; repeating it inside would duplicate the text.
    expect(decoration?.hintText, isNull);
  });

  testWidgets('label above still gives the field an accessible name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const SizedBox(width: 320, child: PlatformTextField(label: 'Email')),
      ),
    );
    expect(find.bySemanticsLabel('Email'), findsWidgets);
    handle.dispose();
  });

  testWidgets('dropdown puts the label above and keeps 16/56', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          child: PlatformDropdown<String>(
            label: 'Direction',
            value: 'ltr',
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'ltr', child: Text('LTR')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final field = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(field.decoration.labelText, isNull);
    expect(field.decoration.constraints?.minHeight, 56);
    final border = field.decoration.enabledBorder as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(PtTheme.fieldRadius));
    expect(find.text('Direction'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Direction')).dy,
      lessThan(
        tester.getTopLeft(find.byType(DropdownButtonFormField<String>)).dy,
      ),
    );
  });

  testWidgets('status chip is a 30-32px pill', (tester) async {
    await tester.pumpWidget(
      _app(
        const PlatformStatusChip(status: 'ACTIVE'),
        overrides: <Override>[
          statusToneTokenProvider('ACTIVE').overrideWith((ref) => 'success'),
        ],
      ),
    );

    final chip = find.descendant(
      of: find.byType(PlatformStatusChip),
      matching: find.byType(Container),
    );
    final container = tester.widget<Container>(chip.first);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(PtTheme.chipRadius));
    expect(tester.getSize(find.text('ACTIVE')).height, 14);
    // 14 line + 8/8 padding + 1/1 border = 32px chip (30–32 token band).
    expect(tester.getSize(chip.first).height, 32);
  });

  testWidgets('filter chip is a 30-32px pill inside a 44px target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 320,
          child: PlatformFilterChip(label: 'All', selected: true, onTap: _noop),
        ),
      ),
    );

    // 32px visual pill (16 line + 7/7 padding + 1/1 border) inside a 46px
    // touch target; both inside the 30–32 / 44+ bands.
    final animated = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = animated.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(PtTheme.chipRadius));
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 32);
    expect(tester.getSize(find.byType(InkWell)).height, 46);
  });
}

void _noop() {}
