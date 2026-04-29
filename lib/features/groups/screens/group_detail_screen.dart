import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/group_model.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../expenses/controller/expense_controller.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../settlement/controller/settlement_controller.dart';
import '../controller/group_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddMemberDialog(context, ref),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            isScrollable: true,
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Expenses List
            _ExpensesTab(groupId: group.id),
            
            // Tab 2: Balances (Settlements)
            _BalancesTab(group: group),

            // Tab 3: Members List
            _MembersTab(group: group),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddExpenseScreen(group: group)),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Member'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Member Name',
            hintText: 'Enter friend\'s name',
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(groupControllerProvider.notifier).addMember(
                      group.id,
                      nameController.text.trim(),
                      context,
                    );
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final String groupId;
  const _ExpensesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses yet.', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.receipt, color: AppColors.primary),
                ),
                title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Paid by: ${expense.paidBy}'),
                trailing: Text('₹${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, trace) => Center(child: Text('Error: $e')),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final GroupModel group;
  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final memberName = group.members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                memberName[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: const Icon(Icons.person, color: AppColors.textSecondary, size: 20),
          ),
        );
      },
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  final GroupModel group;
  const _BalancesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(settlementProvider(group.id));

    if (transactions.isEmpty) {
      return const Center(child: Text('All balances are settled up! 🎉', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: const Icon(Icons.payment, color: AppColors.primary),
            ),
            title: Text(
              '${tx.from} pays ${tx.to}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: Text(
              '₹${tx.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.error,
              ),
            ),
          ),
        );
      },
    );
  }
}
