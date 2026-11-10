import 'dart:convert';

import 'package:web/web.dart' as web;

Future<String> saveReportPdf(List<int> bytes) async {
  final anchor = web.HTMLAnchorElement()
    ..href = 'data:application/pdf;base64,${base64Encode(bytes)}'
    ..download = 'inspection-report.pdf';
  anchor.click();
  return 'inspection-report.pdf';
}