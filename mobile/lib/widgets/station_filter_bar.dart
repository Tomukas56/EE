import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stations_provider.dart';

class StationFilterBar extends ConsumerWidget {
  const StationFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connector = ref.watch(connectorFilterProvider);
    final minKw = ref.watch(minPowerKwProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in connectorFilters) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option.label),
                    selected: connector == option.code,
                    onSelected: (_) {
                      ref.read(connectorFilterProvider.notifier).state =
                          option.code;
                    },
                    selectedColor: const Color(0xFF00D9C0),
                    labelStyle: TextStyle(
                      color: connector == option.code
                          ? const Color(0xFF0B1F3A)
                          : const Color(0xFF111111),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD0D7E2)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in powerFilters) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option.label),
                    selected: minKw == option.kw,
                    onSelected: (_) {
                      ref.read(minPowerKwProvider.notifier).state = option.kw;
                    },
                    selectedColor: const Color(0xFFFF6B35),
                    labelStyle: TextStyle(
                      color: minKw == option.kw
                          ? Colors.white
                          : const Color(0xFF111111),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD0D7E2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
