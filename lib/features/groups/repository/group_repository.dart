import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/group_model.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository(FirebaseFirestore.instance));

class GroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository(this._firestore);

  Future<void> createGroup(GroupModel group) async {
    await _firestore.collection('groups').doc(group.id).set(group.toMap());
  }

  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GroupModel.fromMap(doc.data())).toList());
  }

  Future<void> addMemberToGroup(String groupId, String name) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([name]),
    });
  }

  Stream<GroupModel> getGroup(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>));
  }
}
