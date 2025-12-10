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
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              const SizedBox(height: 8),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
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
                      color: station.availableConnectors > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: station.availableConnectors > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      '${station.availableConnectors}/${station.connectorCount} Available',
                      style: TextStyle(
                        color: station.availableConnectors > 0
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Status Icon
                  Icon(
                    station.availableConnectors > 0
                        ? Icons.ev_station
                        : Icons.block,
                    color: station.availableConnectors > 0
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
