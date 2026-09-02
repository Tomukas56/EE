import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/station.dart';
import '../../providers/stations_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/route_service.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final MapController _mapController = MapController();
  final _routeService = RouteService();
  PlannedRoute? _route;
  bool _loading = false;
  String? _error;
  bool _mapReady = false;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _mapController.dispose();
    super.dispose();
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

  void _fitRoute(PlannedRoute route) {
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
      final stations = await ref.read(stationsProvider.future);
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
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
                        : '${vehicle.label} · ${vehicle.maxRangeKm.toStringAsFixed(0)} km',
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
          Expanded(child: _buildResult(context, route)),
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

  Widget _buildResult(BuildContext context, PlannedRoute? route) {
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter start and destination',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'A map and a Navigate button will appear after the route is calculated. Navigate opens Google Maps driving directions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF3A3A3C), fontSize: 13, height: 1.35),
            ),
          ),
        ],
      );
    }

    final points = _pathPoints(route);
    final stop = route.chargingStop;
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: points.isEmpty
                  ? const LatLng(55.2, 24.0)
                  : points[points.length ~/ 2],
              initialZoom: 6.5,
              onMapReady: () {
                _mapReady = true;
                _fitRoute(route);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'lt.energyeniwhere.mobile',
                retinaMode: true,
              ),
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
                  TextSourceAttribution('© OpenStreetMap, © CARTO'),
                ],
              ),
            ],
          ),
        ),
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
