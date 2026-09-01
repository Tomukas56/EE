import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/station.dart';
import '../providers/auth_provider.dart';
import '../providers/stations_provider.dart';
import '../services/location_service.dart';
import '../utils/geo.dart';
import '../widgets/arrival_check_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool focusNearest;

  const MapScreen({super.key, this.focusNearest = false});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  gmaps.GoogleMapController? _googleMap;
  final Set<gmaps.Marker> _markers = {};
  List<Station> _pins = const [];
  bool _didFocusNearest = false;
  double _zoom = 7.2;
  DevicePosition? _me;
  final Set<String> _promptedArrival = {};

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Station> _mappable(List<Station> stations) =>
      stations.where(hasCoordinates).toList();

  Future<void> _moveCamera(double lat, double lng, double zoom) async {
    _zoom = zoom;
    if (AppConfig.useGoogleMaps) {
      await _googleMap?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), zoom),
      );
    } else {
      _mapController.move(LatLng(lat, lng), zoom);
    }
  }

  void _selectStation(Station station, {bool moveCamera = true}) {
    ref.read(destinationStationProvider.notifier).state = station;
    if (moveCamera) {
      _moveCamera(station.latitude!, station.longitude!, max(_zoom, 13));
    }
    if (AppConfig.useGoogleMaps) {
      _refreshGoogleMarkers(_pins);
    }
  }

  void _selectNearestTo(double lat, double lng, List<Station> stations) {
    final station = nearestStation(stations, lat, lng);
    if (station == null) return;
    final km = distanceKm(lat, lng, station.latitude!, station.longitude!);
    final maxKm = (40 / pow(2, _zoom - 6)).clamp(0.2, 45);
    if (km > maxKm) return;
    _selectStation(station, moveCamera: false);
  }

  Future<void> _goToMyLocation({bool thenNearest = false}) async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      setState(() => _me = position);
      await _moveCamera(position.latitude, position.longitude, 13);

      if (thenNearest) {
        final stations = _mappable(await ref.read(stationsProvider.future));
        final station = nearestStation(stations, position.latitude, position.longitude);
        if (station != null) _selectStation(station);
      }
      _maybePromptArrival(ref.read(destinationStationProvider));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $error')),
      );
    }
  }

  void _applySearch(List<Station> stations) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return;
    final match = stations.where(hasCoordinates).where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q) ||
          (s.operatorName?.toLowerCase().contains(q) ?? false);
    }).firstOrNull;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No station matched that search')),
      );
      return;
    }
    _selectStation(match);
  }

  Future<void> _openDirections(Station station) async {
    final dest = '${station.latitude},${station.longitude}';
    final origin = _me != null ? '${_me!.latitude},${_me!.longitude}' : null;
    final url = Uri.parse(
      origin == null
          ? 'https://www.google.com/maps/dir/?api=1&destination=$dest'
          : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _maybePromptArrival(Station? destination) {
    if (destination == null || _me == null || !hasCoordinates(destination)) {
      return;
    }
    if (_promptedArrival.contains(destination.id)) return;
    final km = distanceKm(
      _me!.latitude,
      _me!.longitude,
      destination.latitude!,
      destination.longitude!,
    );
    if (km > 0.12) return;
    _promptedArrival.add(destination.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportArrival(destination);
    });
  }

  Future<void> _reportArrival(Station station) async {
    final result = await showArrivalCheckSheet(
      context,
      stationName: station.name,
    );
    if (result == null || !mounted) return;
    final user = ref.read(sessionProvider);
    try {
      await ref.read(apiServiceProvider).sendCheckIn(
            stationId: station.id,
            working: result.workingApi,
            freeConnectors: result.freeConnectorsApi,
            reporterId: user?.id ?? user?.email,
            latitude: _me?.latitude,
            longitude: _me?.longitude,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks. Report saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $error')),
      );
    }
  }

  Future<void> _refreshGoogleMarkers(List<Station> pins) async {
    _pins = pins;
    gmaps.LatLngBounds? bounds;
    try {
      bounds = await _googleMap?.getVisibleRegion();
    } catch (_) {}

    final selected = ref.read(destinationStationProvider);
    var visible = pins;
    if (bounds != null) {
      visible = pins.where((station) {
        return bounds!.contains(
          gmaps.LatLng(station.latitude!, station.longitude!),
        );
      }).toList();
    }
    if (visible.length > 220) {
      final step = visible.length / 220;
      visible = [
        for (var i = 0; i < 220; i++) visible[(i * step).floor()],
      ];
    }
    if (selected != null &&
        hasCoordinates(selected) &&
        !visible.any((station) => station.id == selected.id)) {
      visible = [...visible, selected];
    }
    if (!mounted) return;
    final next = <gmaps.Marker>{
      for (final station in visible)
        gmaps.Marker(
          markerId: gmaps.MarkerId(station.id),
          position: gmaps.LatLng(station.latitude!, station.longitude!),
          infoWindow: gmaps.InfoWindow(
            title: station.name,
            snippet: station.address,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            selected?.id == station.id
                ? gmaps.BitmapDescriptor.hueOrange
                : gmaps.BitmapDescriptor.hueAzure,
          ),
          onTap: () => _selectStation(station, moveCamera: false),
        ),
    };
    final sameIds = next.length == _markers.length &&
        next.every((marker) => _markers.any((m) => m.markerId == marker.markerId && m.icon == marker.icon));
    if (sameIds) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(next);
    });
  }

  Widget _buildBasemap(List<Station> pins) {
    if (AppConfig.useGoogleMaps) {
      return gmaps.GoogleMap(
        initialCameraPosition: const gmaps.CameraPosition(
          target: gmaps.LatLng(vilniusLat, vilniusLng),
          zoom: 7.2,
        ),
        markers: Set<gmaps.Marker>.of(_markers),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _googleMap = controller;
          _refreshGoogleMarkers(pins);
        },
        onTap: (latLng) => _selectNearestTo(
          latLng.latitude,
          latLng.longitude,
          pins,
        ),
        onCameraMove: (position) => _zoom = position.zoom,
        onCameraIdle: () => _refreshGoogleMarkers(pins),
      );
    }

    final destination = ref.watch(destinationStationProvider);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(vilniusLat, vilniusLng),
        initialZoom: 7.2,
        onPositionChanged: (camera, _) {
          _zoom = camera.zoom;
        },
        onTap: (tap, latlng) => _selectNearestTo(
          latlng.latitude,
          latlng.longitude,
          pins,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          userAgentPackageName: 'lt.energyeniwhere.mobile',
          retinaMode: true,
        ),
        CircleLayer(
          circles: [
            for (final station in pins)
              CircleMarker(
                point: LatLng(station.latitude!, station.longitude!),
                radius: destination?.id == station.id ? 10 : 5,
                color: destination?.id == station.id
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF0066FF).withValues(alpha: 0.85),
                borderStrokeWidth: destination?.id == station.id ? 3 : 1,
                borderColor: Colors.white,
              ),
          ],
        ),
        if (_me != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_me!.latitude, _me!.longitude),
                width: 24,
                height: 24,
                child: const Icon(Icons.my_location, color: Color(0xFF00C48C)),
              ),
            ],
          ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('© OpenStreetMap, © CARTO'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final destination = ref.watch(destinationStationProvider);

    if (widget.focusNearest && !_didFocusNearest && stationsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_didFocusNearest || !mounted) return;
        _didFocusNearest = true;
        _goToMyLocation(thenNearest: true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a station'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.pushNamed('list'),
            tooltip: 'List View',
          ),
        ],
      ),
      body: stationsAsync.when(
        data: (stations) {
          final pins = _mappable(stations);
          return Stack(
            children: [
              _buildBasemap(pins),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 16,
                    ),
                    cursorColor: const Color(0xFF0066FF),
                    decoration: InputDecoration(
                      hintText: 'Search station or address…',
                      hintStyle: const TextStyle(color: Color(0xFF3A3A3C)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF111111),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF111111),
                        ),
                        onPressed: () => _applySearch(pins),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _applySearch(pins),
                  ),
                ),
              ),
              if (destination != null)
                _DestinationCard(
                  station: destination,
                  distanceKm: _me == null
                      ? null
                      : distanceKm(
                          _me!.latitude,
                          _me!.longitude,
                          destination.latitude!,
                          destination.longitude!,
                        ),
                  onClear: () =>
                      ref.read(destinationStationProvider.notifier).state = null,
                  onDetails: () => context.pushNamed(
                    'station-detail',
                    pathParameters: {'id': destination.id},
                  ),
                  onNavigate: () => _openDirections(destination),
                  onArrived: () => _reportArrival(destination),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(stationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: destination == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'nearest',
                  backgroundColor: const Color(0xFF00C48C),
                  onPressed: () => _goToMyLocation(thenNearest: true),
                  tooltip: 'Nearest station',
                  child: const Icon(Icons.near_me),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'me',
                  onPressed: () => _goToMyLocation(),
                  tooltip: 'My location',
                  child: const Icon(Icons.my_location),
                ),
              ],
            )
          : null,
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final Station station;
  final double? distanceKm;
  final VoidCallback onClear;
  final VoidCallback onDetails;
  final VoidCallback onNavigate;
  final VoidCallback onArrived;

  const _DestinationCard({
    required this.station,
    required this.distanceKm,
    required this.onClear,
    required this.onDetails,
    required this.onNavigate,
    required this.onArrived,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: DefaultTextStyle(
            style: const TextStyle(color: Color(0xFF111111), fontSize: 14),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 8),
                  const Text(
                    'Destination',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, color: Color(0xFF111111)),
                  ),
                ],
              ),
              Text(
                station.name,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(station.address),
              if (station.operatorName != null)
                Text(
                  station.operatorName!,
                  style: const TextStyle(color: Color(0xFF3A3A3C)),
                ),
              if (distanceKm != null) ...[
                const SizedBox(height: 4),
                Text('${distanceKm!.toStringAsFixed(1)} km from your location'),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111111),
                        side: const BorderSide(color: Color(0xFF111111)),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.directions),
                      label: const Text('Go'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onArrived,
                  icon: const Icon(Icons.flag_circle),
                  label: const Text("I've arrived — confirm status"),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
