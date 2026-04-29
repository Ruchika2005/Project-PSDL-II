import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';
import '../../../models/record_model.dart';
import '../../../models/budget_model.dart';
import 'package:uuid/uuid.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/controller/auth_controller.dart';
import '../../budgets/controller/budget_controller.dart';
import '../../budgets/repository/budget_repository.dart';
import '../repository/finance_repository.dart';

// --- STREAMS ---
final accountsProvider = StreamProvider<List<AccountModel>>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(financeRepositoryProvider).getAccounts(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(financeRepositoryProvider).getCategories(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final recordsProvider = StreamProvider<List<RecordModel>>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(financeRepositoryProvider).getRecords(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// --- CONTROLLERS ---

class AccountsController extends Notifier<bool> {
  late FinanceRepository _repo;

  @override
  bool build() {
    _repo = ref.watch(financeRepositoryProvider);
    return false;
  }

  Future<void> addAccount(String name, double initialBalance) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final account = AccountModel(
      id: const Uuid().v4(),
      name: name,
      balance: initialBalance,
      icon: Icons.account_balance_wallet_outlined,
    );
    await _repo.addAccount(userId, account);
  }

  Future<void> updateBalance(String accountId, double amount, RecordType type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final accounts = ref.read(accountsProvider).value;
    if (accounts == null) return; // Should not happen as we watch it in UI
    
    final acc = accounts.firstWhere((a) => a.id == accountId);
    double newBalance = type == RecordType.income ? acc.balance + amount : acc.balance - amount;
    
    await _repo.updateAccountBalance(userId, accountId, newBalance);
  }

  Future<void> ensureDefaultAccounts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final accounts = await ref.read(accountsProvider.future);
    if (accounts.isEmpty) {
      await addAccount('Cash', 0);
      await addAccount('Bank', 0);
    }
  }
}

final accountsControllerProvider = NotifierProvider<AccountsController, bool>(AccountsController.new);

class CategoriesController extends Notifier<bool> {
  late FinanceRepository _repo;

  @override
  bool build() {
    _repo = ref.watch(financeRepositoryProvider);
    return false;
  }

  Future<void> addCategory(String name, CategoryType type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final category = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      icon: Icons.category,
      color: Colors.teal,
      type: type,
    );
    await _repo.addCategory(userId, category);
  }

  Future<void> ensureDefaultCategories() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final categories = await ref.read(categoriesProvider.future);
    if (categories.isEmpty) {
      final defaults = [
        CategoryModel(id: '1', name: 'Food', icon: Icons.restaurant, color: Colors.orange, type: CategoryType.expense),
        CategoryModel(id: '2', name: 'Transport', icon: Icons.directions_bus, color: Colors.blue, type: CategoryType.expense),
        CategoryModel(id: '3', name: 'Shopping', icon: Icons.shopping_bag, color: Colors.pink, type: CategoryType.expense),
        CategoryModel(id: '4', name: 'Salary', icon: Icons.work, color: Colors.green, type: CategoryType.income),
      ];
      for (var cat in defaults) {
        await _repo.addCategory(userId, cat);
      }
    }
  }
}

final categoriesControllerProvider = NotifierProvider<CategoriesController, bool>(CategoriesController.new);

class RecordsController extends Notifier<bool> {
  late FinanceRepository _repo;

  @override
  bool build() {
    _repo = ref.watch(financeRepositoryProvider);
    return false;
  }

  Future<void> addRecord({
    required String title,
    required double amount,
    required RecordType type,
    required String categoryId,
    required String accountId,
    required BuildContext context,
    DateTime? date,
  }) async {
    state = true;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final categories = ref.read(categoriesProvider).value ?? [];
      final accounts = ref.read(accountsProvider).value ?? [];
      
      final category = categories.firstWhere((c) => c.id == categoryId, orElse: () => throw Exception('Category not found'));
      final account = accounts.firstWhere((a) => a.id == accountId, orElse: () => throw Exception('Account not found'));

      // Check for insufficient balance if it's an expense
      if (type == RecordType.expense && account.balance < amount) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Balance'),
              content: Text('You do not have enough balance in ${account.name}.\n\nCurrent Balance: ₹${account.balance.toStringAsFixed(2)}\nExpense Amount: ₹${amount.toStringAsFixed(2)}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        state = false;
        return;
      }

      final record = RecordModel(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        type: type,
        date: date ?? DateTime.now(),
        category: category.name,
        account: account.name,
      );

      await _repo.addRecord(userId, record);
      await ref.read(accountsControllerProvider.notifier).updateBalance(accountId, amount, type);
      
      // Update Budget spent field in Firestore
      if (type == RecordType.expense) {
        try {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            // Fetch latest budgets directly from repo to be 100% sure
            final budgets = await ref.read(budgetRepositoryProvider).getBudgets(userId).first;
            
            final now = DateTime.now();
            final recordDate = date ?? now;
            final budget = budgets.where((b) => b.categoryName.toLowerCase() == category.name.toLowerCase()).firstOrNull;
            
            // ONLY update the Firestore spent field if the record is for the CURRENT month/year
            if (budget != null && recordDate.month == now.month && recordDate.year == now.year) {
              final newSpent = (budget.spent) + amount;
              await ref.read(budgetRepositoryProvider).updateBudgetSpent(userId, budget.id, newSpent);
              debugPrint('SUCCESS: Current month budget updated in Firestore for ${category.name}. New Spent: $newSpent');
            } else if (budget != null) {
              debugPrint('INFO: Past/Future month record added. Not updating current month budget in Firestore.');
            } else {
              debugPrint('INFO: No budget found for category: ${category.name}');
            }
          }
        } catch (e) {
          debugPrint('ERROR: Budget sync failed: $e');
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
    state = false;
  }

  Future<void> resetAllData(BuildContext context) async {
    state = true;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _repo.deleteAllUserData(userId);
      
      // Re-initialize default data
      await ref.read(accountsControllerProvider.notifier).ensureDefaultAccounts();
      await ref.read(categoriesControllerProvider.notifier).ensureDefaultCategories();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been reset successfully!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
      }
    }
    state = false;
  }
}

final recordsControllerProvider = NotifierProvider<RecordsController, bool>(RecordsController.new);
