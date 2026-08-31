import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/vehicle_registration_validator.dart';
import '../../widgets/metal.dart';
import '../../widgets/ui_kit.dart';
import '../legal_documents_screen.dart';
import 'login_screen.dart' show AuthBrandHeader, AuthValidators;
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carColorController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carLicenseController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _carColorController.dispose();
    _carModelController.dispose();
    _carLicenseController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final licensePlate = VehicleRegistrationValidator.normalize(
        _carLicenseController.text,
      );

      final credential = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      final userId = credential?.user?.uid;
      if (userId != null) {
        final vehicle = await _firestoreService.upsertVehicle(
          userId: userId,
          vehicle: VehicleModel(
            id: '',
            userId: userId,
            color: _carColorController.text.trim(),
            carModel: _carModelController.text.trim(),
            licensePlate: licensePlate,
            assetNumber: licensePlate,
          ),
          setPrimaryIfMissing: true,
          syncLegacyUserFields: true,
        );

        final user =
            await _firestoreService.getUserData(userId) ??
            UserModel(
              id: userId,
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              notificationsEnabled: true,
              primaryVehicleId: vehicle.id,
            );

        await _firestoreService.ensureVehicleQrCode(
          user: user,
          vehicle: vehicle,
          syncLegacyUserFields: true,
        );
      }

      if (!mounted) return;

      try {
        await _authService.sendEmailVerification();
      } catch (e) {
        if (mounted) {
          showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
        }
      }

      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              VerifyEmailScreen(email: _emailController.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLegalDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocumentsScreen()),
    );
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
              title: l10n.authCreateYourAccount,
              subtitle:
                  'Two minutes, and your vehicle becomes reachable '
                  'without giving your number to anyone.',
              showLogo: false,
              onBack: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntranceFade(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            overline: 'Step 1 of 2',
                            title: l10n.authYourAccount,
                          ),
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
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.authPassword,
                              helperText: l10n.valPasswordLength,
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
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
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.authConfirmPassword,
                              prefixIcon:
                                  const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? l10n.commonShowPassword
                                    : l10n.commonHidePassword,
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.authConfirmPassword;
                              }
                              if (value != _passwordController.text) {
                                return l10n.valPasswordsDiffer;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.authPhoneOptional,
                              helperText:
                                  'For account recovery only. Never shared '
                                  'with anyone who scans your code.',
                              helperMaxLines: 2,
                              prefixIcon: Icon(Icons.phone_outlined),
                              hintText: '+91 98765 43210',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    EntranceFade(
                      delay: AppMotion.staggerFor(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            overline: 'Step 2 of 2',
                            title: l10n.authYourVehicle,
                          ),
                          TextFormField(
                            controller: _carLicenseController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            inputFormatters: [_UpperCaseFormatter()],
                            decoration: InputDecoration(
                              labelText: l10n.authRegistrationNumber,
                              prefixIcon: Icon(
                                Icons.confirmation_number_outlined,
                              ),
                              hintText: 'KA01AB1234',
                            ),
                            validator:
                                VehicleRegistrationValidator.validationError,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _carColorController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.authColour,
                              prefixIcon: Icon(Icons.palette_outlined),
                              hintText: 'White',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.valEnterColour;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _carModelController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSignUp(),
                            decoration: InputDecoration(
                              labelText: l10n.authMakeAndModel,
                              prefixIcon: Icon(Icons.directions_car_outlined),
                              hintText: 'Maruti Swift',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.valEnterModel;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _PrivacyNote(),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    MetalButton(
                      label: l10n.authCreateAccount,
                      icon: Icons.arrow_forward_rounded,
                      busy: _isLoading,
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'By creating an account you agree to our ',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _InlineLink(
                          label: l10n.legalTermsOfService,
                          onTap: _openLegalDocuments,
                        ),
                        Text(
                          ' and ',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _InlineLink(
                          label: l10n.legalPrivacyPolicy,
                          onTap: _openLegalDocuments,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.infoSurface,
      borderColor: AppColors.infoBorder,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.visibility_off_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Only your vehicle colour, model and number appear to someone '
              'who scans your code — so they know they have the right car. '
              'Your contact details never do.',
              style: AppText.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppText.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
