enum NotificationType {
  addedToGroup,
  newExpense,
  settlementRequest,
  invitationAccepted,
  memberRemoved,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String userId;
  final NotificationType type;
  final String groupId;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    required this.type,
    required this.groupId,
    this.read = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'userId': userId,
      'type': type.name,
      'groupId': groupId,
      'read': read,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere((e) => e.name == map['type'], orElse: () => NotificationType.newExpense),
      groupId: map['groupId'] ?? '',
      read: map['read'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}
