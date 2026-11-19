import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

final allTechnicianConflictsProvider =
    FutureProvider.autoDispose<List<SyncConflictRecord>>((ref) {
      return ref.watch(offlineStoreProvider).openConflicts();
    });
