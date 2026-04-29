import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';
import '../../../models/record_model.dart';

class FinanceRepository {
  final FirebaseFirestore _firestore;
  FinanceRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // --- ACCOUNTS ---
  Stream<List<AccountModel>> getAccounts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AccountModel.fromMap(doc.data())).toList());
  }

  Future<void> addAccount(String userId, AccountModel account) async {
    await _firestore.collection('users').doc(userId).collection('accounts').doc(account.id).set(account.toMap());
  }

  Future<void> updateAccountBalance(String userId, String accountId, double newBalance) async {
    await _firestore.collection('users').doc(userId).collection('accounts').doc(accountId).update({'balance': newBalance});
  }

  // --- CATEGORIES ---
  Stream<List<CategoryModel>> getCategories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data())).toList());
  }

  Future<void> addCategory(String userId, CategoryModel category) async {
    await _firestore.collection('users').doc(userId).collection('categories').doc(category.id).set(category.toMap());
  }

  // --- RECORDS ---
  Stream<List<RecordModel>> getRecords(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('records')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RecordModel.fromMap(doc.data())).toList());
  }

  Future<void> addRecord(String userId, RecordModel record) async {
    await _firestore.collection('users').doc(userId).collection('records').doc(record.id).set(record.toMap());
  }
}

final financeRepositoryProvider = Provider((ref) => FinanceRepository(firestore: FirebaseFirestore.instance));
