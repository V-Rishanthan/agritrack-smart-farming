// Saves land-owner records to Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';

class LandOwner {
  final String id;
  final String fullName;
  final double totalAcres;
  final DateTime flowingDate;
  final List<String> shifts;
  final double ratePerAcre;
  final double advanceAmount;
  final double totalAmount;
  final double balanceDue;
  final String status; // 'pending' | 'cleared'
  final DateTime? createdAt;

  // UI helpers (you can expand these later)
  bool get isVerified => false; // not stored yet
  String get plot => '—'; // not stored yet
  String get dateFormatted {
    // simple formatter – replace with intl if you prefer
    final d = flowingDate;
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get advancePaidFormatted => 'LKR ${_format(advanceAmount)}';
  String get totalYieldFeeFormatted => 'LKR ${_format(totalAmount)}';
  String get settlementAmountFormatted => 'LKR ${_format(balanceDue)}';

  SettlementStatus get settlementStatus =>
      status == 'cleared' ? SettlementStatus.cleared : SettlementStatus.pending;

  LandOwner({
    required this.id,
    required this.fullName,
    required this.totalAcres,
    required this.flowingDate,
    required this.shifts,
    required this.ratePerAcre,
    required this.advanceAmount,
    required this.totalAmount,
    required this.balanceDue,
    required this.status,
    this.createdAt,
  });

  factory LandOwner.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LandOwner(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      totalAcres: (data['totalAcres'] as num?)?.toDouble() ?? 0,
      flowingDate:
          (data['flowingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shifts: List<String>.from(data['shifts'] ?? []),
      ratePerAcre: (data['ratePerAcre'] as num?)?.toDouble() ?? 0,
      advanceAmount: (data['advanceAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      balanceDue: (data['balanceDue'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _format(double amount) {
    final whole = amount.toInt().toString();
    if (whole.length <= 3) return whole;
    final lastThree = whole.substring(whole.length - 3);
    final rest = whole.substring(0, whole.length - 3);
    final withCommas = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas,$lastThree';
  }
}

enum SettlementStatus { pending, cleared }

class OwnerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ownersRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('owners');
  }

  /// Real-time stream of all owners for the signed-in user
  Stream<List<LandOwner>> watchOwners() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _ownersRef(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LandOwner.fromFirestore).toList());
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
