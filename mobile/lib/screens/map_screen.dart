import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/stations_provider.dart';

// TODO: Add Google Maps integration
// For now, displays a simple list view as placeholder
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Stations Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.goNamed('list'),
            tooltip: 'List View',
          ),
        ],
      ),
      body: stationsAsync.when(
        data: (stations) {
          return Column(
            children: [
              // TODO: Replace with Google Maps
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Map View',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Google Maps is available in main.dart',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),

              // Stations Quick List
              Expanded(
                child: ListView.builder(
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: station.availableConnectors > 0
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          '${station.availableConnectors}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(station.name),
                      subtitle: Text(station.address),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.pushNamed(
                          'station-detail',
                          pathParameters: {'id': station.id},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load stations'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(stationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
