import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

class PaymentRecord {
  final String id;
  final DateTime date;
  final double amount;
  final String sessionId;
  final String stationName;
  final String status;
  final String paymentMethod;

  PaymentRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.sessionId,
    required this.stationName,
    required this.status,
    required this.paymentMethod,
  });
}

// Mock data
final paymentHistoryProvider = Provider<List<PaymentRecord>>((ref) {
  return [
    PaymentRecord(
      id: 'PAY001',
      date: DateTime.now().subtract(const Duration(days: 2)),
      amount: 15.82,
      sessionId: '1',
      stationName: 'Ignitis Charging Hub - Vilnius',
      status: 'completed',
      paymentMethod: 'Google Pay',
    ),
    PaymentRecord(
      id: 'PAY002',
      date: DateTime.now().subtract(const Duration(days: 5)),
      amount: 8.20,
      sessionId: '2',
      stationName: 'Elinta Fast Charge - Kaunas',
      status: 'completed',
      paymentMethod: 'Visa ****1234',
    ),
    PaymentRecord(
      id: 'PAY003',
      date: DateTime.now().subtract(const Duration(days: 7)),
      amount: 18.03,
      sessionId: '3',
      stationName: 'Maxima Shopping Center',
      status: 'completed',
      paymentMethod: 'Google Pay',
    ),
  ];
});

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentHistoryProvider);
    final totalAmount = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History'), elevation: 0),
      body: Column(
        children: [
          // Total Spent
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Spent',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  '€${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${payments.length} transactions',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: payments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No payment history',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _PaymentCard(payment: payment);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentRecord payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.check_circle, color: AppColors.successGreen),
        ),
        title: Text(
          payment.stationName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y • HH:mm').format(payment.date),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payment, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  payment.paymentMethod,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '€${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              payment.id,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
