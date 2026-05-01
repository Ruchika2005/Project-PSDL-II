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
import 'package:firebase_auth/firebase_auth.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));

    return groupAsync.when(
      data: (group) => Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            if (FirebaseAuth.instance.currentUser?.uid == group.createdBy)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Group'),
                      content: const Text('Are you sure you want to delete this group? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () {
                            Navigator.pop(context); // close dialog
                            ref.read(groupControllerProvider.notifier).deleteGroup(group.id, context);
                          },
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Delete Group',
              ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authControllerProvider.notifier).showLogoutConfirmation(context),
              tooltip: 'Logout',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ExpensesTab(group: group),
            _BalancesTab(group: group),
            _MembersTab(group: group),
          ],
        ),
        floatingActionButton: _buildFAB(group),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget? _buildFAB(GroupModel group) {
    switch (_tabController.index) {
      case 0: // Expenses
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddExpenseScreen(group: group)),
            );
          },
          child: const Icon(Icons.add),
        );
      case 2: // Members
        return FloatingActionButton(
          onPressed: () => _showAddMemberDialog(context, ref, group),
          child: const Icon(Icons.person_add),
        );
      default: // Balances (case 1)
        return null;
    }
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, GroupModel group) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final amountController = TextEditingController(text: '0');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite New Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  hintText: 'Friend\'s display name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Registered app email',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Amount Owed (₹)',
                  hintText: '0',
                  helperText: 'Amount they owe you right now',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && emailController.text.trim().isNotEmpty) {
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                ref.read(groupControllerProvider.notifier).inviteMember(
                      groupId: group.id,
                      groupName: group.name,
                      inviteeEmail: emailController.text.trim(),
                      inviteeName: nameController.text.trim(),
                      moneyOwed: amount,
                      context: context,
                    );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both name and email')));
              }
            },
            child: const Text('SEND REQUEST'),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final GroupModel group;
  const _ExpensesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(group.id));

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
                          child: ref.watch(memberNamesProvider(group)).when(
                            data: (map) {
                              String desc = expense.description;
                              if (desc.startsWith('Settlement: ') && desc.contains(' to ')) {
                                final parts = desc.substring(12).split(' to ');
                                if (parts.length == 2) {
                                  final fromName = map[parts[0].trim()] ?? parts[0].trim();
                                  final toName = map[parts[1].trim()] ?? parts[1].trim();
                                  desc = 'Settlement: $fromName to $toName';
                                }
                              }
                              return Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                            },
                            loading: () => Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            error: (_, __) => Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
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
                        ref.watch(memberNamesProvider(group)).when(
                          data: (map) => Text(map[expense.paidBy] ?? expense.paidBy, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          loading: () => const Text('...', style: TextStyle(fontSize: 13)),
                          error: (_, __) => Text(expense.paidBy, style: const TextStyle(fontSize: 13)),
                        ),
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

class _MembersTab extends ConsumerWidget {
  final GroupModel group;
  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingInvitesAsync = ref.watch(groupInvitesProvider(group.id));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: group.members.length,
            itemBuilder: (context, index) {
              final memberId = group.members[index];
              return ref.watch(memberNamesProvider(group)).when(
                data: (map) {
                  final name = map[memberId] ?? memberId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ),
                  );
                },
                loading: () => const ListTile(title: Text('...')),
                error: (_, __) => ListTile(title: Text(memberId)),
              );
            },
          ),
        ),
        // Pending Invites Section
        pendingInvitesAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox();
            return Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PENDING INVITATIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...invites.map((invite) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      child: Text(invite.inviteeName[0].toUpperCase(), style: const TextStyle(color: Colors.grey)),
                    ),
                    title: Text(invite.inviteeName, style: const TextStyle(color: AppColors.textSecondary)),
                    subtitle: Text(invite.inviteeEmail, style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )),
                ],
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
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
      return const Center(
        child: Text('All balances are settled up! 🎉', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
      );
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
            title: ref.watch(memberNamesProvider(group)).when(
              data: (map) {
                final fromName = map[tx.from] ?? tx.from;
                final toName = map[tx.to] ?? tx.to;
                return Text(
                  '$toName owes $fromName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                );
              },
              loading: () => const Text('Loading names...', style: TextStyle(fontSize: 16)),
              error: (_, __) => Text('${tx.from} pays ${tx.to}', style: const TextStyle(fontSize: 16)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${tx.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    ref.read(expenseControllerProvider.notifier).settleDebt(
                          groupId: group.id,
                          from: tx.from,
                          to: tx.to,
                          amount: tx.amount,
                          context: context,
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: const Text('DONE/PAID', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
