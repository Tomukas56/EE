import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../services/api_service.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Stations List Provider
final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getStations();
});

// Station Detail Provider (family provider for different IDs)
final stationDetailProvider = FutureProvider.family<StationDetail, String>((
  ref,
  id,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getStationDetail(id);
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Stations Provider
final filteredStationsProvider = Provider<AsyncValue<List<Station>>>((ref) {
  final stationsAsync = ref.watch(stationsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return stationsAsync.whenData((stations) {
    if (searchQuery.isEmpty) {
      return stations;
    }
    return stations.where((station) {
      return station.name.toLowerCase().contains(searchQuery) ||
          station.address.toLowerCase().contains(searchQuery) ||
          (station.operatorName?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  });
});
