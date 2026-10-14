import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Saves and reads tractor expenses in Firestore.
///
/// Where the data lives:
///   users/{uid}/expenses/{expenseId}
/// Every signed-in user gets their own private "expenses" list.
class ExpenseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _expensesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('expenses');
  }

  // ----------- Read (live) -----------

  Stream<List<Map<String, dynamic>>> watchExpenses() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(<Map<String, dynamic>>[]);

    return _expensesRef(user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return <String, dynamic>{
              'id': doc.id,
              'name': (data['name'] as String?) ?? '',
              'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
              'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'notes': (data['notes'] as String?) ?? '',
              'type': (data['type'] as String?) ?? 'other',
            };
          }).toList(),
        );
  }

  // ----------- Save -----------
  /// Returns null when saved, or a readable error message.
  /// type is one of: 'fuel', 'service', 'spares', 'other'
  Future<String?> addExpense({
    required String name,
    required double amount,
    required DateTime date,
    required String notes,
    required String type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';

    try {
      // .add() creates the document with an automatic unique id
      await _expensesRef(user.uid).add({
        'name': name.trim(),
        'amount': amount, // a number, so you can add them up later
        'date': Timestamp.fromDate(date),
        'notes': notes.trim(),
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // success
    } on FirebaseException catch (e) {
      debugPrint('Could not save expense: [${e.code}] ${e.message}');
      if (e.code == 'permission-denied') {
        return 'No permission to save. Check your Firestore rules.';
      }
      return 'Could not save the expense (${e.code}).';
    } catch (e) {
      debugPrint('Could not save expense: $e');
      return 'Something went wrong. Please try again.';
    }
  }
}
