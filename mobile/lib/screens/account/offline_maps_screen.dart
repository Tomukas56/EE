import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/offline_provider.dart';

class OfflineMapsScreen extends ConsumerStatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  ConsumerState<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends ConsumerState<OfflineMapsScreen> {
  final Map<String, bool> _downloading = {};

  static const regions = [
    {'code': 'LT', 'name': 'Lithuania', 'flag': '🇱🇹', 'sizeMb': 12, 'stations': 1500},
    {'code': 'LV', 'name': 'Latvia', 'flag': '🇱🇻', 'sizeMb': 3, 'stations': 400},
    {'code': 'EE', 'name': 'Estonia', 'flag': '🇪🇪', 'sizeMb': 2, 'stations': 300},
    {'code': 'PL', 'name': 'Poland', 'flag': '🇵🇱', 'sizeMb': 18, 'stations': 2500},
  ];

  Future<void> _downloadRegion(String countryCode, int sizeMb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Station Data'),
        content: Text(
          'Download ~$sizeMb MB of station data to this device? '
          'You can delete it anytime from Offline Maps.',
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

  Future<void> _deleteRegion(String countryCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cached Data'),
        content: Text('Delete $countryCode offline data from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final offlineService = ref.read(offlineServiceProvider);
      await offlineService.deleteCountry(countryCode);
      ref.invalidate(syncMetadataProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$countryCode data deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(syncMetadataProvider);
    final forceOffline = ref.watch(forceOfflineModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
      ),
      body: metadataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading offline data: $error'),
          ),
        ),
        data: (metadataList) {
          final metadataMap = {
            for (final m in metadataList) m.countryCode: m,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Download station data to use the app without network. '
                'Data may be outdated when offline.',
                style: TextStyle(color: Color(0xFF3A3A3C)),
              ),
              const SizedBox(height: 24),
              // Force offline mode toggle
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Force offline mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    forceOffline
                        ? 'Using cached data only (saves mobile data)'
                        : 'Auto: Online when available, offline when not',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: forceOffline,
                  onChanged: (value) async {
                    if (value) {
                      // Show disclaimer when enabling offline mode
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Offline Mode'),
                            ],
                          ),
                          content: const Text(
                            'When offline mode is enabled:\n\n'
                            '• Station data comes from local cache\n'
                            '• Prices and availability may be outdated\n'
                            '• New stations won\'t appear until you refresh\n'
                            '• Real-time occupancy is unavailable\n\n'
                            'The manufacturer is not responsible for data accuracy in offline mode. '
                            'Data is not updated automatically from the moment offline mode is enabled.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Enable Offline Mode'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        ref.read(forceOfflineModeProvider.notifier).state = true;
                      }
                    } else {
                      ref.read(forceOfflineModeProvider.notifier).state = false;
                    }
                  },
                  secondary: Icon(
                    forceOffline ? Icons.cloud_off : Icons.cloud_queue,
                    color: forceOffline ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ...regions.map((region) {
                final code = region['code'] as String;
                final name = region['name'] as String;
                final flag = region['flag'] as String;
                final sizeMb = region['sizeMb'] as int;
                final stations = region['stations'] as int;
                final meta = metadataMap[code];
                final isDownloading = _downloading[code] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              flag,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '~$sizeMb MB · $stations stations',
                                    style: const TextStyle(
                                      color: Color(0xFF3A3A3C),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                meta.needsRefreshWarning
                                    ? Icons.warning
                                    : Icons.check_circle,
                                size: 16,
                                color: meta.needsRefreshWarning
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Last update: ${_formatAge(meta.age)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF3A3A3C),
                                ),
                              ),
                            ],
                          ),
                          if (meta.needsRefreshWarning) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Data is ${meta.age.inDays} days old. '
                              'Refresh recommended for accurate info.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (isDownloading)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isDownloading
                                      ? null
                                      : () => _downloadRegion(code, sizeMb),
                                  child: Text(isDownloading
                                      ? 'Updating…'
                                      : 'Update'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isDownloading
                                      ? null
                                      : () => _deleteRegion(code),
                                  child: const Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Not downloaded',
                            style: TextStyle(
                              color: Color(0xFF3A3A3C),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isDownloading)
                            const LinearProgressIndicator()
                          else
                            FilledButton(
                              onPressed: () => _downloadRegion(code, sizeMb),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                              ),
                              child: const Text('Download'),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () async {
                  final totalSizeMb = regions.fold<int>(
                    0,
                    (sum, r) => sum + (r['sizeMb'] as int),
                  );
                  await _downloadRegion('ALL', totalSizeMb);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Download All Countries (~${regions.fold<int>(0, (sum, r) => sum + (r['sizeMb'] as int))} MB)',
                ),
              ),
              if (metadataList.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Offline Data'),
                        content: const Text(
                          'Delete all cached station data from this device?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      try {
                        final offlineService =
                            ref.read(offlineServiceProvider);
                        await offlineService.clearAll();
                        ref.invalidate(syncMetadataProvider);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All offline data deleted'),
                          ),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Clear failed: $error')),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Clear All Offline Data'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
