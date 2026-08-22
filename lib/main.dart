import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/fcm_service.dart';
import 'services/notification_navigation_service.dart';
import 'theme/app_theme.dart';
import 'widgets/hero_header.dart';

// Handle background messages (must be a top-level, entry-point function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    // FCM notification payloads are auto-displayed by Android in background/
    // terminated states. Show a local notification only for data-only payloads.
    if (message.notification == null) {
      await FCMService.showNotificationForMessage(message);
    }
  } catch (e, stack) {
    log(
      'Error showing background notification: $e',
      error: e,
      stackTrace: stack,
    );
  }
  log('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AdMob
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
  }

  // Initialize FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const AvahanaaApp());
}

class AvahanaaApp extends StatefulWidget {
  const AvahanaaApp({super.key});

  @override
  State<AvahanaaApp> createState() => _AvahanaaAppState();
}

class _AvahanaaAppState extends State<AvahanaaApp> {
  @override
  void initState() {
    super.initState();
    NotificationNavigationService.configureRouteFactory((notificationId) {
      return MaterialPageRoute<void>(
        builder: (_) =>
            NotificationsScreen(initialNotificationId: notificationId),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigationService.drainPending();
    });
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    final fcmService = FCMService();
    await fcmService.initialize();
    NotificationNavigationService.drainPending();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AvahanaaTheme.light();

    return MaterialApp(
      title: 'Avahanaa',
      navigatorKey: NotificationNavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: theme,
      // Light-only by design — see AvahanaaTheme.light(). Supplying the same
      // theme for dark keeps a device in dark mode from falling back to
      // Material defaults.
      darkTheme: theme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        // Clamp runaway system font scaling. Above 1.6x the alert surfaces
        // start to truncate, and a truncated alert is a failed alert.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.6,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashView();
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (!user.emailVerified) {
            return VerifyEmailScreen(email: user.email ?? '');
          }
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

/// Shown while Firebase resolves the session. Carries the brand gradient so it
/// continues the native splash rather than flashing a bare spinner.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeroSurface(
        padding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.hero),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Avahanaa',
                style: AppText.displayMedium.copyWith(
                  color: AppColors.onDark,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reachable without being reachable',
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.onDarkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onDark),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
