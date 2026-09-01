import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stations_provider.dart';
import '../utils/geo.dart';

class CountryFilterBar extends ConsumerWidget {
  final ValueChanged<String>? onChanged;
  final bool compact;

  const CountryFilterBar({super.key, this.onChanged, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(countryFilterProvider);
    final density = compact ? VisualDensity.compact : VisualDensity.standard;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in countryFilters) ...[
            Padding(
              padding: EdgeInsets.only(right: compact ? 6 : 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter.code,
                visualDensity: density,
                materialTapTargetSize: compact
                    ? MaterialTapTargetSize.shrinkWrap
                    : MaterialTapTargetSize.padded,
                labelPadding: compact
                    ? const EdgeInsets.symmetric(horizontal: 8)
                    : null,
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
                  fontSize: compact ? 12 : null,
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
