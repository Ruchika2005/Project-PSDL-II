import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/budget_model.dart';
import '../../finance/controller/finance_controller.dart';
import '../../../models/record_model.dart';
import 'package:uuid/uuid.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../repository/budget_repository.dart';

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(budgetRepositoryProvider).getBudgets(userId);
});

class BudgetsController extends Notifier<bool> {
  late BudgetRepository _repo;

  @override
  bool build() {
    _repo = ref.watch(budgetRepositoryProvider);
    return false;
  }

  Future<void> addBudget(String categoryName, double limit) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final budget = BudgetModel(id: const Uuid().v4(), categoryName: categoryName, limit: limit);
    await _repo.addBudget(userId, budget);
  }

  Future<void> removeBudget(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await _repo.removeBudget(userId, id);
  }
}

final budgetsControllerProvider = NotifierProvider<BudgetsController, bool>(BudgetsController.new);

// A provider that calculates the current spent amount for each budget
final budgetsWithProgressProvider = Provider<List<BudgetModel>>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final recordsAsync = ref.watch(recordsProvider);
  
  return budgetsAsync.when(
    data: (budgets) {
      return recordsAsync.when(
        data: (records) {
          return budgets.map((budget) {
            final spent = records
                .where((r) => r.type == RecordType.expense && r.category == budget.categoryName)
                .fold(0.0, (sum, r) => sum + r.amount);
            
            return budget.copyWith(spent: spent);
          }).toList();
        },
        loading: () => budgets,
        error: (_, __) => budgets,
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
