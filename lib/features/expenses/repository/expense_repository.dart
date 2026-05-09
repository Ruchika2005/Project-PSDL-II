import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/expense_model.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository(FirebaseFirestore.instance));

class ExpenseRepository {
  final FirebaseFirestore _firestore;

  ExpenseRepository(this._firestore);

  Future<void> addExpense(ExpenseModel expense) async {
    await _firestore.collection('expenses').doc(expense.id).set(expense.toMap());
  }

  Future<void> verifyExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).update({'isVerified': true});
  }

  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data())).toList();
          // Sort in memory to avoid needing a Firestore composite index
          expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return expenses;
        });
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }
}
