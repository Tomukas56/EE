import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/map_provider.dart';
import '../../providers/map_provider_provider.dart';

class MapSettingsScreen extends ConsumerWidget {
  const MapSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProvider = ref.watch(mapProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose your preferred map provider',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The app will use this provider for all maps. You can change this anytime from Account → Map Settings.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF3A3A3C),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ...MapProvider.values.map((provider) {
            final isSelected = selectedProvider == provider;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              color: isSelected
                  ? const Color(0xFFE3F2FF)
                  : const Color(0xFFF8F9FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0066FF)
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  provider == MapProvider.googleMaps
                      ? Icons.map
                      : provider == MapProvider.mapbox
                          ? Icons.layers
                          : provider == MapProvider.mapTiler
                              ? Icons.terrain
                              : Icons.public,
                  size: 32,
                  color: isSelected
                      ? const Color(0xFF0066FF)
                      : const Color(0xFF3A3A3C),
                ),
                title: Text(
                  provider.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF0066FF)
                        : Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      provider.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (provider.requiresApiKey) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Requires API key',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF9500),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF0066FF),
                      )
                    : null,
                onTap: () async {
                  await ref
                      .read(mapProviderProvider.notifier)
                      .setProvider(provider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Map provider set to ${provider.label}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFB800).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Color(0xFFFF9500),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'About map providers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Google Maps: Best quality, requires Google API key\n'
                  '• OpenStreetMap: Free, community-driven, works offline\n'
                  '• Mapbox: Modern design, requires free Mapbox account\n'
                  '• MapTiler: OSM-based with custom styling options',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
