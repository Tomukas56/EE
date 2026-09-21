import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/map_provider.dart';
import '../../providers/map_provider_provider.dart';
import '../../providers/offline_provider.dart';
import '../../providers/connectivity_provider.dart';

class MapSettingsScreen extends ConsumerStatefulWidget {
  const MapSettingsScreen({super.key});

  @override
  ConsumerState<MapSettingsScreen> createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends ConsumerState<MapSettingsScreen> {
  final Map<String, bool> _downloading = {};

  static const regions = [
    {'code': 'LT', 'name': 'Lithuania', 'flag': '🇱🇹', 'sizeMb': 12},
    {'code': 'LV', 'name': 'Latvia', 'flag': '🇱🇻', 'sizeMb': 3},
    {'code': 'EE', 'name': 'Estonia', 'flag': '🇪🇪', 'sizeMb': 2},
    {'code': 'PL', 'name': 'Poland', 'flag': '🇵🇱', 'sizeMb': 18},
  ];

  Future<void> _downloadRegion(String countryCode, int sizeMb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Station Data'),
        content: Text(
          'Download ~$sizeMb MB of station data to this device? '
          'You can delete it anytime from Map Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _downloading[countryCode] = true);
    try {
      final offlineService = ref.read(offlineServiceProvider);
      await offlineService.downloadCountry(countryCode);
      ref.invalidate(syncMetadataProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$countryCode data downloaded')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading.remove(countryCode));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvider = ref.watch(mapProviderProvider);
    final forceOffline = ref.watch(forceOfflineModeProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final metadataAsync = ref.watch(syncMetadataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline Mode Section
          const Text(
            'Offline Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: forceOffline ? Colors.orange.shade50 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        forceOffline ? Icons.cloud_off : Icons.cloud_done,
                        color: forceOffline ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          forceOffline ? 'Offline Mode Enabled' : 'Online Mode',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: forceOffline,
                        onChanged: isOnline
                            ? (value) async {
                                if (value) {
                                  // Check if has data
                                  final metadataList =
                                      await ref.read(syncMetadataProvider.future);
                                  if (metadataList.isEmpty && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please download regional data first',
                                        ),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    return;
                                  }

                                  // Show disclaimer
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Enable Offline Mode'),
                                        ],
                                      ),
                                      content: const Text(
                                        'When offline mode is enabled:\n\n'
                                        '• Station data comes from local cache\n'
                                        '• Prices and availability may be outdated\n'
                                        '• New stations won\'t appear until you refresh\n'
                                        '• Real-time occupancy is unavailable\n\n'
                                        'The manufacturer is not responsible for data '
                                        'accuracy in offline mode. Data is not updated '
                                        'automatically.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('I Agree'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    ref.read(forceOfflineModeProvider.notifier).state =
                                        true;
                                  }
                                } else {
                                  ref.read(forceOfflineModeProvider.notifier).state =
                                      false;
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forceOffline
                        ? 'Using cached data only. Toggle to go back online.'
                        : isOnline
                            ? 'Using live data. Toggle to enable offline mode (saves mobile data).'
                            : 'No network connection. Using cached data.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Download Regional Data
          metadataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
            data: (metadataList) {
              final metadataMap = {
                for (final m in metadataList) m.countryCode: m,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Download Maps for Offline Use',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...regions.map((region) {
                    final code = region['code'] as String;
                    final name = region['name'] as String;
                    final flag = region['flag'] as String;
                    final sizeMb = region['sizeMb'] as int;
                    final meta = metadataMap[code];
                    final isDownloading = _downloading[code] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(flag, style: const TextStyle(fontSize: 24)),
                        title: Text(name),
                        subtitle: Text(
                          meta != null
                              ? 'Downloaded (~$sizeMb MB)'
                              : '~$sizeMb MB',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Icon(
                                  meta != null ? Icons.refresh : Icons.download,
                                  color: const Color(0xFF0066FF),
                                ),
                                onPressed: isDownloading
                                    ? null
                                    : () => _downloadRegion(code, sizeMb),
                              ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          // Map Provider Section
          const Text(
            'Map Provider',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your preferred map provider',
            style: TextStyle(
              fontSize: 14,
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
