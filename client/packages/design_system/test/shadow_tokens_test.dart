import 'dart:convert';
import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compares every shared shadow token to the `effects` arrays in the Figma
/// export JSON. This is a unit test, not an image estimate: it reads the
/// exported node effects and compares offset, blur, spread, colour and alpha.
void main() {
  final root = _repoRoot();
  final technician = '${root.path}/docs/ui/figma-export/technision_figma';

  test('card shadow equals the Figma Delivery Status Card effects', () {
    final json = _readJson(
      '$technician/screens/16_16._Post-Finalization_Success/'
      '16._Post-Finalization_Success.json',
    );
    final node = _findByName(json, name: 'Delivery Status Card');
    final shadows = AppTheme.light.extension<AppShadowTokens>()!;
    _expectShadows(shadows.card, _effects(node, 'Delivery Status Card'));
  });

  test('subtle button shadow equals the Figma Sign In button effects', () {
    final json = _readJson(
      '$technician/screens/01_1._Login_&_Language_Selection/'
      '1._Login_&_Language_Selection.json',
    );
    final button = _findByName(json, name: 'Button', width: 342, height: 56);
    final shadow = _findByName(button, name: 'Button:shadow');
    _expectShadows(
      AppTheme.light.extension<AppShadowTokens>()!.buttonSubtle,
      _effects(shadow, 'Button:shadow'),
    );
  });

  test('CTA shadow equals the Figma SAVE button effects', () {
    final json = _readJson(
      '$technician/screens/09_9._Defect_Detail_&_Evidence/'
      '9._Defect_Detail_&_Evidence.json',
    );
    final save = _findByName(json, name: 'Chunky Solid Emerald Green SAVE Button');
    final button = _findByName(save, name: 'Button');
    _expectShadows(
      AppTheme.light.extension<AppShadowTokens>()!.button,
      _effects(button, 'SAVE Button'),
    );
  });

  test('floating shadow equals the Figma bottom nav effects', () {
    final json = _readJson(
      '$technician/screens/02_2._Assigned_Jobs_Dashboard/'
      '2._Assigned_Jobs_Dashboard.json',
    );
    final nav = _findByName(json, name: 'Nav', width: 350, height: 64);
    _expectShadows(
      AppTheme.light.extension<AppShadowTokens>()!.floating,
      _effects(nav, 'Nav'),
    );
  });

  test('selected result option shadow equals the Figma Minor option', () {
    final json = _readJson(
      '$technician/screens/09_9._Defect_Detail_&_Evidence/'
      '9._Defect_Detail_&_Evidence.json',
    );
    final option = _findByName(
      json,
      name:
          'Button - Minor Option (Active: Highlighted Pastel Orange with Dark Navy Text)',
    );
    _expectShadows(
      FigmaShadows.selectedOption,
      _effects(option, 'Minor option'),
    );
  });
}

Map<String, dynamic> _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('Figma export missing: $path');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _findByName(
  Object? node, {
  required String name,
  double? width,
  double? height,
}) {
  if (node is List<dynamic>) {
    for (final child in node) {
      final match = _findByName(
        child,
        name: name,
        width: width,
        height: height,
      );
      if (match.isNotEmpty) return match;
    }
    return const <String, dynamic>{};
  }
  if (node is! Map<String, dynamic>) return const <String, dynamic>{};
  final nodeName = node['name'];
  final nodeWidth = (node['width'] as num?)?.toDouble();
  final nodeHeight = (node['height'] as num?)?.toDouble();
  final matches = nodeName == name &&
      (width == null || nodeWidth == width) &&
      (height == null || nodeHeight == height);
  if (matches) return node;
  for (final key in const ['children', 'nodes']) {
    final children = node[key];
    if (children is! List<dynamic>) continue;
    for (final child in children) {
      final match = _findByName(
        child,
        name: name,
        width: width,
        height: height,
      );
      if (match.isNotEmpty) return match;
    }
  }
  return const <String, dynamic>{};
}

List<dynamic> _effects(Map<String, dynamic> node, String label) {
  final effects = node['effects'];
  if (effects is! List<dynamic>) {
    fail('Figma node "$label" has no effects array');
  }
  return effects;
}

void _expectShadows(List<BoxShadow> actual, List<dynamic> effects) {
  final dropShadows = effects
      .cast<Map<String, dynamic>>()
      .where(
        (effect) =>
            effect['type'] == 'DROP_SHADOW' && effect['visible'] != false,
      )
      .toList(growable: false);
  expect(actual.length, dropShadows.length, reason: 'shadow layer count');
  for (var index = 0; index < actual.length; index++) {
    final shadow = actual[index];
    final figma = dropShadows[index];
    final offset = figma['offset'] as Map<String, dynamic>;
    final color = figma['color'] as Map<String, dynamic>;
    final reason = 'layer $index';
    expect(shadow.offset.dx, closeTo((offset['x'] as num).toDouble(), 0.01), reason: '$reason x');
    expect(shadow.offset.dy, closeTo((offset['y'] as num).toDouble(), 0.01), reason: '$reason y');
    expect(shadow.blurRadius, closeTo((figma['radius'] as num).toDouble(), 0.01), reason: '$reason blur');
    expect(shadow.spreadRadius, closeTo((figma['spread'] as num).toDouble(), 0.01), reason: '$reason spread');
    final figmaAlpha = (color['a'] as num).toDouble();
    expect(shadow.color.a, closeTo(figmaAlpha, 1 / 255), reason: '$reason alpha');
    expect(shadow.color.r, closeTo((color['r'] as num).toDouble(), 1 / 255), reason: '$reason red');
    expect(shadow.color.g, closeTo((color['g'] as num).toDouble(), 1 / 255), reason: '$reason green');
    expect(shadow.color.b, closeTo((color['b'] as num).toDouble(), 1 / 255), reason: '$reason blue');
  }
}

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 12; i += 1) {
    if (Directory('${dir.path}/docs/ui/figma').existsSync() &&
        Directory('${dir.path}/client').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('Could not find repository root from ${Directory.current}');
}
