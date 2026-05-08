import 'package:flutter/material.dart';

class AccountModel {
  final String id;
  final String name;
  double balance;
  final IconData icon;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'icon': icon.codePoint,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      icon: IconData(map['icon'] ?? Icons.account_balance.codePoint, fontFamily: 'MaterialIcons'),
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    double? balance,
    IconData? icon,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
    );
  }
}
