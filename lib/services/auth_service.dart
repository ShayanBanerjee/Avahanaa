import '../l10n/l10n_global.dart';
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
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          userId: userCredential.user!.uid,
          email: email,
          phoneNumber: phoneNumber,
        );
        await _updateFcmTokenForUser(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw appL10n.errUnexpected;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'phoneNumber': phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': '',
        'primaryVehicleId': '',
        'notificationsEnabled': true,
      });
    } catch (e) {
      log('Error creating user document: $e');
      throw appL10n.errCreateProfile;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _updateFcmTokenForUser(userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw appL10n.errUnexpected;
    }
  }

  // Sign out
  Future<void> signOut() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _clearFcmTokenForUser(userId);
      } catch (e) {
        log('Failed to clear stored FCM token for user $userId: $e');
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      log('Failed to delete local FCM token during sign out: $e');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      throw appL10n.errSignOut;
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
      throw appL10n.errResetEmail;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw appL10n.errNoUser;
      }
      await user.sendEmailVerification(_buildActionCodeSettings());
    } on FirebaseAuthException catch (e) {
      log('Email verification failed (${e.code}): ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Email verification failed: $e');
      throw appL10n.errVerifyEmail;
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
      throw appL10n.errRefreshUser;
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
      throw appL10n.errUpdateEmail;
    }
  }

  // Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw appL10n.errUpdatePassword;
    }
  }

  // Delete account
  Future<void> deleteAccount({AuthCredential? credential}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw appL10n.errNoUser;
      }

      if (credential != null) {
        await user.reauthenticateWithCredential(credential);
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final legacyQrCodeId = (userDoc.data()?['qrCodeId'] ?? '')
          .toString()
          .trim();

      await _deleteVehiclesAndLinkedQrCodes(user.uid);
      await _deleteNotifications(user.uid);
      if (legacyQrCodeId.isNotEmpty) {
        await _firestore.collection('qrCodes').doc(legacyQrCodeId).delete();
      }

      // Delete user document
      await userRef.delete();

      // Delete auth account
      await user.delete();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw appL10n.errDeleteAccount;
    }
  }

  Future<void> _clearFcmTokenForUser(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': FieldValue.delete(),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteVehiclesAndLinkedQrCodes(String userId) async {
    final vehiclesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles');

    // A vehicle delete may include an extra linked qrCode delete. Keep ops well
    // below Firestore's 500 write batch limit.
    while (true) {
      final snapshot = await vehiclesRef.limit(200).get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final vehicleDoc in snapshot.docs) {
        final qrCodeId = (vehicleDoc.data()['qrCodeId'] ?? '')
            .toString()
            .trim();
        if (qrCodeId.isNotEmpty) {
          batch.delete(_firestore.collection('qrCodes').doc(qrCodeId));
        }
        batch.delete(vehicleDoc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteNotifications(String userId) async {
    while (true) {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(400)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final notificationDoc in snapshot.docs) {
        batch.delete(notificationDoc.reference);
      }
      await batch.commit();
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return appL10n.errWeakPassword;
      case 'email-already-in-use':
        return appL10n.errEmailInUse;
      case 'invalid-email':
        return appL10n.errInvalidEmail;
      case 'user-not-found':
        return appL10n.errUserNotFound;
      case 'wrong-password':
        return appL10n.errWrongPassword;
      case 'user-disabled':
        return appL10n.errUserDisabled;
      case 'too-many-requests':
        return appL10n.errTooManyRequests;
      case 'operation-not-allowed':
        return appL10n.errNotAllowed;
      case 'requires-recent-login':
        return appL10n.errNeedsRecentLogin;
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
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      log('FCM token saved for user $userId');
    } catch (e) {
      log('Error updating FCM token for user $userId: $e');
    }
  }
}
