import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hero_header.dart';
import '../../widgets/metal.dart';
import '../../widgets/ui_kit.dart';
import '../home_screen.dart';
import 'login_screen.dart' show AuthButtonSpinner, LoginScreen;

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the mail app is the most likely moment for the
    // verification to have completed, so re-check silently.
    if (state == AppLifecycleState.resumed) {
      _checkVerification(showFeedback: false);
    }
  }

  Future<void> _checkVerification({bool showFeedback = true}) async {
    if (_isChecking) return;

    setState(() => _isChecking = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final verified = await _authService.reloadAndCheckEmailVerified();
      if (!mounted) return;

      if (verified) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => HomeScreen()),
          (route) => false,
        );
        return;
      }

      if (showFeedback) {
        showAppSnackBar(
          messenger,
          'Not verified yet — check your inbox and tap the link.',
        );
      }
    } catch (e) {
      if (!mounted || !showFeedback) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      showAppSnackBar(
        messenger,
        'Verification email sent',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  /// Escape hatch.
  ///
  /// This screen is a dead end otherwise: `AuthGate` routes here for any signed
  /// in but unverified account, and there is nothing to pop back to, so the
  /// hardware back button just exits the app. Someone who mistyped their email
  /// at sign-up would be stuck here permanently, unable to reach sign-in and
  /// unable to correct the address.
  Future<void> _useDifferentEmail() async {
    final navigator = Navigator.of(context);
    await _authService.signOut();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final email = widget.email.trim();

    return Scaffold(
      body: HeroSurface(
        padding: EdgeInsets.zero,
        palette: MetalPalette.success,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EntranceFade(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.hero,
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        size: 52,
                        color: AppColors.successDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Confirm your email',
                      textAlign: TextAlign.center,
                      style: AppText.displayMedium.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'We sent a verification link to',
                      textAlign: TextAlign.center,
                      style: AppText.bodyLarge.copyWith(
                        color: AppColors.onDarkMuted,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: AppText.titleMedium.copyWith(
                          color: AppColors.onDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppColors.onDark,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'No email yet? Check your spam and promotions '
                              'folders — it often lands there.',
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.onDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.successDark,
                        ),
                        onPressed: _isChecking
                            ? null
                            : () => _checkVerification(),
                        child: _isChecking
                            ? AuthButtonSpinner(
                                color: AppColors.successDark,
                              )
                            : const Text("I've verified — continue"),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _isResending ? null : _resendVerificationEmail,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onDark,
                      ),
                      child: _isResending
                          ? AuthButtonSpinner()
                          : Text(l10n.authResendEmail),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: _useDifferentEmail,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onDarkMuted,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l10n.authUseDifferentEmail),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
