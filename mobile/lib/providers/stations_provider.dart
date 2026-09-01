import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/geo.dart';


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

final countryFilterProvider = StateProvider<String>((ref) => 'ALL');

const connectorFilters = <({String code, String label})>[
  (code: 'ALL', label: 'All plugs'),
  (code: 'CCS', label: 'CCS'),
  (code: 'TYPE2', label: 'Type 2'),
  (code: 'CHAdeMO', label: 'CHAdeMO'),
  (code: 'TYPE1', label: 'Type 1'),
];

const powerFilters = <({double kw, String label})>[
  (kw: 0, label: 'Any kW'),
  (kw: 22, label: '22+ kW'),
  (kw: 50, label: '50+ kW'),
  (kw: 150, label: '150+ kW'),
];

final connectorFilterProvider = StateProvider<String>((ref) => 'ALL');
final minPowerKwProvider = StateProvider<double>((ref) => 0);

bool matchesConnectorFilter(Station station, String type) {
  if (type == 'ALL') return true;
  if (station.connectorTypes.isEmpty) return false;
  return station.connectorTypes.contains(type);
}

bool matchesPowerFilter(Station station, double minKw) {
  if (minKw <= 0) return true;
  return station.maxPowerKw >= minKw;
}

// Filtered Stations Provider
final filteredStationsProvider = Provider<AsyncValue<List<Station>>>((ref) {
  final stationsAsync = ref.watch(stationsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final country = ref.watch(countryFilterProvider);
  final connector = ref.watch(connectorFilterProvider);
  final minKw = ref.watch(minPowerKwProvider);

  return stationsAsync.whenData((stations) {
    return stations.where((station) {
      if (!matchesCountryFilter(station, country)) return false;
      if (!matchesConnectorFilter(station, connector)) return false;
      if (!matchesPowerFilter(station, minKw)) return false;
      if (searchQuery.isEmpty) return true;
      return station.name.toLowerCase().contains(searchQuery) ||
          station.address.toLowerCase().contains(searchQuery) ||
          (station.operatorName?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  });
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final devicePositionProvider = FutureProvider<DevicePosition>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentPosition();
});

final nearestStationProvider = Provider<AsyncValue<({Station station, double km})?>>((ref) {
  final stationsAsync = ref.watch(stationsProvider);
  final positionAsync = ref.watch(devicePositionProvider);

  if (positionAsync.isLoading || stationsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  final positionError = positionAsync.error;
  if (positionError != null) {
    return AsyncValue.error(positionError, positionAsync.stackTrace ?? StackTrace.empty);
  }
  final stationsError = stationsAsync.error;
  if (stationsError != null) {
    return AsyncValue.error(stationsError, stationsAsync.stackTrace ?? StackTrace.empty);
  }

  final position = positionAsync.value;
  final stations = stationsAsync.value;
  if (position == null || stations == null) {
    return const AsyncValue.data(null);
  }

  final station = nearestStation(stations, position.latitude, position.longitude);
  if (station == null) return const AsyncValue.data(null);

  final km = distanceKm(
    position.latitude,
    position.longitude,
    station.latitude!,
    station.longitude!,
  );
  return AsyncValue.data((station: station, km: km));
});

/// Station chosen as the drive-to destination (navigation-style pin).
final destinationStationProvider = StateProvider<Station?>((ref) => null);
