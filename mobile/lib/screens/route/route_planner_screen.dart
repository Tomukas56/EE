import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config.dart';
import '../../core/theme.dart';
import '../../models/station.dart';
import '../../providers/stations_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/location_service.dart';
import '../../services/route_service.dart';
import '../../utils/geo.dart';
import '../../widgets/map_tile_layer.dart';
import '../../providers/map_provider_provider.dart';
import '../../models/map_provider.dart' as mp;

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final MapController _mapController = MapController();
  gmaps.GoogleMapController? _googleMap;
  final _routeService = RouteService();
  PlannedRoute? _route;
  bool _loading = false;
  String? _error;
  bool _mapReady = false;
  DevicePosition? _myLocation;

  bool _useGoogleMap(mp.MapProvider selectedProvider) {
    return selectedProvider == mp.MapProvider.googleMaps &&
        AppConfig.googleMapsApiKey.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
    // Pre-fill destination if coming from map with selected station
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final destination = ref.read(destinationStationProvider);
      if (destination != null && mounted) {
        _endController.text = destination.name;
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMyLocation() async {
    try {
      final pos = await LocationService().getCurrentPosition();
      if (mounted) {
        setState(() => _myLocation = pos);
      }
    } catch (_) {
      // Location not available - show default center
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  List<LatLng> _pathPoints(PlannedRoute route) {
    return [
      for (final point in route.path) LatLng(point.lat, point.lng),
    ];
  }

  List<gmaps.LatLng> _googlePath(PlannedRoute route) {
    return [
      for (final point in route.path) gmaps.LatLng(point.lat, point.lng),
    ];
  }

  void _fitRoute(PlannedRoute route) {
    final selectedProvider = ref.read(mapProviderProvider);
    if (_useGoogleMap(selectedProvider)) {
      final points = _googlePath(route);
      final controller = _googleMap;
      if (points.isEmpty || controller == null) return;
      try {
        if (points.length == 1) {
          controller.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(points.first, 10),
          );
          return;
        }
        var minLat = points.first.latitude;
        var maxLat = points.first.latitude;
        var minLng = points.first.longitude;
        var maxLng = points.first.longitude;
        for (final point in points) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }
        if (maxLat - minLat < 0.02) {
          minLat -= 0.05;
          maxLat += 0.05;
        }
        if (maxLng - minLng < 0.02) {
          minLng -= 0.05;
          maxLng += 0.05;
        }
        controller.animateCamera(
          gmaps.CameraUpdate.newLatLngBounds(
            gmaps.LatLngBounds(
              southwest: gmaps.LatLng(minLat, minLng),
              northeast: gmaps.LatLng(maxLat, maxLng),
            ),
            48,
          ),
        );
      } catch (_) {}
      return;
    }
    final points = _pathPoints(route);
    if (points.isEmpty || !_mapReady) return;
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(40),
          maxZoom: 12,
        ),
      );
    } catch (_) {}
  }

  Future<void> _calculateRoute() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var stations = <Station>[];
      try {
        stations = await ref.read(stationsProvider.future);
      } catch (_) {
        // Route still works without the catalog; charging stop is skipped.
      }
      final vehicle = ref.read(vehicleProvider);
      final route = await _routeService.plan(
        origin: _startController.text,
        destination: _endController.text,
        stations: stations,
        vehicle: vehicle,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitRoute(route);
      });
    } catch (error) {
      debugPrint('Trip planner failed: $error');
      if (!mounted) return;
      final message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _loading = false;
        _error = message;
        _route = null;
      });
    }
  }

  Future<void> _openNavigate(PlannedRoute route) async {
    final origin = '${route.origin.lat},${route.origin.lng}';
    final destination = '${route.destination.lat},${route.destination.lng}';
    final stop = route.chargingStop;
    final waypoint = stop != null &&
            stop.latitude != null &&
            stop.longitude != null
        ? '${stop.latitude},${stop.longitude}'
        : null;
    final url = Uri.parse(
      waypoint == null
          ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving'
          : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoint&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleProvider);
    final route = _route;
    final selectedProvider = ref.watch(mapProviderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Planner')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  textInputAction: TextInputAction.next,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    hintText: 'e.g. Vilnius',
                    prefixIcon: Icon(Icons.my_location),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _endController,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  onSubmitted: (_) => _calculateRoute(),
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g. Riga',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    vehicle == null
                        ? 'No vehicle saved — using 300 km default range'
                        : 'Active vehicle: ${vehicle.label} · ${vehicle.specsLine}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _calculateRoute,
                    child: Text(_loading ? 'Calculating…' : 'Find Charging Route'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResult(context, route, selectedProvider)),
          if (route != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _openNavigate(route),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TripStat(
                        icon: Icons.timer,
                        value: _formatDuration(route.duration),
                        label: 'Duration',
                      ),
                      _TripStat(
                        icon: Icons.ev_station,
                        value: route.chargingStop == null ? '0 stops' : '1 stop',
                        label: 'Charging',
                      ),
                      _TripStat(
                        icon: Icons.bolt,
                        value: '${route.energyKwh.toStringAsFixed(0)} kWh',
                        label: 'Energy',
                      ),
                      _TripStat(
                        icon: Icons.euro,
                        value: '€${route.estimatedCostEur.toStringAsFixed(2)}',
                        label: 'Est. Cost',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, PlannedRoute? route, mp.MapProvider selectedProvider) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (route == null) {
      return _buildEmptyMap(selectedProvider);
    }

    final points = _pathPoints(route);
    final stop = route.chargingStop;
    return Column(
      children: [
        Expanded(child: _buildRouteMap(route, points, stop, selectedProvider)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${route.distanceKm.toStringAsFixed(0)} km'
                '${route.usedGoogleDirections ? ' (Google Directions)' : ' (estimate)'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(route.summary),
              if (stop != null) ...[
                const SizedBox(height: 8),
                _StopCard(station: stop),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMap(mp.MapProvider selectedProvider) {
    final myLat = _myLocation?.latitude ?? vilniusLat;
    final myLng = _myLocation?.longitude ?? vilniusLng;
    final hasLocation = _myLocation != null;

    if (_useGoogleMap(selectedProvider)) {
      return gmaps.GoogleMap(
        key: const ValueKey('ee-trip-empty-google-map'),
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(myLat, myLng),
          zoom: hasLocation ? 12.0 : 6.5,
        ),
        markers: hasLocation
            ? {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('me'),
                  position: gmaps.LatLng(myLat, myLng),
                  infoWindow: const gmaps.InfoWindow(title: 'You are here'),
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueCyan,
                  ),
                ),
              }
            : const <gmaps.Marker>{},
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(myLat, myLng),
        initialZoom: hasLocation ? 12.0 : 6.5,
        onMapReady: () => _mapReady = true,
      ),
      children: [
        MapTileLayer(provider: selectedProvider),
        if (hasLocation)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(myLat, myLng),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF00C48C),
                  size: 32,
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('© OpenStreetMap'),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteMap(
    PlannedRoute route,
    List<LatLng> points,
    Station? stop,
    mp.MapProvider selectedProvider,
  ) {
    final mid = points.isEmpty
        ? const LatLng(55.2, 24.0)
        : points[points.length ~/ 2];
    if (_useGoogleMap(selectedProvider)) {
      final gPath = _googlePath(route);
      final markers = <gmaps.Marker>{
        gmaps.Marker(
          markerId: const gmaps.MarkerId('origin'),
          position: gmaps.LatLng(route.origin.lat, route.origin.lng),
          infoWindow: const gmaps.InfoWindow(title: 'Start'),
        ),
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: gmaps.LatLng(route.destination.lat, route.destination.lng),
          infoWindow: const gmaps.InfoWindow(title: 'Destination'),
        ),
        if (stop != null && stop.latitude != null && stop.longitude != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('stop'),
            position: gmaps.LatLng(stop.latitude!, stop.longitude!),
            infoWindow: gmaps.InfoWindow(title: stop.name),
          ),
      };
      return gmaps.GoogleMap(
        key: const ValueKey('ee-trip-google-map'),
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(mid.latitude, mid.longitude),
          zoom: 6.5,
        ),
        polylines: gPath.length >= 2
            ? {
                gmaps.Polyline(
                  polylineId: const gmaps.PolylineId('route'),
                  points: gPath,
                  color: const Color(0xFF0066FF),
                  width: 5,
                ),
              }
            : const <gmaps.Polyline>{},
        markers: markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _googleMap = controller;
          _fitRoute(route);
        },
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mid,
        initialZoom: 6.5,
        onMapReady: () {
          _mapReady = true;
          _fitRoute(route);
        },
      ),
      children: [
        MapTileLayer(provider: selectedProvider),
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: const Color(0xFF0066FF),
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(route.origin.lat, route.origin.lng),
              width: 40,
              height: 40,
              child: const Icon(Icons.trip_origin, color: Color(0xFF00C48C)),
            ),
            if (stop != null &&
                stop.latitude != null &&
                stop.longitude != null)
              Marker(
                point: LatLng(stop.latitude!, stop.longitude!),
                width: 40,
                height: 40,
                child: const Icon(Icons.ev_station, color: Color(0xFFFF6B35)),
              ),
            Marker(
              point: LatLng(route.destination.lat, route.destination.lng),
              width: 40,
              height: 40,
              child: const Icon(Icons.flag, color: Color(0xFF0066FF)),
            ),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('© OpenStreetMap'),
          ],
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final Station station;

  const _StopCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.ev_station),
        title: Text(station.name),
        subtitle: Text(
          [
            station.address,
            if (station.maxPowerKw > 0)
              '${station.maxPowerKw.toStringAsFixed(0)} kW',
            ...station.connectorTypes,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => context.pushNamed(
          'station-detail',
          pathParameters: {'id': station.id},
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TripStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
