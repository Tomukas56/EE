import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/sessions_provider.dart';

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

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chargingHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(chargingHistoryProvider),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load payments: $error'),
          ),
        ),
        data: (sessions) {
          final payments = sessions
              .where((s) => !s.isOpen && s.costEur > 0)
              .map(
                (s) => PaymentRecord(
                  id: s.id.substring(0, s.id.length.clamp(0, 8)),
                  date: s.endTime ?? s.startTime,
                  amount: s.costEur,
                  sessionId: s.id,
                  stationName: s.stationName,
                  status: s.status,
                  paymentMethod: s.paymentMethod.isEmpty
                      ? 'lab-estimate'
                      : s.paymentMethod,
                ),
              )
              .toList();
          final totalAmount = payments.fold(0.0, (sum, p) => sum + p.amount);

          return Column(
            children: [
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
                      'Lab estimate (not Stripe)',
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
                      '${payments.length} completed sessions',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              _WalletBindingBanner(),
              Expanded(
                child: payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lab estimates yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          return _PaymentCard(payment: payments[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletBindingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    late final String title;
    late final String body;
    late final IconData icon;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        title = 'Apple Wallet / Apple Pay';
        body =
            'This device is not linked to Apple Wallet or Apple Pay. Lab receipts stay in the app only.';
        icon = Icons.phone_iphone;
      case TargetPlatform.android:
        title = 'Google Wallet / Google Pay';
        body =
            'This Android device is not linked to Google Wallet or Google Pay. Lab receipts stay in the app only.';
        icon = Icons.android;
      default:
        title = 'Device wallet';
        body =
            'No device wallet is linked in this lab build. Payments here are estimates, not card charges.';
        icon = Icons.account_balance_wallet_outlined;
    }
    return Material(
      color: const Color(0xFFEEF6FF),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0066FF)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(body, style: const TextStyle(fontSize: 13, height: 1.3)),
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
            color: AppColors.successGreen.withValues(alpha: 0.1),
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
