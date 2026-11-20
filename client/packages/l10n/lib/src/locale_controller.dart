import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  /// English-only product: any requested locale is clamped to English.
  void setLocale(Locale locale) {
    state = const Locale('en');
  }

  void toggle() {
    state = const Locale('en');
  }
}
