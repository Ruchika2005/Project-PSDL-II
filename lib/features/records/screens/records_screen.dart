import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/record_model.dart';
import '../../finance/controller/finance_controller.dart';
import '../../auth/controller/auth_controller.dart';
import 'add_record_screen.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Monthly filter logic later
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          final accounts = accountsAsync.value ?? [];
          double totalBalance = accounts.fold(0, (sum, item) => sum + item.balance);
          
          double totalIncome = records.where((r) => r.type == RecordType.income).fold(0, (sum, item) => sum + item.amount);
          double totalExpense = records.where((r) => r.type == RecordType.expense).fold(0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              // Dashboard Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  children: [
                    const Text('Total Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('₹${totalBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Income', style: TextStyle(color: AppColors.textSecondary)),
                            Text('+₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Expense', style: TextStyle(color: AppColors.textSecondary)),
                            Text('-₹${totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
              
              // Records List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: record.type == RecordType.income ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                          child: Icon(
                            record.type == RecordType.income ? Icons.arrow_downward : Icons.arrow_upward,
                            color: record.type == RecordType.income ? AppColors.success : AppColors.error,
                          ),
                        ),
                        title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${record.category} • ${record.account}', style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: Text(
                          '${record.type == RecordType.income ? '+' : '-'}₹${record.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: record.type == RecordType.income ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRecordScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
