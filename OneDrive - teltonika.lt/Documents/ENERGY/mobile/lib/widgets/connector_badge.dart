import 'package:flutter/material.dart';
import '../models/connector.dart';

class ConnectorBadge extends StatelessWidget {
  final Connector connector;

  const ConnectorBadge({super.key, required this.connector});

  Color get statusColor {
    switch (connector.status) {
      case ConnectorStatus.AVAILABLE:
        return Colors.green;
      case ConnectorStatus.OCCUPIED:
      case ConnectorStatus.CHARGING:
        return Colors.orange;
      case ConnectorStatus.OUTOFORDER:
        return Colors.red;
      case ConnectorStatus.UNKNOWN:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (connector.type) {
      case ConnectorType.CCS:
        return Icons.ev_station;
      case ConnectorType.CHAdeMO:
        return Icons.flash_on;
      case ConnectorType.TYPE2:
      case ConnectorType.TYPE1:
        return Icons.electrical_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          // Type Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),

          // Connector Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and Power
                Text(
                  '${connector.type.displayName} • ${connector.maxPowerKw.toStringAsFixed(0)} kW',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // EVSE ID
                Text(
                  connector.evseId,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),

                // Tariff
                if (connector.tariff != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    connector.tariff!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              connector.status.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
