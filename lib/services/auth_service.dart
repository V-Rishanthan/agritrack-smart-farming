import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// All Firebase Authentication + user-profile calls live here.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The signed-in user, or null if nobody is signed in.
  User? get currentUser => _auth.currentUser;

  /// Emits a new value every time the user signs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ----------- Sign in -----------
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ----------- Register -----------
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create the login account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return 'Something went wrong. Please try again.';
      }

      // 2. Store the full name on the Firebase user profile
      await user.updateDisplayName(name.trim());

      // 3. Save the extra data in Firestore -> users/{uid}
      await _saveUserProfile(user: user, name: name, email: email);

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _messageFor(e);
    } catch (e) {
      debugPrint('Register error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Writes users/{uid}. If this fails the account still exists, so we
  /// print the real error to the console instead of failing the sign-up.
  Future<void> _saveUserProfile({
    required User user,
    required String name,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': name.trim(),
        'email': email.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Look for this line in the Debug Console, e.g.
      // [cloud_firestore/permission-denied] or NOT_FOUND ... database
      debugPrint('Could not save user profile to Firestore: $e');
    }
  }

  // ----------- Sign out -----------
  Future<void> signOut() => _auth.signOut();

  /// Turns Firebase's error codes into messages a farmer can understand.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }
}
