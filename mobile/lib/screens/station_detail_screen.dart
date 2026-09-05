import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/station.dart';
import '../providers/auth_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/stations_provider.dart';
import '../widgets/arrival_check_sheet.dart';
import '../widgets/connector_badge.dart';

String _updatedLabel(DateTime synced) {
  final seconds = DateTime.now().difference(synced).inSeconds;
  if (seconds < 60) return '$seconds sec ago';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min ago';
  return '${minutes ~/ 60} h ago';
}

class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  Future<void> _launchNavigation(double? lat, double? lng) async {
    if (lat == null || lng == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null) return;

    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _reportArrival(
    BuildContext context,
    WidgetRef ref,
    StationDetail station,
  ) async {
    final result = await showArrivalCheckSheet(
      context,
      stationName: station.name,
    );
    if (result == null || !context.mounted) return;
    if (ref.read(sessionProvider)?.limitedAccess == true) return;
    final user = ref.read(sessionProvider);
    try {
      await ref.read(apiServiceProvider).sendCheckIn(
            stationId: station.id,
            working: result.workingApi,
            freeConnectors: result.freeConnectorsApi,
            reporterId: user?.id ?? user?.email,
            latitude: station.latitude,
            longitude: station.longitude,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks. Report saved.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $error')),
      );
    }
  }

  Future<void> _startCharge(
    BuildContext context,
    WidgetRef ref,
    StationDetail station,
  ) async {
    final user = ref.read(sessionProvider);
    if (user?.limitedAccess == true) return;
    try {
      await ref.read(apiServiceProvider).startSession(
            stationId: station.id,
            reporterId: labReporterId(user),
            connectorType: station.connectors.isNotEmpty
                ? station.connectors.first.type.name
                : null,
          );
      ref.invalidate(chargingHistoryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lab charging started. Stop to estimate kWh at €0.32/kWh.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start: $error')),
      );
    }
  }

  Future<void> _stopCharge(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    try {
      final session = await ref.read(apiServiceProvider).stopSession(sessionId);
      ref.invalidate(chargingHistoryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stopped: ${session.energyKwh.toStringAsFixed(1)} kWh · €${session.costEur.toStringAsFixed(2)} (lab estimate)',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not stop: $error')),
      );
    }
  }

  Future<void> _launchWebsite(String? website) async {
    if (website == null) return;

    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(stationDetailProvider(stationId));
    final openSession = ref.watch(openSessionProvider);
    final limited = ref.watch(sessionProvider)?.limitedAccess == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Station Details')),
      body: stationAsync.when(
        data: (station) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Station Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (station.operatorName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          station.operatorName!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      if (station.hasLiveOccupancy) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${station.availableConnectors} available · ${station.connectorCount} connectors'
                          '${station.tariff != null ? ' · ${station.tariff}' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (station.lastSyncedAt != null)
                          Text(
                            'Updated ${_updatedLabel(station.lastSyncedAt!)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                // Contact Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: station.address,
                      ),

                      // Opening Hours
                      if (station.openingHours != null)
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Opening Hours',
                          value: station.openingHours!,
                        ),

                      // Phone
                      if (station.phone != null)
                        _InfoRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: station.phone!,
                          onTap: () => _launchPhone(station.phone),
                        ),

                      // Website
                      if (station.website != null)
                        _InfoRow(
                          icon: Icons.language,
                          label: 'Website',
                          value: station.website!,
                          onTap: () => _launchWebsite(station.website),
                        ),

                      if (station.source == 'via_lietuva')
                        _InfoRow(
                          icon: Icons.verified,
                          label: 'Catalogue',
                          value:
                              'Via Lietuva open data (CC BY 4.0). Occupancy and price as last published.',
                          onTap: () => _launchWebsite(
                            'https://ev.vialietuva.lt/atviri-duomenys-1',
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(),

                // Connectors Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Connectors',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (station.connectors.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No connectors available'),
                          ),
                        )
                      else
                        ...station.connectors.map(
                          (connector) => ConnectorBadge(connector: connector),
                        ),
                      const SizedBox(height: 20),
                      if (limited)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Skip mode: charging and arrival reports are locked. '
                            'Sign out and accept the Terms to use them.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else ...[
                      if (openSession != null &&
                          openSession.stationId != station.id)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'A session is already open at ${openSession.stationName}. Stop it first.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (openSession != null &&
                          openSession.stationId == station.id)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _stopCharge(context, ref, openSession.id),
                            icon: const Icon(Icons.stop_circle),
                            label: const Text('Stop charging (lab)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: openSession != null
                                ? null
                                : () => _startCharge(context, ref, station),
                            icon: const Icon(Icons.bolt),
                            label: const Text('Start charging (lab)'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _reportArrival(context, ref, station),
                          icon: const Icon(Icons.flag_circle),
                          label: const Text("I've arrived — confirm status"),
                        ),
                      ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load station details'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(stationDetailProvider(stationId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),

      // Navigate Button
      floatingActionButton: stationAsync.when(
        data: (station) {
          return FloatingActionButton.extended(
            onPressed: () =>
                _launchNavigation(station.latitude, station.longitude),
            icon: const Icon(Icons.directions),
            label: const Text('Navigate'),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          ],
        ),
      ),
    );
  }
}
