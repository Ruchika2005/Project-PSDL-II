import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/notification_model.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository(FirebaseFirestore.instance));

class NotificationRepository {
  final FirebaseFirestore _firestore;
  NotificationRepository(this._firestore);

  Future<void> sendNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'read': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
