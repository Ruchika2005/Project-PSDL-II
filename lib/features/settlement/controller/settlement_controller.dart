import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/expense_model.dart';
import '../utils/settlement_algorithm.dart';
import '../../expenses/controller/expense_controller.dart';

final settlementProvider = Provider.family<List<Transaction>, String>((ref, groupId) {
  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  
  return expensesAsync.maybeWhen(
    data: (expenses) {
      Map<String, double> balances = {};
      
      for (var expense in expenses) {
        // Add full amount to the payer
        balances[expense.paidBy] = (balances[expense.paidBy] ?? 0.0) + expense.amount;
        
        // Subtract split amounts from everyone involved
        for (var split in expense.splits) {
          double splitAmount = split.amount;
          if (expense.splitType == SplitType.percentage) {
            splitAmount = (expense.amount * split.amount) / 100;
          }
          balances[split.userId] = (balances[split.userId] ?? 0.0) - splitAmount;
        }
      }
      
      return SettlementAlgorithm.calculateSettlements(balances);
    },
    orElse: () => [],
  );
});
