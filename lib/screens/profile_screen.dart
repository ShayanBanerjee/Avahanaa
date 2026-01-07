import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/vehicle_rc_service.dart';
import '../models/user_model.dart';
import '../models/vehicle_details.dart';
import 'auth/login_screen.dart';
import '../utils/qr_payload_builder.dart';
import '../services/fcm_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _vehicleRcService = VehicleRcService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _fcmService = FCMService();
  bool _isUpdatingNotificationPreference = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.streamUserData(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User data not found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color.fromARGB(255, 0, 81, 173), Color(0xFF002b5c)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.email[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (user.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Car Details Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.directions_car,
                              color: Color(0xFF2563EB)),
                          title: const Text(
                            'Car Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user.carDescription),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditCarDialog(user),
                        ),
                      ],
                    ),
                  ),
                ),

                // Account Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.phone, color: Color(0xFF2563EB)),
                          title: const Text('Phone Number'),
                          subtitle: Text(
                            user.phoneNumber.isEmpty
                                ? 'Not set'
                                : user.phoneNumber,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditPhoneDialog(user),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading:
                              const Icon(Icons.lock, color: Color(0xFF2563EB)),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showChangePasswordDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                // QR Code Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.qr_code,
                              color: Color(0xFF2563EB)),
                          title: const Text('QR Code Active'),
                          subtitle: Text(
                            _isUpdatingNotificationPreference
                                ? 'Updating...'
                                : 'Allow others to notify you',
                          ),
                          value: user.notificationsEnabled,
                          onChanged: _isUpdatingNotificationPreference
                              ? null
                              : (value) =>
                                  _handleNotificationToggle(user, value),
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<Map<String, int>>(
                    future: _firestoreService
                        .getNotificationStats(_currentUser.uid),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'today': 0, 'total': 0};

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Today',
                                stats['today'].toString(),
                                Icons.today,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _buildStatItem(
                                'Total',
                                stats['total'].toString(),
                                Icons.notifications,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Danger Zone
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading:
                          Icon(Icons.delete_forever, color: Colors.red[700]),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text('Permanently delete your account'),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _handleNotificationToggle(
      UserModel user, bool isEnabled) async {
    if (_isUpdatingNotificationPreference || _currentUser == null) return;

    setState(() {
      _isUpdatingNotificationPreference = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _firestoreService.updateUserProfile(
        userId: _currentUser!.uid,
        notificationsEnabled: isEnabled,
      );

      if (user.qrCodeId.isNotEmpty) {
        await _firestoreService.toggleQRCodeStatus(
          qrCodeId: user.qrCodeId,
          isActive: isEnabled,
        );
      }

      if (isEnabled) {
        await _fcmService.refreshFcmToken();
      } else {
        await _fcmService.deleteFCMToken();
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEnabled
                  ? 'QR code notifications enabled'
                  : 'QR code notifications disabled',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update QR code status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingNotificationPreference = false;
        });
      }
    }
  }

  void _showEditCarDialog(UserModel user) {
    final colorController = TextEditingController(
      text: user.carDetails?['color'] ?? '',
    );
    final modelController = TextEditingController(
      text: user.carDetails?['carModel'] ?? '',
    );
    final plateController = TextEditingController(
      text: user.carDetails?['licensePlate'] ?? '',
    );

    Map<String, dynamic>? rcResponse;
    final existingRcResponse = user.carDetails?['rcResponse'];
    if (existingRcResponse is Map<String, dynamic>) {
      rcResponse = existingRcResponse;
    } else if (existingRcResponse is Map) {
      rcResponse = Map<String, dynamic>.from(existingRcResponse);
    }

    bool isFetching = false;
    String? fetchError;
    String? lastFetchedPlate =
        rcResponse != null ? plateController.text.trim().toUpperCase() : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> fetchVehicleDetails() async {
            final plate = plateController.text.trim();
            if (plate.isEmpty) {
              setModalState(() {
                fetchError = 'Enter a registration number to fetch details';
              });
              return;
            }

            setModalState(() {
              isFetching = true;
              fetchError = null;
            });

            try {
              final response =
                  await _vehicleRcService.fetchVehicleDetails(plate);
              final details = _vehicleRcService.buildCarDetails(
                rcResponse: response,
                fallbackPlate: plate,
              );
              colorController.text = (details['color'] ?? '').toString();
              modelController.text = (details['carModel'] ?? '').toString();
              final normalizedPlate =
                  (details['licensePlate'] ?? plate).toString().trim().toUpperCase();
              plateController.text = normalizedPlate;
              rcResponse = response;
              lastFetchedPlate = normalizedPlate;
            } catch (e) {
              if (context.mounted) {
                setModalState(() {
                  fetchError = e.toString();
                });
              }
            } finally {
              if (context.mounted) {
                setModalState(() {
                  isFetching = false;
                });
              }
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text('Edit Car Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: plateController,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      hintText: 'e.g., PB65AM0008',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      final normalized = value.trim().toUpperCase();
                      final shouldClearFetch = lastFetchedPlate != null &&
                          normalized != lastFetchedPlate;
                      if (shouldClearFetch || fetchError != null) {
                        setModalState(() {
                          if (shouldClearFetch) {
                            rcResponse = null;
                            lastFetchedPlate = null;
                          }
                          fetchError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isFetching ? null : fetchVehicleDetails,
                      icon: isFetching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        isFetching ? 'Fetching details...' : 'Fetch vehicle details',
                      ),
                    ),
                  ),
                  if (fetchError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      fetchError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      hintText: 'e.g., Red, Blue',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'e.g., Toyota Camry',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isFetching
                    ? null
                    : () async {
                        try {
                          final updatedCarDetails =
                              Map<String, dynamic>.from(user.carDetails ?? {});
                          updatedCarDetails.remove('makeModel');
                          updatedCarDetails.remove('vehicleType');
                          updatedCarDetails['color'] =
                              colorController.text.trim();
                          updatedCarDetails['carModel'] =
                              modelController.text.trim();
                          updatedCarDetails['licensePlate'] =
                              plateController.text.trim().toUpperCase();

                          if (rcResponse != null) {
                            final vehicleDetails =
                                VehicleDetails.fromRcResponse(rcResponse!);
                            if (vehicleDetails.assetNumber.isNotEmpty) {
                              updatedCarDetails['assetNumber'] =
                                  vehicleDetails.assetNumber;
                            }
                            if (vehicleDetails.variantId != null) {
                              updatedCarDetails['variantId'] =
                                  vehicleDetails.variantId;
                            }
                            updatedCarDetails['rcResponse'] = rcResponse;
                          }

                          await _firestoreService.updateUserProfile(
                            userId: _currentUser!.uid,
                            carDetails: updatedCarDetails,
                          );

                          if (user.qrCodeId.isNotEmpty) {
                            final updatedUser =
                                user.copyWith(carDetails: updatedCarDetails);
                            await _firestoreService.syncQRCodeMetadata(
                              qrCodeId: user.qrCodeId,
                              metadata: QrPayloadBuilder.buildMetadata(updatedUser),
                              shareableLink:
                                  QrPayloadBuilder.buildShareableLink(updatedUser),
                              payload: QrPayloadBuilder.buildPayload(updatedUser),
                            );
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          Future.delayed(const Duration(seconds: 0), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Car details updated')),
                            );
                          });
                        } catch (e) {
                          if (!mounted) return;
                          Future.delayed(const Duration(seconds: 0), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          });
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPhoneDialog(UserModel user) {
    final phoneController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.updateUserProfile(
                  userId: _currentUser!.uid,
                  phoneNumber: phoneController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number updated')),
                  );
                });
              } catch (e) {
                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                // Re-authenticate first
                final credential = EmailAuthProvider.credential(
                  email: _currentUser!.email!,
                  password: currentPasswordController.text,
                );
                await _currentUser.reauthenticateWithCredential(credential);

                // Update password
                await _authService.updatePassword(
                  newPassword: newPasswordController.text,
                );

                if (!mounted) return;
                Navigator.pop(context);
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password updated successfully')),
                  );
                });
              } catch (e) {
                if (!mounted) return;
                Future.delayed(const Duration(seconds: 0), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (!mounted || password == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: password,
      );
      await _authService.deleteAccount(credential: credential);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorText = 'Please enter your password');
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text('Delete Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone. All your data including QR code and notifications will be permanently deleted.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                errorText: _errorText,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
