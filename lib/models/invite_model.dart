import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus { pending, accepted, rejected, settled }

class InviteModel {
  final String id;
  final String groupId;
  final String groupName;
  final String creatorName;
  final String creatorId;
  final String inviteeEmail;
  final String inviteeName;
  final String code;
  final double moneyOwed;
  final DateTime createdAt;
  final InviteStatus status;

  InviteModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.creatorName,
    required this.creatorId,
    required this.inviteeEmail,
    required this.inviteeName,
    required this.code,
    this.moneyOwed = 0.0,
    required this.createdAt,
    this.status = InviteStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'creatorName': creatorName,
      'creatorId': creatorId,
      'inviteeEmail': inviteeEmail,
      'inviteeName': inviteeName,
      'code': code,
      'moneyOwed': moneyOwed,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorId: map['creatorId'] ?? '',
      inviteeEmail: map['inviteeEmail'] ?? '',
      inviteeName: map['inviteeName'] ?? '',
      code: map['code'] ?? '',
      moneyOwed: (map['moneyOwed'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      status: InviteStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => InviteStatus.pending),
    );
  }

  InviteModel copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? creatorName,
    String? creatorId,
    String? inviteeEmail,
    String? inviteeName,
    String? code,
    double? moneyOwed,
    DateTime? createdAt,
    InviteStatus? status,
  }) {
    return InviteModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      creatorName: creatorName ?? this.creatorName,
      creatorId: creatorId ?? this.creatorId,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      inviteeName: inviteeName ?? this.inviteeName,
      code: code ?? this.code,
      moneyOwed: moneyOwed ?? this.moneyOwed,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
