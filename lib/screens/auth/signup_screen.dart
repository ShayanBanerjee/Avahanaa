import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_rc_service.dart';
import '../../models/vehicle_details.dart';
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
  final _vehicleRcService = VehicleRcService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFetchingVehicleDetails = false;
  Map<String, dynamic>? _rcResponse;
  String? _vehicleFetchError;
  String? _lastFetchedPlate;

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

    try {
      final licensePlate = _carLicenseController.text.trim().toUpperCase();
      final vehicleDetails = _rcResponse != null
          ? VehicleDetails.fromRcResponse(_rcResponse!)
          : null;
      final assetNumber = vehicleDetails?.assetNumber.isNotEmpty == true
          ? vehicleDetails!.assetNumber
          : licensePlate;
      final carDetails = {
        'color': _carColorController.text.trim(),
        'carModel': _carModelController.text.trim(),
        'licensePlate': licensePlate,
        'assetNumber': assetNumber,
        if (vehicleDetails?.variantId != null)
          'variantId': vehicleDetails!.variantId,
        if (_rcResponse != null) 'rcResponse': _rcResponse,
      };

      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        carDetails: carDetails,
      );

      if (!mounted) return;

      try {
        await _authService.sendEmailVerification();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Navigate to verify email screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchVehicleDetails() async {
    final vehicleNumber = _carLicenseController.text.trim();
    if (vehicleNumber.isEmpty) {
      setState(() {
        _vehicleFetchError = 'Enter a registration number to fetch details';
      });
      return;
    }

    setState(() {
      _isFetchingVehicleDetails = true;
      _vehicleFetchError = null;
    });

    try {
      final rcResponse =
          await _vehicleRcService.fetchVehicleDetails(vehicleNumber);
      final details = _vehicleRcService.buildCarDetails(
        rcResponse: rcResponse,
        fallbackPlate: vehicleNumber,
      );
      _carColorController.text = (details['color'] ?? '').toString();
      _carModelController.text = (details['carModel'] ?? '').toString();
      final plate = (details['licensePlate'] ?? vehicleNumber).toString();
      final normalizedPlate = plate.trim().toUpperCase();
      _carLicenseController.text = normalizedPlate;
      _rcResponse = rcResponse;
      _lastFetchedPlate = normalizedPlate;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle details fetched')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _vehicleFetchError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingVehicleDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Sign up to get your QR code',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 32),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field (optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+1234567890',
                  ),
                ),
                const SizedBox(height: 16),

                // Registration number field
                TextFormField(
                  controller: _carLicenseController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    final normalized = value.trim().toUpperCase();
                    final shouldClearFetch =
                        _lastFetchedPlate != null &&
                            normalized != _lastFetchedPlate;
                    if (shouldClearFetch || _vehicleFetchError != null) {
                      setState(() {
                        if (shouldClearFetch) {
                          _rcResponse = null;
                          _lastFetchedPlate = null;
                        }
                        _vehicleFetchError = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Registration Number *',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    hintText: 'e.g., PB65AM0008',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your registration number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isFetchingVehicleDetails
                        ? null
                        : _fetchVehicleDetails,
                    icon: _isFetchingVehicleDetails
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      _isFetchingVehicleDetails
                          ? 'Fetching details...'
                          : 'Fetch vehicle details',
                    ),
                  ),
                ),
                if (_vehicleFetchError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _vehicleFetchError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),

                // Car color field
                TextFormField(
                  controller: _carColorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Car Color *',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your car color';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Car model field
                TextFormField(
                  controller: _carModelController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Car Model *',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                    hintText: 'e.g., Toyota Camry',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your car model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignUp(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Sign up button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isFetchingVehicleDetails
                        ? null
                        : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 24),

                // Terms text
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
