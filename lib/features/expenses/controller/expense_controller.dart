import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../repository/expense_repository.dart';
import '../../../models/expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final expenseControllerProvider = NotifierProvider<ExpenseController, bool>(ExpenseController.new);

final groupExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, groupId) {
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return expenseRepo.getGroupExpenses(groupId);
});

class ExpenseController extends Notifier<bool> {
  late ExpenseRepository _expenseRepository;

  @override
  bool build() {
    _expenseRepository = ref.watch(expenseRepositoryProvider);
    return false;
  }

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<ExpenseSplit> splits,
    required SplitType splitType,
    required BuildContext context,
  }) async {
    state = true;
    try {
      // Validate based on split type
      if (splitType == SplitType.percentage) {
        double totalPercentage = splits.fold(0, (sum, split) => sum + split.amount);
        if ((totalPercentage - 100).abs() > 0.01) {
          throw Exception('Percentages must add up to 100%');
        }
      } else if (splitType == SplitType.unequal) {
        double totalSplit = splits.fold(0, (sum, split) => sum + split.amount);
        if ((totalSplit - amount).abs() > 0.01) {
          throw Exception('Unequal splits must add up to the total amount ($amount)');
        }
      }

      final expenseId = const Uuid().v4();
      final expense = ExpenseModel(
        id: expenseId,
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        splits: splits,
        splitType: splitType,
        createdAt: DateTime.now(),
      );

      await _expenseRepository.addExpense(expense);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }
}
