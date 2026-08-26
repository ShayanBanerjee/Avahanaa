import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'login_screen.dart' show AuthButtonSpinner, AuthValidators;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _authService.resetPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EntranceFade(
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    // State.context — this is a State method, not a static helper.
    final l10n = AppL10n.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthIcon(
            icon: Icons.lock_reset_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.authResetYourPassword, style: AppText.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter the email you signed up with and we will send you a link '
            'to set a new password.',
            style: AppText.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              labelText: l10n.authEmail,
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: AuthValidators.email,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              child: _isLoading
                  ? AuthButtonSpinner()
                  : Text(l10n.authSendResetLink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    // State.context — this is a State method, not a static helper.
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthIcon(
          icon: Icons.mark_email_read_rounded,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.authCheckYourEmail, style: AppText.displayMedium),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We sent password reset instructions to '
          '${_emailController.text.trim()}. The link expires in an hour.',
          style: AppText.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.authBackToSignIn),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: Text(l10n.authUseDifferentEmail),
        ),
      ],
    );
  }
}

class _AuthIcon extends StatelessWidget {
  const _AuthIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Icon(icon, size: 34, color: color),
      ),
    );
  }
}
