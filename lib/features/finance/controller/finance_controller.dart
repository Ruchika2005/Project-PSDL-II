import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';
import '../../../models/record_model.dart';
import 'package:uuid/uuid.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../repository/finance_repository.dart';

// --- STREAMS ---
final accountsProvider = StreamProvider<List<AccountModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(financeRepositoryProvider).getAccounts(userId);
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(financeRepositoryProvider).getCategories(userId);
});

final recordsProvider = StreamProvider<List<RecordModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(financeRepositoryProvider).getRecords(userId);
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

    final accounts = await ref.read(accountsProvider.future);
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

  Future<void> addRecord(String title, double amount, RecordType type, String categoryId, String accountId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final categories = await ref.read(categoriesProvider.future);
    final accounts = await ref.read(accountsProvider.future);
    
    final category = categories.firstWhere((c) => c.id == categoryId);
    final account = accounts.firstWhere((a) => a.id == accountId);

    final record = RecordModel(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      date: DateTime.now(),
      category: category.name,
      account: account.name,
    );

    await _repo.addRecord(userId, record);
    await ref.read(accountsControllerProvider.notifier).updateBalance(accountId, amount, type);
  }
}

final recordsControllerProvider = NotifierProvider<RecordsController, bool>(RecordsController.new);
