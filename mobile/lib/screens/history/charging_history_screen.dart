import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/charging_session.dart';

// Mock data provider (replace with real API later)
final chargingHistoryProvider = Provider<List<ChargingSession>>((ref) {
  return [
    ChargingSession(
      id: '1',
      stationId: '90cc06ec-54ef-4c75-97b9-bf5ea5557637',
      stationName: 'Ignitis Charging Hub - Vilnius',
      connectorType: 'CCS',
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      energyKwh: 45.2,
      costEur: 15.82,
      status: 'completed',
    ),
    ChargingSession(
      id: '2',
      stationId: 'a3707dc4-1565-46a8-a463-31169ebf7937',
      stationName: 'Elinta Fast Charge - Kaunas',
      connectorType: 'Type 2',
      startTime: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
      endTime: DateTime.now().subtract(const Duration(days: 5)),
      energyKwh: 32.8,
      costEur: 8.20,
      status: 'completed',
    ),
    ChargingSession(
      id: '3',
      stationId: 'efab2b1a-2729-4d92-bc34-3271367f7a23',
      stationName: 'Maxima Shopping Center',
      connectorType: 'CCS',
      startTime: DateTime.now().subtract(const Duration(days: 7, hours: 4)),
      endTime: DateTime.now().subtract(const Duration(days: 7, hours: 3)),
      energyKwh: 51.5,
      costEur: 18.03,
      status: 'completed',
    ),
  ];
});

class ChargingHistoryScreen extends ConsumerWidget {
  const ChargingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chargingHistoryProvider);
    final totalEnergy = sessions.fold(0.0, (sum, s) => sum + s.energyKwh);
    final totalCost = sessions.fold(0.0, (sum, s) => sum + s.costEur);

    return Scaffold(
      appBar: AppBar(title: const Text('Charging History'), elevation: 0),
      body: Column(
        children: [
          // Stats Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.bolt,
                      label: 'Total Energy',
                      value: '${totalEnergy.toStringAsFixed(1)} kWh',
                    ),
                    _StatItem(
                      icon: Icons.euro,
                      label: 'Total Cost',
                      value: '€${totalCost.toStringAsFixed(2)}',
                    ),
                    _StatItem(
                      icon: Icons.ev_station,
                      label: 'Sessions',
                      value: '${sessions.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sessions List
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No charging sessions yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _SessionCard(session: session);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ChargingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.ev_station, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.stationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM d, y • HH:mm',
                        ).format(session.startTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.status.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    icon: Icons.power,
                    label: 'Energy',
                    value: '${session.energyKwh.toStringAsFixed(1)} kWh',
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: session.formattedDuration,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.euro,
                    label: 'Cost',
                    value: '€${session.costEur.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
