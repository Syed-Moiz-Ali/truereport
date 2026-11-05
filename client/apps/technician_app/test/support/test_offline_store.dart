import 'package:drift/native.dart';
import 'package:technician_app/src/offline/offline_database.dart';
import 'package:technician_app/src/offline/offline_store.dart';

OfflineStore createTestOfflineStore() =>
    OfflineStore(OfflineDatabase(NativeDatabase.memory()));
