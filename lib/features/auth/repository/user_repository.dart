import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(FirebaseFirestore.instance));

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  Future<List<UserModel>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];
    // Firestore whereIn limit is 30, for now we assume group size is small
    final snapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: uids).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }
}
