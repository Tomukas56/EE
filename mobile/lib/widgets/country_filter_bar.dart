import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stations_provider.dart';
import '../utils/geo.dart';

class CountryFilterBar extends ConsumerWidget {
  final ValueChanged<String>? onChanged;

  const CountryFilterBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(countryFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in countryFilters) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter.code,
                onSelected: (_) {
                  ref.read(countryFilterProvider.notifier).state = filter.code;
                  onChanged?.call(filter.code);
                },
                selectedColor: const Color(0xFF0066FF),
                labelStyle: TextStyle(
                  color: selected == filter.code
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
    );
  }
}
