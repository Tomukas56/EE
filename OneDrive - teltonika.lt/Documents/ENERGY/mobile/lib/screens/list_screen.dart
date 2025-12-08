import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/stations_provider.dart';
import '../widgets/station_card.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredStationsAsync = ref.watch(filteredStationsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.goNamed('map'),
            tooltip: 'Map View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Stations List
          Expanded(
            child: filteredStationsAsync.when(
              data: (stations) {
                if (stations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.ev_station_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No stations found'
                              : 'No charging stations available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                            child: const Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(stationsProvider);
                  },
                  child: ListView.builder(
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      return StationCard(station: stations[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load stations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(stationsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
