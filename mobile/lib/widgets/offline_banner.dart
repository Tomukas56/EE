import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_provider.dart';

class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _dismissed = false;

  String _formatAge(Duration age) {
    if (age.inMinutes < 60) return '${age.inMinutes} minutes';
    if (age.inHours < 24) return '${age.inHours} hours';
    if (age.inDays == 1) return '1 day';
    return '${age.inDays} days';
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _expanded) {
          setState(() => _expanded = false);
        }
      });
    }
  }

  Future<void> _showOfflineModeDialog() async {
    final isOnline = ref.read(isOnlineProvider);
    final forceOffline = ref.read(forceOfflineModeProvider);
    final metadataList = await ref.read(syncMetadataProvider.future);
    final hasData = metadataList.isNotEmpty;

    if (!mounted) return;

    // If trying to enable offline but no data - redirect to download
    if (isOnline && !forceOffline && !hasData) {
      final goToDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Offline Mode'),
            ],
          ),
          content: const Text(
            'To use offline mode, you need to download station data first.\n\n'
            'Go to Offline Maps to download data for your region?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Download Maps'),
            ),
          ],
        ),
      );

      if (goToDownload == true && mounted) {
        Navigator.of(context).pushNamed('offline-maps');
      }
      return;
    }

    // Show toggle dialog
    await showDialog(
      context: context,
      builder: (context) => _OfflineModeDialog(
        isOnline: isOnline,
        forceOffline: forceOffline,
        hasData: hasData,
        onToggle: (value) async {
          if (value) {
            // Enable offline
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
                  'The manufacturer is not responsible for data accuracy in offline mode. '
                  'Data is not updated automatically.',
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
              ref.read(forceOfflineModeProvider.notifier).state = true;
              if (context.mounted) Navigator.pop(context);
            }
          } else {
            // Disable offline
            ref.read(forceOfflineModeProvider.notifier).state = false;
            if (context.mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isOnline = ref.watch(isOnlineProvider);
    final forceOffline = ref.watch(forceOfflineModeProvider);
    final metadataAsync = ref.watch(syncMetadataProvider);

    final isOfflineMode = !isOnline || forceOffline;

    // Online status
    if (!isOfflineMode) {
      return _buildStatusIndicator(
        color: Colors.green.shade700,
        icon: Icons.cloud_done,
        message: 'Online — live data',
      );
    }

    // Offline status
    return metadataAsync.when(
      loading: () => _buildStatusIndicator(
        color: Colors.orange.shade800,
        icon: Icons.offline_bolt,
        message: 'Offline — no cached data',
      ),
      error: (error, stack) => _buildStatusIndicator(
        color: Colors.orange.shade800,
        icon: Icons.offline_bolt,
        message: 'Offline — no cached data',
      ),
      data: (metadataList) {
        if (metadataList.isEmpty) {
          return _buildStatusIndicator(
            color: Colors.red.shade700,
            icon: Icons.warning,
            message: 'Offline — no cached data available',
          );
        }

        final oldestAge = metadataList.map((m) => m.age).reduce((a, b) => a > b ? a : b);
        final isVeryOld = oldestAge.inDays >= 7;
        
        final message = forceOffline
            ? 'Offline mode (manual) — data may be outdated'
            : 'Offline (no network) — last update ${_formatAge(oldestAge)} ago';

        return _buildStatusIndicator(
          color: isVeryOld ? Colors.red.shade700 : Colors.orange.shade800,
          icon: isVeryOld ? Icons.warning : Icons.offline_bolt,
          message: message,
        );
      },
    );
  }

  Widget _buildStatusIndicator({
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: _showOfflineModeDialog,
        onLongPress: _toggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: _expanded ? MediaQuery.of(context).size.width * 0.5 : 40,
          height: 40,
          child: Material(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            elevation: 4,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _dismissed = true),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OfflineModeDialog extends StatelessWidget {
  final bool isOnline;
  final bool forceOffline;
  final bool hasData;
  final Function(bool) onToggle;

  const _OfflineModeDialog({
    required this.isOnline,
    required this.forceOffline,
    required this.hasData,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOfflineMode = !isOnline || forceOffline;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
            color: isOfflineMode ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          const Text('Connection Mode'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOfflineMode
                ? 'Currently using cached data'
                : 'Currently using live data',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOfflineMode
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isOfflineMode ? Icons.wifi_off : Icons.wifi,
                  color: isOfflineMode ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOfflineMode ? 'Offline Mode' : 'Online Mode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: forceOffline,
                  onChanged: isOnline ? onToggle : null,
                ),
              ],
            ),
          ),
          if (!isOnline) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No network connection available',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
          if (!hasData && isOnline) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No offline data downloaded yet',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
