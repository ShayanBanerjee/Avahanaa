import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    String? phoneNumber,
    Map<String, dynamic>? carDetails,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          userId: userCredential.user!.uid,
          email: email,
          phoneNumber: phoneNumber,
          carDetails: carDetails,
        );
        await _updateFcmTokenForUser(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    String? phoneNumber,
    Map<String, dynamic>? carDetails,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'phoneNumber': phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': '',
        'qrCodeId': '', // Will be set by Cloud Function trigger
        'carDetails': carDetails ?? {},
        'notificationsEnabled': true,
      });
    } catch (e) {
      log('Error creating user document: $e');
      throw 'Failed to create user profile. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _updateFcmTokenForUser(userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      final actionCodeSettings = _buildActionCodeSettings();
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (e) {
      log('Password reset failed (${e.code}): ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Password reset failed: $e');
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }
      await user.sendEmailVerification(_buildActionCodeSettings());
    } on FirebaseAuthException catch (e) {
      log('Email verification failed (${e.code}): ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Email verification failed: $e');
      throw 'Failed to send verification email. Please try again.';
    }
  }

  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      log('Reload failed (${e.code}): ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Reload failed: $e');
      throw 'Failed to refresh user. Please try again.';
    }
  }

  // Update email
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
      await _firestore.collection('users').doc(currentUser?.uid).update({
        'email': newEmail,
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update email. Please try again.';
    }
  }

  // Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update password. Please try again.';
    }
  }

  // Delete account
  Future<void> deleteAccount({AuthCredential? credential}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }

      if (credential != null) {
        await user.reauthenticateWithCredential(credential);
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final qrCodeId = userDoc.data()?['qrCodeId'];

      // Delete user document
      await userRef.delete();

      // Delete QR code document
      if (qrCodeId != null && qrCodeId.isNotEmpty) {
        await _firestore.collection('qrCodes').doc(qrCodeId).delete();
      }

      // Delete auth account
      await user.delete();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Authentication failed: ${e.message ?? "Unknown error"}';
    }
  }

  ActionCodeSettings _buildActionCodeSettings() {
    final projectId = Firebase.app().options.projectId;
    return ActionCodeSettings(
      url: 'https://$projectId.firebaseapp.com',
      handleCodeInApp: false,
    );
  }

  Future<void> _updateFcmTokenForUser(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        log('FCM token not available at login/signup');
        return;
      }
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      log('FCM token saved for user $userId');
    } catch (e) {
      log('Error updating FCM token for user $userId: $e');
    }
  }
}
