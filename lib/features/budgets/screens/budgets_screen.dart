import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/budget_controller.dart';
import '../../finance/controller/finance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/category_model.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsWithProgressProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
      ),
      body: budgets.isEmpty
          ? const Center(child: Text('No budgets set yet. Tap + to set one!'))
          : categoriesAsync.when(
              data: (allCategories) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final category = allCategories.firstWhere(
                        (c) => c.name == budget.categoryName,
                        orElse: () => allCategories.first);
                    
                    final progress = budget.limit > 0 ? budget.spent / budget.limit : 0.0;
                    final isOver = progress > 1.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: category.color.withValues(alpha: 0.2),
                                      child: Icon(category.icon, color: category.color),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(budget.categoryName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () => ref.read(budgetsControllerProvider.notifier).removeBudget(budget.id),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progress > 1.0 ? 1.0 : progress,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.error : AppColors.success),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Spent: ₹${budget.spent.toStringAsFixed(0)}', 
                                  style: TextStyle(color: isOver ? AppColors.error : Colors.white)),
                                Text('Limit: ₹${budget.limit.toStringAsFixed(0)}', 
                                  style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                            if (isOver)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Over budget by ₹${(budget.spent - budget.limit).toStringAsFixed(0)}!', 
                                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, trace) => Center(child: Text('Error loading categories: $e')),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          categoriesAsync.whenData((cats) {
            final expenseCats = cats.where((c) => c.type == CategoryType.expense).toList();
            if (expenseCats.isNotEmpty) {
              _showAddBudgetDialog(context, ref, expenseCats);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref, List<CategoryModel> categories) {
    String selectedCategory = categories.first.name;
    final limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Category Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(labelText: 'Monthly Limit', prefixText: '₹ '),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                final limit = double.tryParse(limitController.text) ?? 0;
                if (limit > 0) {
                  ref.read(budgetsControllerProvider.notifier).addBudget(selectedCategory, limit);
                  Navigator.pop(context);
                }
              },
              child: const Text('SET BUDGET'),
            ),
          ],
        ),
      ),
    );
  }
}
