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
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Text('Total Balance', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('₹${totalBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Income', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            Text('+₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Expense', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                          backgroundColor: record.type == RecordType.income ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                          child: Icon(
                            record.type == RecordType.income ? Icons.arrow_downward : Icons.arrow_upward,
                            color: record.type == RecordType.income ? AppColors.success : AppColors.error,
                          ),
                        ),
                        title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${record.category} • ${record.account}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${record.type == RecordType.income ? '+' : '-'}₹${record.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: record.type == RecordType.income ? AppColors.success : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditDialog(context, ref, record);
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context, ref, record);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  void _showEditDialog(BuildContext context, WidgetRef ref, RecordModel record) {
    final titleController = TextEditingController(text: record.title);
    final amountController = TextEditingController(text: record.amount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountController.text) ?? 0;
              if (titleController.text.isNotEmpty && newAmount > 0) {
                ref.read(recordsControllerProvider.notifier).updateRecord(
                  oldRecord: record,
                  newTitle: titleController.text.trim(),
                  newAmount: newAmount,
                  context: context,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, RecordModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete "${record.title}"? This will also update your account balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(recordsControllerProvider.notifier).deleteRecord(record, context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
