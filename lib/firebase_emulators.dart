/// Local Firebase emulator wiring, for development only.
///
/// Enabled with `--dart-define=USE_FIREBASE_EMULATOR=true`, which defaults to
/// false, so a release build can never accidentally point at localhost. This
/// follows the same `fromEnvironment` convention as `qr_payload_builder.dart`.
///
/// Running against emulators is the only way to exercise the signed-in screens
/// — home, alerts, profile, the sticker studio — without touching production
/// data or a real account.
///
///     firebase emulators:start --project congestion-free \
///       --only auth,firestore
///     flutter run --dart-define=USE_FIREBASE_EMULATOR=true \
///       --dart-define=DEV_SIGNIN_EMAIL=demo@avahanaa.test \
///       --dart-define=DEV_SIGNIN_PASSWORD=...
library;

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Whether this build talks to local emulators instead of the real project.
const bool kUseFirebaseEmulator = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
);

const String _defaultHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  // The Android emulator reaches the host machine through 10.0.2.2, not
  // localhost — localhost inside the guest is the guest itself.
  defaultValue: '',
);

const int _authPort = int.fromEnvironment(
  'FIREBASE_AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);

const int _firestorePort = int.fromEnvironment(
  'FIREBASE_FIRESTORE_EMULATOR_PORT',
  defaultValue: 8080,
);

String get _host {
  if (_defaultHost.isNotEmpty) return _defaultHost;
  if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}

/// Points Auth and Firestore at the local emulators. A no-op unless
/// [kUseFirebaseEmulator] is set.
Future<void> connectToFirebaseEmulatorsIfEnabled() async {
  if (!kUseFirebaseEmulator) return;

  // Belt and braces: never let this run in a release binary even if the
  // define is somehow set.
  if (kReleaseMode) {
    debugPrint('Refusing to use Firebase emulators in a release build.');
    return;
  }

  final host = _host;
  await FirebaseAuth.instance.useAuthEmulator(host, _authPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, _firestorePort);
  debugPrint(
    'Firebase emulators: auth $host:$_authPort, firestore $host:$_firestorePort',
  );
}

const String _devEmail = String.fromEnvironment('DEV_SIGNIN_EMAIL');
const String _devPassword = String.fromEnvironment('DEV_SIGNIN_PASSWORD');

/// Signs in a seeded emulator fixture account so the signed-in screens can be
/// exercised without hand-driving the login form.
///
/// Only ever runs against the emulators, never in release, and does nothing
/// unless both defines are supplied. The credentials this reads belong to a
/// throwaway sandbox account that exists only inside the local emulator — it
/// is fixture data, not a real identity.
Future<void> signInDevFixtureUserIfEnabled() async {
  if (!kUseFirebaseEmulator || kReleaseMode) return;
  if (_devEmail.isEmpty || _devPassword.isEmpty) return;
  if (FirebaseAuth.instance.currentUser != null) return;

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _devEmail,
      password: _devPassword,
    );
    debugPrint('Signed in emulator fixture user: $_devEmail');
  } catch (e) {
    debugPrint('Dev fixture sign-in failed: $e');
  }
}
