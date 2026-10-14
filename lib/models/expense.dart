import 'package:cloud_firestore/cloud_firestore.dart';

/// The four tiles on the "Log Tractor Expense" form.
enum ExpenseType { fuel, service, spares, other }

/// The filter chips on the Expenses screen.
/// (Service and Spares both count as "maintenance" in the ledger.)
enum ExpenseCategory { all, fuel, maintenance, other }

/// One expense, as saved by ExpenseService.addExpense().
/// Lives in Firestore at users/{uid}/expenses/{id}.
class Expense {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final String notes;
  final ExpenseType type;

  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.notes,
    required this.type,
  });

  /// Turns a Firestore document into an Expense.
  /// Every field has a safe fallback, so one bad document can't crash the list.
  factory Expense.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return Expense(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: (data['notes'] as String?) ?? '',
      type: ExpenseType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ExpenseType.other,
      ),
    );
  }

  /// Which ledger filter chip this expense belongs to.
  ExpenseCategory get category => switch (type) {
    ExpenseType.fuel => ExpenseCategory.fuel,
    ExpenseType.service || ExpenseType.spares => ExpenseCategory.maintenance,
    ExpenseType.other => ExpenseCategory.other,
  };

  /// e.g. "Nov 15, 2026"
  String get dateLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
