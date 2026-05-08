import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/record_model.dart';
import '../../../models/category_model.dart';
import '../../finance/controller/finance_controller.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  bool isExpense = true; // Toggle between Income and Expense
  final amountController = TextEditingController();
  final titleController = TextEditingController();
  String? selectedCategoryId;
  String? selectedAccountId;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Date Selection
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => isExpense = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpense ? AppColors.error : Theme.of(context).colorScheme.surface,
                      foregroundColor: isExpense ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('EXPENSE'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => isExpense = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isExpense ? AppColors.success : Theme.of(context).colorScheme.surface,
                      foregroundColor: !isExpense ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('INCOME'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                labelText: 'Amount',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Note',
              ),
            ),
            const SizedBox(height: 16),
            // Category Dropdown
            categoriesAsync.when(
              data: (allCategories) {
                final currentType = isExpense ? CategoryType.expense : CategoryType.income;
                final relevantCategories = allCategories.where((c) => c.type == currentType).toList();

                if (selectedCategoryId != null && !relevantCategories.any((c) => c.id == selectedCategoryId)) {
                  selectedCategoryId = null;
                }

                return DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: relevantCategories.map((c) {
                    return DropdownMenuItem(
                      value: c.id, 
                      child: Row(
                        children: [
                          Icon(c.icon, color: c.color, size: 20),
                          const SizedBox(width: 12),
                          Text(c.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategoryId = value),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, trace) => Text('Error loading categories: $e'),
            ),
            const SizedBox(height: 16),
            // Account Dropdown
            accountsAsync.when(
              data: (accounts) {
                return DropdownButtonFormField<String>(
                  value: selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedAccountId = value),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, trace) => Text('Error loading accounts: $e'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ref.watch(recordsControllerProvider) ? null : () {
                  if (amountController.text.isNotEmpty && titleController.text.isNotEmpty && selectedCategoryId != null && selectedAccountId != null) {
                    ref.read(recordsControllerProvider.notifier).addRecord(
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      type: isExpense ? RecordType.expense : RecordType.income,
                      categoryId: selectedCategoryId!,
                      accountId: selectedAccountId!,
                      context: context,
                      date: selectedDate,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  }
                },
                child: ref.watch(recordsControllerProvider) 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('SAVE RECORD'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
