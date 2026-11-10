import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveReportPdf(List<int> bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/inspection-report.pdf');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
