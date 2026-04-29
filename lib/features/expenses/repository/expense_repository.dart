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

  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data())).toList());
  }
}
