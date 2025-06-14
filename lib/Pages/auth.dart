import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if username already exists
  Future<bool> _usernameExists(String username) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Username check error: $e');
      return true; // Fail safe
    }
  }

  // Register with username instead of email
  Future<User?> registerWithUsername(
    String username,
    String password,
    String name,
  ) async {
    try {
      if (await _usernameExists(username)) {
        throw FirebaseAuthException(
          code: 'username-taken',
          message: 'This username is already taken',
        );
      }

      final domain = _auth.app.options.projectId;
      final uniqueEmail = '${username.toLowerCase()}@$domain.com';

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: uniqueEmail,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'username': username.toLowerCase(),
        'email': uniqueEmail,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'isApproved': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Registration error: $e');
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // Sign in using username and password
  Future<User?> signInWithUsername(String username, String password) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with that username.',
        );
      }

      final userData = snapshot.docs.first.data();
      final email = userData['email'] as String?;

      if (email == null) {
        throw FirebaseAuthException(
          code: 'invalid-data',
          message: 'Invalid account information.',
        );
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore
          .collection('users')
          .doc(credential.user?.uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});

      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error [${e.code}]: ${e.message}');
      if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Wrong username or password',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      throw FirebaseAuthException(
        code: 'login-error',
        message: 'An error occurred during login.',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Fetch user data error: $e');
      return null;
    }
  }

  // Get current FirebaseAuth user
  User? getCurrentUser() => _auth.currentUser;

  // Is a user currently logged in
  bool isLoggedIn() => _auth.currentUser != null;
}
