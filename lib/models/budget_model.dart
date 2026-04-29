import 'package:flutter/material.dart';

class BudgetModel {
  final String id;
  final String categoryName;
  final double limit;
  final double spent;

  BudgetModel({
    required this.id,
    required this.categoryName,
    required this.limit,
    this.spent = 0,
  });

  BudgetModel copyWith({double? spent}) {
    return BudgetModel(
      id: id,
      categoryName: categoryName,
      limit: limit,
      spent: spent ?? this.spent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'limit': limit,
      'spent': spent,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      categoryName: map['categoryName'] ?? '',
      limit: (map['limit'] ?? 0).toDouble(),
      spent: (map['spent'] ?? 0).toDouble(),
    );
  }
}
