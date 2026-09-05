import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/station.dart';

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'station-detail',
            pathParameters: {'id': station.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station Name
              Text(
                station.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // Operator
              if (station.operatorName != null)
                Text(
                  station.operatorName!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),

              // Address
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      station.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Connectors Info
              Row(
                children: [
                  // Available Connectors
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !station.hasLiveOccupancy
                          ? Colors.blueGrey.shade50
                          : station.availableConnectors > 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !station.hasLiveOccupancy
                            ? Colors.blueGrey
                            : station.availableConnectors > 0
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    child: Text(
                      station.hasLiveOccupancy
                          ? '${station.availableConnectors}/${station.connectorCount} Available'
                          : '${station.connectorCount} connectors',
                      style: TextStyle(
                        color: !station.hasLiveOccupancy
                            ? Colors.blueGrey.shade900
                            : station.availableConnectors > 0
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (station.tariff != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      station.tariff!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),

                  // Status Icon
                  Icon(
                    !station.hasLiveOccupancy
                        ? Icons.ev_station
                        : station.availableConnectors > 0
                            ? Icons.ev_station
                            : Icons.block,
                    color: !station.hasLiveOccupancy
                        ? Colors.blueGrey
                        : station.availableConnectors > 0
                            ? Colors.green
                            : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
