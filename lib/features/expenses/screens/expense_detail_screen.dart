import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/expense_model.dart';
import '../../../models/group_model.dart';
import '../../groups/controller/group_controller.dart';
import '../../../core/constants/app_colors.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseModel expense;
  final GroupModel group;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberNamesAsync = ref.watch(memberNamesProvider(group));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    expense.description,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(expense.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Paid By Section
            _buildSectionTitle(context, 'PAID BY'),
            const SizedBox(height: 12),
            memberNamesAsync.when(
              data: (map) => _buildMemberTile(
                context,
                map[expense.paidBy] ?? expense.paidBy,
                expense.amount,
                isPayer: true,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildMemberTile(context, expense.paidBy, expense.amount, isPayer: true),
            ),
            
            const SizedBox(height: 32),

            // Split Details Section
            _buildSectionTitle(context, 'SPLIT DETAILS'),
            const SizedBox(height: 12),
            memberNamesAsync.when(
              data: (map) => Column(
                children: expense.splits.map((split) {
                  final name = map[split.userId] ?? split.userId;
                  return _buildMemberTile(context, name, split.amount);
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Column(
                children: expense.splits.map((split) => _buildMemberTile(context, split.userId, split.amount)).toList(),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Split Type Info
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Text(
                  'Split Type: ${expense.splitType.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, String name, double amount, {bool isPayer = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPayer 
              ? AppColors.success.withOpacity(0.5) 
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: isPayer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isPayer ? AppColors.success : Theme.of(context).colorScheme.primary).withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: isPayer ? AppColors.success : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isPayer ? AppColors.success : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
