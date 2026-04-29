import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/group_model.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../expenses/controller/expense_controller.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../settlement/controller/settlement_controller.dart';
import '../controller/group_controller.dart';
import '../../auth/controller/auth_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return groupAsync.when(
      data: (group) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => _showAddMemberDialog(context, ref, group),
              ),
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
                Tab(text: 'Expenses'),
                Tab(text: 'Balances'),
                Tab(text: 'Members'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _ExpensesTab(groupId: group.id, members: group.members),
              _BalancesTab(group: group),
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
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, GroupModel group) {
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
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(groupControllerProvider.notifier).addMember(
                      group.id,
                      nameController.text.trim(),
                      context,
                    );
                Navigator.pop(context);
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
  final List<String> members;
  const _ExpensesTab({required this.groupId, required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses yet.', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final splitCount = expense.splits.length;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.surface.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(expense.description, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        Text('₹${expense.amount.toStringAsFixed(0)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_pin, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Paid by ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(expense.paidBy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Split between $splitCount people', 
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
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
