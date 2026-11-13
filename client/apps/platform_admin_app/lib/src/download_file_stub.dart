import 'dart:io';

void downloadBytes(String filename, List<int> bytes) {
  File(filename).writeAsBytesSync(bytes);
}
