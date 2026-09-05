import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stations_provider.dart';
import '../utils/geo.dart';

/// Compact filter icons on the left: country, plug, min kW.
class MapFilterRail extends ConsumerWidget {
  const MapFilterRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(countryFilterProvider);
    final connector = ref.watch(connectorFilterProvider);
    final minKw = ref.watch(minPowerKwProvider);
    final minEur = ref.watch(minPriceEurProvider);
    final maxEur = ref.watch(maxPriceEurProvider);
    final countryLabel =
        countryFilters.firstWhere((f) => f.code == country).label;
    final plugLabel =
        connectorFilters.firstWhere((f) => f.code == connector).label;
    final powerLabel =
        powerFilters.firstWhere((f) => f.kw == minKw).label;
    final priceLabel = _priceRailLabel(minEur, maxEur);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterIcon(
          tooltip: 'Country',
          label: country == 'ALL' ? 'ALL' : countryLabel,
          icon: Icons.flag_outlined,
          onTap: () => _pick<String>(
            context: context,
            title: 'Country',
            options: [
              for (final f in countryFilters) (value: f.code, label: f.label),
            ],
            selected: country,
            onPicked: (code) {
              ref.read(countryFilterProvider.notifier).state = code;
            },
          ),
        ),
        const SizedBox(height: 8),
        _FilterIcon(
          tooltip: 'Plug',
          label: connector == 'ALL' ? 'Plug' : plugLabel,
          icon: Icons.electrical_services,
          onTap: () => _pick<String>(
            context: context,
            title: 'Plug',
            options: [
              for (final f in connectorFilters) (value: f.code, label: f.label),
            ],
            selected: connector,
            onPicked: (code) {
              ref.read(connectorFilterProvider.notifier).state = code;
            },
          ),
        ),
        const SizedBox(height: 8),
        _FilterIcon(
          tooltip: 'Power',
          label: minKw == 0 ? 'kW' : powerLabel,
          icon: Icons.bolt,
          onTap: () => _pick<double>(
            context: context,
            title: 'Min power',
            options: [
              for (final f in powerFilters) (value: f.kw, label: f.label),
            ],
            selected: minKw,
            onPicked: (kw) {
              ref.read(minPowerKwProvider.notifier).state = kw;
            },
          ),
        ),
        const SizedBox(height: 8),
        _FilterIcon(
          tooltip: 'Price',
          label: priceLabel,
          icon: Icons.euro,
          onTap: () => _pickPrice(context, ref, minEur, maxEur),
        ),
      ],
    );
  }

  Future<void> _pickPrice(
    BuildContext context,
    WidgetRef ref,
    double minEur,
    double maxEur,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    'Price (€/kWh)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Text('Lowest', style: TextStyle(color: Color(0xFF3A3A3C))),
                ),
                for (final option in priceMinFilters)
                  ListTile(
                    dense: true,
                    title: Text(option.label),
                    trailing: option.eur == minEur
                        ? const Icon(Icons.check, color: Color(0xFF0066FF))
                        : null,
                    onTap: () {
                      var nextMin = option.eur;
                      var nextMax = maxEur;
                      if (nextMin > 0 && nextMax > 0 && nextMin > nextMax) {
                        nextMax = nextMin;
                      }
                      ref.read(minPriceEurProvider.notifier).state = nextMin;
                      ref.read(maxPriceEurProvider.notifier).state = nextMax;
                      Navigator.pop(context);
                    },
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text('Highest', style: TextStyle(color: Color(0xFF3A3A3C))),
                ),
                for (final option in priceMaxFilters)
                  ListTile(
                    dense: true,
                    title: Text(option.label),
                    trailing: option.eur == maxEur
                        ? const Icon(Icons.check, color: Color(0xFF0066FF))
                        : null,
                    onTap: () {
                      var nextMax = option.eur;
                      var nextMin = minEur;
                      if (nextMin > 0 && nextMax > 0 && nextMin > nextMax) {
                        nextMin = nextMax;
                      }
                      ref.read(minPriceEurProvider.notifier).state = nextMin;
                      ref.read(maxPriceEurProvider.notifier).state = nextMax;
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pick<T>({
    required BuildContext context,
    required String title,
    required List<({T value, String label})> options,
    required T selected,
    required ValueChanged<T> onPicked,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  trailing: option.value == selected
                      ? const Icon(Icons.check, color: Color(0xFF0066FF))
                      : null,
                  onTap: () => Navigator.pop(context, option.value),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) onPicked(picked);
  }
}

String _priceRailLabel(double minEur, double maxEur) {
  if (minEur <= 0 && maxEur <= 0) return '€';
  if (minEur <= 0) return '≤${maxEur.toStringAsFixed(2)}';
  if (maxEur <= 0) return '≥${minEur.toStringAsFixed(2)}';
  return '${minEur.toStringAsFixed(2)}–${maxEur.toStringAsFixed(2)}';
}

class _FilterIcon extends StatelessWidget {
  const _FilterIcon({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Tooltip(
            message: tooltip,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: const Color(0xFF111111)),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
