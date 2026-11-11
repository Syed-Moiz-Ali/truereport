import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/catalogues/data_catalogues_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

const _reason = PlatformCatalogueEntry(
  id: 'reason-1',
  code: 'NOT_ACCESSIBLE',
  status: 'ACTIVE',
  sortOrder: 1,
  labelEn: 'Not accessible',
  labelAr: 'غير متاح',
  values: [],
);

const _dropdown = PlatformCatalogueEntry(
  id: 'dropdown-1',
  code: 'SEVERITY',
  status: 'ACTIVE',
  sortOrder: 1,
  labelEn: 'Severity',
  labelAr: 'الخطورة',
  values: [
    PlatformCatalogueValue(
      id: 'value-1',
      code: 'MINOR',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Minor',
      labelAr: 'طفيف',
    ),
  ],
);

Widget _app({Locale locale = const Locale('en'), double width = 1280}) {
  return ProviderScope(
    overrides: [
      reasonsProvider.overrideWith((ref) async => const [_reason]),
      dropdownsProvider.overrideWith((ref) async => const [_dropdown]),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const DataCataloguesScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders catalogues from API providers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('Not accessible'), findsWidgets);
  });

  testWidgets('renders on compact width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(_app(width: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
