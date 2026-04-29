enum SplitType { equal, unequal, percentage }

class ExpenseSplit {
  final String userId;
  final double amount;

  ExpenseSplit({required this.userId, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      userId: map['userId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy; // User ID
  final List<ExpenseSplit> splits;
  final SplitType splitType;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splits,
    required this.splitType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splits': splits.map((x) => x.toMap()).toList(),
      'splitType': splitType.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      description: map['description'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      paidBy: map['paidBy'] ?? '',
      splits: List<ExpenseSplit>.from(map['splits']?.map((x) => ExpenseSplit.fromMap(x)) ?? []),
      splitType: SplitType.values.firstWhere((e) => e.name == map['splitType'], orElse: () => SplitType.equal),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
