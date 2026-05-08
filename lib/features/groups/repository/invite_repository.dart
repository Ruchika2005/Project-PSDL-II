import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/invite_model.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/phone_utils.dart';

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

  Future<UserModel?> findUserByPhoneNumber(String phoneNumber) async {
    final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
    final snapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
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
            .where((invite) => invite.status == InviteStatus.pending)
            .toList());
  }

  Stream<List<InviteModel>> getInvitesForPhone(String phoneNumber) {
    final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
    return _firestore
        .collection('invitations')
        .where('inviteePhone', isEqualTo: normalizedPhone)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .where((invite) => invite.status == InviteStatus.pending)
            .toList());
  }

  Stream<List<InviteModel>> getInvitesForGroup(String groupId) {
    return _firestore
        .collection('invitations')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InviteModel.fromMap(doc.data()))
            .where((i) => i.status == InviteStatus.pending)
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

  Future<void> deleteInvite(String inviteId) async {
    await _firestore.collection('invitations').doc(inviteId).delete();
  }
}

final inviteRepositoryProvider = Provider((ref) => InviteRepository(FirebaseFirestore.instance));
