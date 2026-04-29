import 'package:flutter/material.dart';

enum RecordType { income, expense }

class RecordModel {
  final String id;
  final String title;
  final double amount;
  final RecordType type;
  final DateTime date;
  final String category;
  final String account;

  RecordModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    required this.account,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'account': account,
    };
  }

  factory RecordModel.fromMap(Map<String, dynamic> map) {
    return RecordModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: RecordType.values.firstWhere((e) => e.name == map['type']),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'] ?? '',
      account: map['account'] ?? '',
    );
  }
}
