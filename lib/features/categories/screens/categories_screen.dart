import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../finance/controller/finance_controller.dart';
import '../../auth/controller/auth_controller.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();
        final incomeCategories = categories.where((c) => c.type == CategoryType.income).toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Categories'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => ref.read(authControllerProvider.notifier).showLogoutConfirmation(context),
                  tooltip: 'Logout',
                ),
              ],
              bottom: const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildCategoryList(expenseCategories),
                _buildCategoryList(incomeCategories),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _showAddCategoryDialog(context, ref);
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: category.color.withValues(alpha: 0.2),
                  child: Icon(category.icon, color: category.color),
                ),
                const SizedBox(height: 8),
                Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    CategoryType selectedType = CategoryType.expense;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              DropdownButton<CategoryType>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: CategoryType.expense, child: Text('Expense')),
                  DropdownMenuItem(value: CategoryType.income, child: Text('Income')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
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
                if (nameController.text.isNotEmpty) {
                  ref.read(categoriesControllerProvider.notifier).addCategory(
                    nameController.text,
                    selectedType,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }
}
