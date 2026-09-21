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
        onTap: _toggleExpanded,
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
