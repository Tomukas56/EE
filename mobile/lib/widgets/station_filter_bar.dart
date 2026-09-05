import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stations_provider.dart';

class StationFilterBar extends ConsumerWidget {
  final bool compact;

  const StationFilterBar({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connector = ref.watch(connectorFilterProvider);
    final minKw = ref.watch(minPowerKwProvider);
    final minEur = ref.watch(minPriceEurProvider);
    final maxEur = ref.watch(maxPriceEurProvider);
    final density = compact ? VisualDensity.compact : VisualDensity.standard;
    final gap = compact ? 6.0 : 8.0;

    Widget chip({
      required String label,
      required bool selected,
      required Color selectedColor,
      required Color selectedText,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: EdgeInsets.only(right: gap),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          visualDensity: density,
          materialTapTargetSize: compact
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          labelPadding:
              compact ? const EdgeInsets.symmetric(horizontal: 8) : null,
          onSelected: (_) => onTap(),
          selectedColor: selectedColor,
          labelStyle: TextStyle(
            color: selected ? selectedText : const Color(0xFF111111),
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : null,
          ),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD0D7E2)),
        ),
      );
    }

    final connectorRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in connectorFilters)
            chip(
              label: option.label,
              selected: connector == option.code,
              selectedColor: const Color(0xFF00D9C0),
              selectedText: const Color(0xFF0B1F3A),
              onTap: () {
                ref.read(connectorFilterProvider.notifier).state = option.code;
              },
            ),
        ],
      ),
    );

    final powerRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in powerFilters)
            chip(
              label: option.label,
              selected: minKw == option.kw,
              selectedColor: const Color(0xFFFF6B35),
              selectedText: Colors.white,
              onTap: () {
                ref.read(minPowerKwProvider.notifier).state = option.kw;
              },
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        connectorRow,
        SizedBox(height: compact ? gap : 8),
        powerRow,
        SizedBox(height: compact ? gap : 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in priceMinFilters)
                chip(
                  label: option.label,
                  selected: minEur == option.eur,
                  selectedColor: const Color(0xFF0066FF),
                  selectedText: Colors.white,
                  onTap: () {
                    var nextMin = option.eur;
                    var nextMax = maxEur;
                    if (nextMin > 0 && nextMax > 0 && nextMin > nextMax) {
                      nextMax = nextMin;
                    }
                    ref.read(minPriceEurProvider.notifier).state = nextMin;
                    ref.read(maxPriceEurProvider.notifier).state = nextMax;
                  },
                ),
              for (final option in priceMaxFilters.skip(1))
                chip(
                  label: option.label,
                  selected: maxEur == option.eur,
                  selectedColor: const Color(0xFF111111),
                  selectedText: Colors.white,
                  onTap: () {
                    var nextMax = option.eur;
                    var nextMin = minEur;
                    if (nextMin > 0 && nextMax > 0 && nextMin > nextMax) {
                      nextMin = nextMax;
                    }
                    ref.read(minPriceEurProvider.notifier).state = nextMin;
                    ref.read(maxPriceEurProvider.notifier).state = nextMax;
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
