import 'package:workshop_admin_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/web_url_strategy_stub.dart'
    if (dart.library.html) 'src/web_url_strategy_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();
  runApp(const ProviderScope(child: AdminApp()));
}
