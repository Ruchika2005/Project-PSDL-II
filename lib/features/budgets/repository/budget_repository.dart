import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore;
  BudgetRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  Stream<List<BudgetModel>> getBudgets(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BudgetModel.fromMap(doc.data())).toList());
  }

  Future<void> addBudget(String userId, BudgetModel budget) async {
    await _firestore.collection('users').doc(userId).collection('budgets').doc(budget.id).set(budget.toMap());
  }

  Future<void> removeBudget(String userId, String budgetId) async {
    await _firestore.collection('users').doc(userId).collection('budgets').doc(budgetId).delete();
  }

  Future<void> updateBudgetSpent(String userId, String budgetId, double spent) async {
    await _firestore.collection('users').doc(userId).collection('budgets').doc(budgetId).update({'spent': spent});
  }
}

final budgetRepositoryProvider = Provider((ref) => BudgetRepository(firestore: FirebaseFirestore.instance));
