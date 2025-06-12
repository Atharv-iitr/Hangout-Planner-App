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
      return true; // Fail safe - assume username exists
    }
  }

  // Register with username instead of email
  Future<User?> registerWithUsername(
    String username,
    String password,
    String name,
  ) async {
    try {
      // Validate username availability
      if (await _usernameExists(username)) {
        throw FirebaseAuthException(
          code: 'username-taken',
          message: 'This username is already taken',
        );
      }

      // Create a unique email for Firebase Auth
      final domain = _auth.app.options.projectId;
      final uniqueEmail = '${username.toLowerCase()}@$domain.com';

      // 1. Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: uniqueEmail,
        password: password,
      );

      // 2. Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'username': username.toLowerCase(),
        'email': uniqueEmail, // Stored for reference
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'isApproved': true, // Set to false if you need admin approval
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow; // Let the UI handle specific auth errors
    } catch (e) {
      debugPrint('Registration Error: $e');
      throw FirebaseAuthException(
        code: 'registration-error',
        message: 'Registration failed. Please try again.',
      );
    }
  }

  // Sign in with username
  Future<User?> signInWithUsername(String username, String password) async {
    try {
      // 1. Look up the email associated with this username
      final userSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found with this username',
        );
      }

      final userData = userSnapshot.docs.first.data();
      final email = userData['email'] as String?;

      if (email == null) {
        throw FirebaseAuthException(
          code: 'invalid-account',
          message: 'Account data is corrupted',
        );
      }

      // 2. Sign in with email/password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Update last login time
      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed. Please try again.',
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
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current auth user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
