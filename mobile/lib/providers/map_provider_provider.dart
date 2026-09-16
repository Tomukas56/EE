import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_provider.dart';

/// Selected map provider (persisted to SharedPreferences).
class MapProviderNotifier extends StateNotifier<MapProvider> {
  MapProviderNotifier() : super(MapProvider.openStreetMap) {
    _loadSavedProvider();
  }

  static const _key = 'map_provider';

  Future<void> _loadSavedProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_key);
      if (savedName != null) {
        final provider = MapProvider.values.firstWhere(
          (p) => p.name == savedName,
          orElse: () => MapProvider.openStreetMap,
        );
        state = provider;
      }
    } catch (_) {
      // Use default if load fails
    }
  }

  Future<void> setProvider(MapProvider provider) async {
    state = provider;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, provider.name);
    } catch (_) {
      // Continue even if save fails
    }
  }
}

final mapProviderProvider =
    StateNotifierProvider<MapProviderNotifier, MapProvider>((ref) {
  return MapProviderNotifier();
});
