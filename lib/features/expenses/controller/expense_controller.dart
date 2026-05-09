import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../repository/expense_repository.dart';
import '../repository/bill_repository.dart';
import '../../../models/expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';

final expenseControllerProvider = NotifierProvider<ExpenseController, bool>(ExpenseController.new);

final groupExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, groupId) {
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return expenseRepo.getGroupExpenses(groupId);
});

class ExpenseController extends Notifier<bool> {
  late ExpenseRepository _expenseRepository;
  late BillRepository _billRepository;
  
  @override
  bool build() {
    _expenseRepository = ref.watch(expenseRepositoryProvider);
    _billRepository = ref.watch(billRepositoryProvider);
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
    File? billImage,
  }) async {
    state = true;
    try {
      if (splitType == SplitType.percentage) {
        double totalPercentage = splits.fold(0, (sum, split) => sum + split.amount);
        if ((totalPercentage - 100).abs() > 0.01) {
          if (context.mounted) {
            _showValidationError(
              context, 
              'Percentage Mismatch', 
              'The sum of percentages (₹${totalPercentage.toStringAsFixed(1)}%) does not match 100%. Please adjust the values.'
            );
          }
          state = false;
          return;
        }
      } else if (splitType == SplitType.unequal) {
        double totalSplit = splits.fold(0, (sum, split) => sum + split.amount);
        if ((totalSplit - amount).abs() > 0.01) {
          if (context.mounted) {
            _showValidationError(
              context, 
              'Amount Mismatch', 
              'The sum of unequal splits (₹${totalSplit.toStringAsFixed(2)}) does not match the total expense amount (₹${amount.toStringAsFixed(2)}). Please adjust the values.'
            );
          }
          state = false;
          return;
        }
      }
      
      final expenseId = const Uuid().v4();
      String? billReference;
      if (billImage != null) {
        final bytes = await billImage.readAsBytes();
        final base64Image = base64Encode(bytes);
        await _billRepository.uploadBill(expenseId, base64Image);
        billReference = 'link:$expenseId'; // Store a lightweight link instead of full data
      }

      final expense = ExpenseModel(
        id: expenseId,
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        splits: splits,
        splitType: splitType,
        createdAt: DateTime.now(),
        billImageUrl: billReference,
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

  Future<void> deleteExpense(String expenseId, BuildContext context) async {
    state = true;
    try {
      await _expenseRepository.deleteExpense(expenseId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> updateExpense({
    required ExpenseModel oldExpense,
    required String newDescription,
    required double newAmount,
    required BuildContext context,
    File? newBillImage,
  }) async {
    state = true;
    try {
      List<ExpenseSplit> newSplits = oldExpense.splits;
      if (oldExpense.amount != newAmount && oldExpense.amount > 0) {
        if (oldExpense.splitType == SplitType.equal) {
          double splitAmount = newAmount / oldExpense.splits.length;
          newSplits = oldExpense.splits.map((s) => ExpenseSplit(userId: s.userId, amount: splitAmount)).toList();
        } else if (oldExpense.splitType == SplitType.unequal) {
          double scale = newAmount / oldExpense.amount;
          newSplits = oldExpense.splits.map((s) => ExpenseSplit(
            userId: s.userId,
            amount: s.amount * scale,
          )).toList();
        }
        // For percentage, newSplits remains the same as percentages don't change with total amount
      }

      String? billReference = oldExpense.billImageUrl;
      if (newBillImage != null) {
        final bytes = await newBillImage.readAsBytes();
        final base64Image = base64Encode(bytes);
        await _billRepository.uploadBill(oldExpense.id, base64Image);
        billReference = 'link:${oldExpense.id}';
      }

      final updatedExpense = oldExpense.copyWith(
        description: newDescription,
        amount: newAmount,
        splits: newSplits,
        billImageUrl: billReference,
      );

      await _expenseRepository.addExpense(updatedExpense);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense updated successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> settleDebt({
    required String groupId,
    required String from,
    required String to,
    required double amount,
    required BuildContext context,
  }) async {
    state = true;
    try {
      final expenseId = const Uuid().v4();
      final expense = ExpenseModel(
        id: expenseId,
        groupId: groupId,
        description: 'Settlement: $from to $to',
        amount: amount,
        paidBy: from,
        splits: [
          ExpenseSplit(userId: to, amount: amount),
        ],
        splitType: SplitType.unequal,
        createdAt: DateTime.now(),
        isVerified: false,
      );

      await _expenseRepository.addExpense(expense);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked ₹${amount.toStringAsFixed(2)} as paid to $to. Waiting for confirmation.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> verifySettlement({
    required String expenseId,
    required BuildContext context,
  }) async {
    state = true;
    try {
      await _expenseRepository.verifyExpense(expenseId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verified successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  void _showValidationError(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}
