import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';

void main() {
  test('evidence duration fields round-trip and tolerate absence', () {
    final rule = EvidenceRule.fromJson(<String, dynamic>{
      'resultCode': 'DEFECT_FOUND',
      'minDurationSeconds': 5,
      'maxDurationSeconds': 30,
    });
    expect(rule.minDurationSeconds, 5);
    expect(rule.maxDurationSeconds, 30);
    expect(rule.toJson()['minDurationSeconds'], 5);
    expect(rule.toJson()['maxDurationSeconds'], 30);

    final legacy = EvidenceRule.fromJson(<String, dynamic>{
      'resultCode': 'NO_ISSUE_OBSERVED',
    });
    expect(legacy.minDurationSeconds, isNull);
    expect(legacy.maxDurationSeconds, isNull);
    expect(legacy.toJson()['minDurationSeconds'], isNull);
  });

  test('duration parsing accepts only positive whole seconds', () {
    expect(evidenceDurationSeconds(''), isNull);
    expect(evidenceDurationSeconds('   '), isNull);
    expect(evidenceDurationSeconds('0'), isNull);
    expect(evidenceDurationSeconds('-2'), isNull);
    expect(evidenceDurationSeconds('abc'), isNull);
    expect(evidenceDurationSeconds('1.5'), isNull);
    expect(evidenceDurationSeconds('15'), 15);
  });

  test('duration validation enforces optional min < max', () {
    expect(evidenceDurationsInvalid('', ''), isFalse);
    expect(evidenceDurationsInvalid('5', ''), isFalse);
    expect(evidenceDurationsInvalid('', '30'), isFalse);
    expect(evidenceDurationsInvalid('5', '30'), isFalse);

    expect(evidenceDurationsInvalid('30', '5'), isTrue);
    expect(evidenceDurationsInvalid('5', '5'), isTrue);
    expect(evidenceDurationsInvalid('0', ''), isTrue);
    expect(evidenceDurationsInvalid('', '0'), isTrue);
    expect(evidenceDurationsInvalid('5', 'abc'), isTrue);
  });
}
