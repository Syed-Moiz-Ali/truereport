import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:technician_app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Real web URLs (/jobs) instead of hash fragments (/#/jobs).
  usePathUrlStrategy();
  runApp(const ProviderScope(child: TechnicianApp()));
}
