class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String profilePhoto;
  final DateTime createdAt;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profilePhoto = '',
    required this.createdAt,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhoto': profilePhoto,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePhoto: map['profilePhoto'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      fcmToken: map['fcmToken'],
    );
  }
}
