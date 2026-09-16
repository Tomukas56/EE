import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';
import 'stations_provider.dart';

final offlineServiceProvider = Provider<OfflineService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return OfflineService(apiService);
});

final syncMetadataProvider = FutureProvider<List<SyncMetadata>>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  return await offlineService.getAllSyncMetadata();
});

/// Manual offline mode toggle (when user wants to force offline even with network).
final forceOfflineModeProvider = StateProvider<bool>((ref) => false);
