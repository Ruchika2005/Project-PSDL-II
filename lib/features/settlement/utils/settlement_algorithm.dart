import 'package:collection/collection.dart';

class Transaction {
  final String from;
  final String to;
  final double amount;

  Transaction({required this.from, required this.to, required this.amount});
}

class SettlementAlgorithm {
  static List<Transaction> calculateSettlements(Map<String, double> balances) {
    // Max-priority queue for creditors (those who are owed money)
    final creditors = PriorityQueue<MapEntry<String, double>>((a, b) => b.value.compareTo(a.value));
    
    // Max-priority queue for debtors (those who owe money, using absolute value)
    final debtors = PriorityQueue<MapEntry<String, double>>((a, b) => b.value.abs().compareTo(a.value.abs()));

    // Separate into debtors and creditors
    balances.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(userId, balance));
      } else if (balance > 0.01) {
        creditors.add(MapEntry(userId, balance));
      }
    });

    List<Transaction> transactions = [];

    // Greedily match largest debtor with largest creditor
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      final debtor = debtors.removeFirst();
      final creditor = creditors.removeFirst();

      final debtAmount = debtor.value.abs();
      final creditAmount = creditor.value;

      final settlementAmount = debtAmount < creditAmount ? debtAmount : creditAmount;

      transactions.add(Transaction(
        from: debtor.key,
        to: creditor.key,
        amount: settlementAmount,
      ));

      // Check if there is still debt or credit remaining
      final remainingDebt = debtAmount - settlementAmount;
      final remainingCredit = creditAmount - settlementAmount;

      if (remainingDebt > 0.01) {
        debtors.add(MapEntry(debtor.key, -remainingDebt));
      }

      if (remainingCredit > 0.01) {
        creditors.add(MapEntry(creditor.key, remainingCredit));
      }
    }

    return transactions;
  }
}
