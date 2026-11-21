import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform_providers.dart';
import 'manual_translation_models.dart';

/// One page of canonical fields for the manual translations screen.
final manualTranslationsPageProvider = FutureProvider.autoDispose
    .family<ManualTranslationPage, ManualTranslationQuery>((ref, query) {
      return ref
          .watch(platformConfigApiProvider)
          .contentUnits(
            lang: query.lang,
            entityType: query.entityType,
            filter: query.filter,
            query: query.search,
            page: query.page,
            size: query.size,
          );
    });

/// Header totals for one language, read from the server's `total` (not the
/// current page). Two cheap `size=1` calls keep the definition explicit:
/// total canonical fields and fields without a translation.
final manualTranslationSummaryProvider = FutureProvider.autoDispose
    .family<ManualTranslationSummary, String>((ref, lang) async {
      final api = ref.watch(platformConfigApiProvider);
      final missing = await api.contentUnits(
        lang: lang,
        filter: ManualTranslationFilter.missing,
        page: 0,
        size: 1,
      );
      final all = await api.contentUnits(
        lang: lang,
        filter: ManualTranslationFilter.all,
        page: 0,
        size: 1,
      );
      return ManualTranslationSummary.fromPages(all: all, missing: missing);
    });
