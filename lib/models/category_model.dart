import 'package:flutter/material.dart';

enum CategoryType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.toARGB32(),
      'type': type.name,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: IconData(map['icon'] ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] ?? Colors.teal.toARGB32()),
      type: CategoryType.values.firstWhere((e) => e.name == map['type']),
    );
  }
}
