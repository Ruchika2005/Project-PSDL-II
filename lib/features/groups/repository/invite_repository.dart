import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/invite_model.dart';
import '../../../models/user_model.dart';

class InviteRepository {
  final FirebaseFirestore _firestore;
  InviteRepository(this._firestore);

  Future<UserModel?> findUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Future<void> sendInvite(InviteModel invite) async {
    await _firestore.collection('invitations').doc(invite.id).set(invite.toMap());
  }

  Stream<List<InviteModel>> getInvitesForUser(String email) {
    return _firestore
        .collection('invitations')
        .where('inviteeEmail', isEqualTo: email.toLowerCase().trim())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .where((invite) => invite.status != InviteStatus.rejected && invite.status != InviteStatus.settled)
            .toList());
  }

  Stream<List<InviteModel>> getInvitesForGroup(String groupId) {
    return _firestore
        .collection('invitations')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .where((i) => i.status != InviteStatus.rejected && i.status != InviteStatus.settled)
            .toList());
  }

  Future<void> updateInviteStatus(String inviteId, InviteStatus status) async {
    await _firestore.collection('invitations').doc(inviteId).update({'status': status.name});
  }

  Future<InviteModel?> getInviteByCode(String code) async {
    final snapshot = await _firestore
        .collection('invitations')
        .where('code', isEqualTo: code)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return InviteModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }
}

final inviteRepositoryProvider = Provider((ref) => InviteRepository(FirebaseFirestore.instance));
