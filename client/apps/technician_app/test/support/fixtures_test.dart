/// Guards the fixtures themselves.
///
/// Characterization tests are only as good as their inputs: if the template
/// silently loses items every downstream test keeps passing against a shorter
/// checklist.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('jobSummary describes the reference Land Cruiser', () {
    final job = jobSummary();

    expect(job.reference, 'TR-2026-0412');
    expect(job.vehicleMake, 'Toyota');
    expect(job.vehicleModel, 'Land Cruiser');
    expect(job.vehicleYear, 2023);
    expect(job.vehiclePlate, 'AUD-354626');
    expect(job.totalItems, 30);
  });

  test('checklist serves the full 30-item template', () {
    final served = checklist();

    expect(served.items, hasLength(30));
    expect(served.total, 30);
    expect(served.completed, 0);
    expect(served.items.first.sortOrder, 1);
    expect(served.items.last.sortOrder, 30);
  });

  test('item codes are unique and every item names a category', () {
    final served = checklist();
    final itemCodes = served.items.map((item) => item.itemCode).toList();
    final categoryCodes = served.categories
        .map((category) => category.code)
        .toSet();

    expect(itemCodes.toSet(), hasLength(itemCodes.length));
    for (final item in served.items) {
      expect(categoryCodes, contains(item.categoryCode));
      expect(item.labelEn, isNotEmpty);
      expect(item.labelAr, isNotEmpty);
    }
  });

  test('itemCount shortens the checklist for smaller scenarios', () {
    expect(checklist(itemCount: 3).items, hasLength(3));
    expect(checklist(itemCount: 3, completed: 2).completed, 2);
  });
}
