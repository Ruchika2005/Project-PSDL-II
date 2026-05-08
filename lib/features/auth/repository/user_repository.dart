import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/phone_utils.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(FirebaseFirestore.instance));

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _firestore.collection('users').where('email', isEqualTo: email.toLowerCase().trim()).limit(1).get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
    final query = await _firestore.collection('users').where('phoneNumber', isEqualTo: normalizedPhone).limit(1).get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  Future<List<UserModel>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];
    final snapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: uids).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> updateProfilePhoto(String uid, String photoUrl) async {
    await _firestore.collection('users').doc(uid).update({'profilePhoto': photoUrl});
  }
}
