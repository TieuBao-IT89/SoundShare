import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/catalog_provider.dart';
import '../../home/domain/song.dart';
import '../domain/discovery.dart';

final searchProvider = FutureProvider.autoDispose
    .family<List<Song>, DiscoveryFilters>((ref, filters) async {
      var disposed = false;
      ref.onDispose(() => disposed = true);
      final repository = ref.watch(songRepositoryProvider);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (disposed) return [];
      return repository.search(filters);
    });
