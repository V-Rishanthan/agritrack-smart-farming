// Saves land-owner records to Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';

class OwnerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ownersRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('owners');
  }

  Future<String?> addOwner({
    required String fullName,
    required double totalAcres,
    required DateTime flowingDate,
    required List<String> shifts,
    required double ratePerAcre,
    required double advanceAmount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';

    // Same maths as the "Automated Ledger Computation" box on the form
    final totalAmount = totalAcres * ratePerAcre;
    final balanceDue = totalAmount - advanceAmount;

    try {
      // creates the document with an automatic unique id
      await _ownersRef(user.uid).add({
        'fullName': fullName.trim(),
        'totalAcres':
            totalAcres, // numbers stay numbers, so you can sum them later
        'flowingDate': Timestamp.fromDate(flowingDate),
        'shifts': shifts, // e.g. ['Shift 1', 'Shift 2']
        'ratePerAcre': ratePerAcre,
        'advanceAmount': advanceAmount,
        'totalAmount': totalAmount,
        'balanceDue': balanceDue,
        'status': balanceDue > 0 ? 'pending' : 'cleared',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // success
    } on FirebaseException catch (e) {
      debugPrint('Could not save owner: [${e.code}] ${e.message}');
      if (e.code == 'permission-denied') {
        return 'No permission to save. Check your Firestore rules.';
      }

      return 'Could not save the owner (${e.code}).';
    } catch (e) {
      debugPrint('Could not save owner: $e');
      return 'Something went wrong. Please try again.';
    }
  }
}
