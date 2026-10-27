import 'transaction.dart';

class PersonLedger {
  final String personName;
  final double totalSent; // Total expenses paid to this person
  final double totalReceived; // Total income received from this person
  final List<TransactionModel> transactions;

  PersonLedger({
    required this.personName,
    required this.totalSent,
    required this.totalReceived,
    required this.transactions,
  });

  double get netBalance => totalReceived - totalSent;

  bool get isOwed => netBalance > 0; // The person owes money to user
  bool get owesUser => netBalance < 0; // User sent more money to this person
}
