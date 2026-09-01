import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _routeService = RouteService();
  PlannedRoute? _route;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
        _route = null;
      });
    }
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    hintText: 'e.g. Vilnius',
                    prefixIcon: Icon(Icons.my_location),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _endController,
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
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              width: double.infinity,
              child: _buildResult(context, route),
            ),
          ),
          if (route != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
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
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${route.distanceKm.toStringAsFixed(0)} km'
          '${route.usedGoogleDirections ? ' (Google Directions)' : ' (estimate)'}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(route.summary),
        if (route.chargingStop != null) ...[
          const SizedBox(height: 16),
          _StopCard(station: route.chargingStop!),
        ],
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
      child: ListTile(
        leading: const Icon(Icons.ev_station),
        title: Text(station.name),
        subtitle: Text(
          [
            station.address,
            if (station.maxPowerKw > 0)
              '${station.maxPowerKw.toStringAsFixed(0)} kW',
            ...station.connectorTypes,
          ].join(' · '),
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
