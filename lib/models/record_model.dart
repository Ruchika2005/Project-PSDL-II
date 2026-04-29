import 'package:cloud_firestore/cloud_firestore.dart';
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
      'date': Timestamp.fromDate(date),
      'category': category,
      'account': account,
    };
  }

  factory RecordModel.fromMap(Map<String, dynamic> map) {
    DateTime date;
    if (map['date'] is int) {
      date = DateTime.fromMillisecondsSinceEpoch(map['date']);
    } else if (map['date'] is Timestamp) {
      date = (map['date'] as Timestamp).toDate();
    } else {
      date = DateTime.now();
    }

    return RecordModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: RecordType.values.byName(map['type'] ?? 'expense'),
      date: date,
      category: map['category'] ?? '',
      account: map['account'] ?? '',
    );
  }
}
