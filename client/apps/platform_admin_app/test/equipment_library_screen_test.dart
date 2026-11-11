import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/equipment/equipment_library_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

const _equipment = PlatformCatalogueEntry(
  id: 'equipment-1',
  code: 'OBD2_SCANNER',
  status: 'ACTIVE',
  sortOrder: 1,
  labelEn: 'OBD2 Scanner',
  labelAr: 'ماسح OBD2',
  values: [],
);

Widget _app({Locale locale = const Locale('en'), double width = 1280}) {
  return ProviderScope(
    overrides: [
      equipmentProvider.overrideWith((ref) async => const [_equipment]),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const EquipmentLibraryScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders equipment from API provider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('OBD2 Scanner'), findsWidgets);
  });

  testWidgets('renders on compact width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(_app(width: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
