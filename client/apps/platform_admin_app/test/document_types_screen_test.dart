import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/documents/document_types_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

const _docType = ReportDocumentType(
  id: 'doc-1',
  code: 'INSPECTION',
  name: 'Inspection Report',
  status: 'ACTIVE',
  required: true,
  sortOrder: 1,
);

class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi()
    : super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

  Map<String, dynamic>? lastBody;

  @override
  Future<ReportDocumentType> createDocumentType(
    Map<String, dynamic> body,
  ) async {
    lastBody = body;
    return ReportDocumentType(
      id: 'doc-created',
      code: body['code'] as String? ?? '',
      name: body['name'] as String? ?? '',
      status: 'ACTIVE',
      required: body['required'] as bool? ?? false,
      sortOrder: body['sortOrder'] as int? ?? 0,
    );
  }
}

Widget _app(_FakeConfigApi api) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
      platformConfigApiProvider.overrideWithValue(api),
      documentTypesProvider.overrideWith((ref) async => const [_docType]),
    ],
    child: const MaterialApp(
      supportedLocales: <Locale>[Locale('en')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: Size(1280, 900)),
        child: DocumentTypesScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('document type form is English-only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(_FakeConfigApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add document type'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('doc-type-name')), findsOneWidget);
    expect(find.byKey(const Key('doc-type-name-ar')), findsNothing);
    expect(find.text('Label (Arabic)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document type create sends the plain source name', (
    tester,
  ) async {
    final api = _FakeConfigApi();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add document type'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('doc-type-code')), 'PHOTO');
    await tester.enterText(
      find.byKey(const Key('doc-type-name')),
      'Photo Report',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(api.lastBody, isNotNull);
    expect(api.lastBody!['name'], 'Photo Report');
    expect(api.lastBody!.containsKey('nameEn'), isFalse);
    expect(api.lastBody!.containsKey('nameAr'), isFalse);
  });
}
