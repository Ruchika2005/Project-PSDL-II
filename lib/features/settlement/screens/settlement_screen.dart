import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/group_model.dart';
import '../controller/settlement_controller.dart';
import '../../../core/constants/app_colors.dart';

class SettlementScreen extends ConsumerWidget {
  final GroupModel group;

  const SettlementScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(settlementProvider(group.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('All balances are settled up! 🎉', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.payment, color: AppColors.primary),
                    title: Text(
                      '${tx.from} pays ${tx.to}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '₹${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
