import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/remote_devotional_catalog.dart';
import '../../services/backend_service.dart';

/// Server-published aartis + deities, starting from disk cache then refreshing.
class RemoteCatalogNotifier extends StateNotifier<RemoteDevotionalCatalog> {
  RemoteCatalogNotifier() : super(BackendService.remoteCatalog) {
    refresh();
  }

  Future<void> refresh() async {
    await BackendService.loadCachedRemoteCatalog();
    if (mounted) state = BackendService.remoteCatalog;
    final fresh = await BackendService.fetchRemoteCatalog();
    if (mounted) state = fresh;
  }
}

final remoteCatalogProvider =
    StateNotifierProvider<RemoteCatalogNotifier, RemoteDevotionalCatalog>(
  (ref) => RemoteCatalogNotifier(),
);
