import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _verificationId;

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
      return true;
    }
  }

  // Verify phone number
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('Verification failed: ${e.message}');
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // Verify OTP
  Future<User?> verifyOTP(String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      throw FirebaseAuthException(
        code: 'invalid-otp',
        message: 'Invalid OTP entered',
      );
    }
  }

  // Register
  Future<User?> registerWithUsername(
    String username,
    String password,
    String name,
    String phoneNumber,
    String? photoURL,
    String? biodata,
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
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        'biodata': biodata,
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

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(File imageFile, String uid) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$uid.jpg');
      await ref.putFile(imageFile);
      final photoURL = await ref.getDownloadURL();
      return photoURL;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  User? getCurrentUser() => _auth.currentUser;

  bool isLoggedIn() => _auth.currentUser != null;
}