import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_global.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hero_header.dart';
import '../../widgets/metal.dart';
import '../../widgets/ui_kit.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final userCredential = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = userCredential?.user;
      if (user != null && !user.emailVerified) {
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => VerifyEmailScreen(
              email: user.email ?? _emailController.text.trim(),
            ),
          ),
        );
        return;
      }

      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthBrandHeader(
              title: l10n.authWelcomeBack,
              subtitle: l10n.authSignInBlurb,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EntranceFade(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.authEmail,
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: AuthValidators.email,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: l10n.authPassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? l10n.commonShowPassword
                                : l10n.commonHidePassword,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: AuthValidators.password,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(l10n.authForgotPassword),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      MetalButton(
                        label: l10n.authSignIn,
                        icon: Icons.lock_open_rounded,
                        busy: _isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New to Avahanaa?",
                            style: AppText.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(l10n.authCreateAnAccount),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared auth chrome
// ---------------------------------------------------------------------------

/// Brand gradient panel used at the top of every unauthenticated screen, so
/// sign-in, sign-up and password reset read as one flow.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final bool showLogo;

  /// When set, a back control is laid out *above* the title. It is part of the
  /// column rather than stacked over it, so it can never overlap the heading.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return HeroSurface(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.hero),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        onBack == null ? AppSpacing.xl : AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.onDark,
                  onPressed: onBack,
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (showLogo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text(
              title,
              style: AppText.displayMedium.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppText.bodyLarge.copyWith(color: AppColors.onDarkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthButtonSpinner extends StatelessWidget {
  const AuthButtonSpinner({super.key, this.color = AppColors.onDark});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

abstract final class AuthValidators {
  static String? email(String? value) {
    final l10n = appL10n;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.valEnterEmail;
    // Deliberately loose — Firebase is the real authority on deliverability.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return l10n.valInvalidEmail;
    }
    return null;
  }

  static String? password(String? value) {
    final l10n = appL10n;
    final text = value ?? '';
    if (text.isEmpty) return l10n.valEnterPassword;
    if (text.length < 6) return l10n.valPasswordLength;
    return null;
  }
}
