import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final billRepositoryProvider = Provider((ref) => BillRepository(FirebaseFirestore.instance));

class BillRepository {
  final FirebaseFirestore _firestore;

  BillRepository(this._firestore);

  Future<void> uploadBill(String expenseId, String base64Image) async {
    await _firestore.collection('expense_bills').doc(expenseId).set({
      'billData': base64Image,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getBill(String expenseId) async {
    final doc = await _firestore.collection('expense_bills').doc(expenseId).get();
    if (doc.exists) {
      return doc.data()?['billData'] as String?;
    }
    return null;
  }

  Future<void> deleteBill(String expenseId) async {
    await _firestore.collection('expense_bills').doc(expenseId).delete();
  }
}
