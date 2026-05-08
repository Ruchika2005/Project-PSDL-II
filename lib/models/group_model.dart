class GroupModel {
  final String id;
  final String name;
  final List<String> members; // User IDs
  final String createdBy; // User ID

  GroupModel({
    required this.id,
    required this.name,
    required this.members,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'createdBy': createdBy,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdBy: map['createdBy'] ?? '',
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    List<String>? members,
    String? createdBy,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
