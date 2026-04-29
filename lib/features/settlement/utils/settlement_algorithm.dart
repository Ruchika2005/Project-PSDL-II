class Transaction {
  final String from;
  final String to;
  final double amount;

  Transaction({required this.from, required this.to, required this.amount});
}

class SettlementAlgorithm {
  static List<Transaction> calculateSettlements(Map<String, double> balances) {
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    // Separate into debtors (negative balance) and creditors (positive balance)
    balances.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(userId, balance)); // Owe money
      } else if (balance > 0.01) {
        creditors.add(MapEntry(userId, balance)); // Owed money
      }
    });

    // Sort to optimize: largest debtor matched with largest creditor
    debtors.sort((a, b) => a.value.compareTo(b.value)); // Most negative first
    creditors.sort((a, b) => b.value.compareTo(a.value)); // Most positive first

    List<Transaction> transactions = [];
    int i = 0; // Debtors index
    int j = 0; // Creditors index

    while (i < debtors.length && j < creditors.length) {
      String debtorId = debtors[i].key;
      double debtAmount = -debtors[i].value;

      String creditorId = creditors[j].key;
      double creditAmount = creditors[j].value;

      double settlementAmount = debtAmount < creditAmount ? debtAmount : creditAmount;

      transactions.add(Transaction(
        from: debtorId,
        to: creditorId,
        amount: settlementAmount,
      ));

      // Update remaining balances
      double remainingDebt = debtAmount - settlementAmount;
      double remainingCredit = creditAmount - settlementAmount;

      if (remainingDebt < 0.01) {
        i++; // Debtor is fully settled
      } else {
        debtors[i] = MapEntry(debtorId, -remainingDebt);
      }

      if (remainingCredit < 0.01) {
        j++; // Creditor is fully settled
      } else {
        creditors[j] = MapEntry(creditorId, remainingCredit);
      }
    }

    return transactions;
  }
}
