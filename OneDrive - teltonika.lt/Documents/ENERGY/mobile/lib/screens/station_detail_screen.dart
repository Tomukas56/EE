import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/stations_provider.dart';
import '../widgets/connector_badge.dart';

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
            Icon(icon, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              Icon(Icons.open_in_new, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
