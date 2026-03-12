import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/firestore_service.dart';
import '../utils/vehicle_registration_validator.dart';
import '../widgets/admob_banner.dart';
import 'auth/login_screen.dart';
import 'legal_documents_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _firestoreService.streamUserData(_currentUser!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = userSnapshot.data;
                if (user == null) {
                  return const Center(child: Text('User data not found'));
                }

                return StreamBuilder<List<VehicleModel>>(
                  stream: _firestoreService.streamUserVehicles(user.id),
                  builder: (context, vehiclesSnapshot) {
                    final vehicles =
                        vehiclesSnapshot.data ?? const <VehicleModel>[];

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Profile Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 0, 81, 173),
                                  Color(0xFF002b5c),
                                ],
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

                          // Vehicles Section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: const Text(
                                      'Vehicles',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      vehicles.isEmpty
                                          ? 'No vehicles added'
                                          : '${vehicles.length} vehicle${vehicles.length == 1 ? '' : 's'}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add),
                                      tooltip: 'Add Vehicle',
                                      onPressed: () =>
                                          _showAddVehicleDialog(user),
                                    ),
                                  ),
                                  if (vehicles.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: Text(
                                        'Add a vehicle to generate and manage QR codes.',
                                      ),
                                    ),
                                  for (int i = 0; i < vehicles.length; i++) ...[
                                    if (i > 0) const Divider(height: 1),
                                    _buildVehicleTile(user, vehicles[i]),
                                  ],
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
                                    leading: const Icon(
                                      Icons.phone,
                                      color: Color(0xFF2563EB),
                                    ),
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
                                    leading: const Icon(
                                      Icons.lock,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: const Text('Change Password'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: _showChangePasswordDialog,
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.privacy_tip_outlined,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: const Text('Legal & Privacy'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const LegalDocumentsScreen(),
                                        ),
                                      );
                                    },
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
                                    secondary: const Icon(
                                      Icons.qr_code,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: const Text('QR Code Active'),
                                    subtitle: Text(
                                      _isUpdatingNotificationPreference
                                          ? 'Updating...'
                                          : 'Allow others to notify you across all vehicles',
                                    ),
                                    value: user.notificationsEnabled,
                                    onChanged: _isUpdatingNotificationPreference
                                        ? null
                                        : (value) => _handleNotificationToggle(
                                            vehicles,
                                            value,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Statistics
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FutureBuilder<Map<String, int>>(
                              future: _firestoreService.getNotificationStats(
                                _currentUser.uid,
                              ),
                              builder: (context, snapshot) {
                                final stats =
                                    snapshot.data ?? {'today': 0, 'total': 0};

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
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
                                leading: Icon(
                                  Icons.delete_forever,
                                  color: Colors.red[700],
                                ),
                                title: Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Permanently delete your account',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.red,
                                ),
                                onTap: _showDeleteAccountDialog,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const AdMobBanner(),
        ],
      ),
    );
  }

  Widget _buildVehicleTile(UserModel user, VehicleModel vehicle) {
    final isPrimary = user.primaryVehicleId.trim() == vehicle.id;

    return ListTile(
      leading: Icon(
        Icons.directions_car,
        color: isPrimary ? const Color(0xFF10B981) : const Color(0xFF2563EB),
      ),
      title: Text(
        vehicle.licensePlate.trim().isEmpty
            ? 'Unnamed Vehicle'
            : vehicle.licensePlate,
      ),
      subtitle: Text(vehicle.description),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: isPrimary ? 'Primary Vehicle' : 'Set as Primary',
            icon: Icon(
              isPrimary ? Icons.star : Icons.star_border,
              color: isPrimary ? const Color(0xFF10B981) : Colors.grey,
            ),
            onPressed: isPrimary
                ? null
                : () => _setPrimaryVehicle(user, vehicle),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditVehicleDialog(user, vehicle);
              } else if (value == 'delete') {
                _confirmDeleteVehicle(user, vehicle);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      onTap: () => _showEditVehicleDialog(user, vehicle),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Future<void> _handleNotificationToggle(
    List<VehicleModel> vehicles,
    bool isEnabled,
  ) async {
    final userId = _currentUser?.uid;
    if (userId == null) {
      return;
    }

    if (_isUpdatingNotificationPreference) {
      return;
    }

    setState(() {
      _isUpdatingNotificationPreference = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _firestoreService.updateUserProfile(
        userId: userId,
        notificationsEnabled: isEnabled,
      );

      for (final vehicle in vehicles) {
        await _firestoreService.toggleVehicleQRCodeStatus(
          userId: userId,
          vehicleId: vehicle.id,
          qrCodeId: vehicle.qrCodeId,
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

  Future<void> _setPrimaryVehicle(UserModel user, VehicleModel vehicle) async {
    try {
      await _firestoreService.setPrimaryVehicle(
        userId: user.id,
        vehicleId: vehicle.id,
      );
      await _firestoreService.upsertVehicle(
        userId: user.id,
        vehicle: vehicle,
        syncLegacyUserFields: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Primary vehicle updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddVehicleDialog(UserModel user) {
    _showVehicleDialog(
      title: 'Add Vehicle',
      onSave: (color, model, plate) async {
        final createdVehicle = await _firestoreService.upsertVehicle(
          userId: user.id,
          vehicle: VehicleModel(
            id: '',
            userId: user.id,
            color: color,
            carModel: model,
            licensePlate: plate,
            assetNumber: plate,
            isActive: true,
            notificationsEnabled: user.notificationsEnabled,
          ),
          setPrimaryIfMissing: true,
          syncLegacyUserFields: user.primaryVehicleId.trim().isEmpty,
        );

        final userForQr = await _firestoreService.getUserData(user.id) ?? user;

        await _firestoreService.ensureVehicleQrCode(
          user: userForQr,
          vehicle: createdVehicle,
          syncLegacyUserFields: user.primaryVehicleId.trim().isEmpty,
        );
      },
    );
  }

  void _showEditVehicleDialog(UserModel user, VehicleModel vehicle) {
    _showVehicleDialog(
      title: 'Edit Vehicle',
      initialColor: vehicle.color,
      initialModel: vehicle.carModel,
      initialPlate: vehicle.licensePlate,
      onSave: (color, model, plate) async {
        final isPrimaryVehicle =
            user.primaryVehicleId.trim().isEmpty ||
            user.primaryVehicleId == vehicle.id;

        final updatedVehicle = vehicle.copyWith(
          color: color,
          carModel: model,
          licensePlate: plate,
          assetNumber: plate,
        );

        final savedVehicle = await _firestoreService.upsertVehicle(
          userId: user.id,
          vehicle: updatedVehicle,
          syncLegacyUserFields: isPrimaryVehicle,
        );

        final userForQr = await _firestoreService.getUserData(user.id) ?? user;

        await _firestoreService.syncVehicleQrMetadata(
          user: userForQr,
          vehicle: savedVehicle,
          isActive: savedVehicle.isActive,
        );
      },
    );
  }

  void _showVehicleDialog({
    required String title,
    String initialColor = '',
    String initialModel = '',
    String initialPlate = '',
    required Future<void> Function(String color, String model, String plate)
    onSave,
  }) {
    final normalizedInitialPlate = VehicleRegistrationValidator.normalize(
      initialPlate,
    );
    final colorController = TextEditingController(text: initialColor.trim());
    final modelController = TextEditingController(text: initialModel.trim());
    final plateController = TextEditingController(text: normalizedInitialPlate);
    String? registrationError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool hasFormChanges() {
            return colorController.text.trim() != initialColor.trim() ||
                modelController.text.trim() != initialModel.trim() ||
                VehicleRegistrationValidator.normalize(plateController.text) !=
                    normalizedInitialPlate;
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: plateController,
                    decoration: InputDecoration(
                      labelText: 'Registration Number',
                      hintText: 'e.g., PB65AM0008',
                      errorText: registrationError,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) {
                      setModalState(() {
                        registrationError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      hintText: 'e.g., Red, Blue',
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'e.g., Toyota Camry',
                    ),
                    onChanged: (_) => setModalState(() {}),
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
                onPressed: !hasFormChanges()
                    ? null
                    : () async {
                        final normalizedPlate =
                            VehicleRegistrationValidator.normalize(
                              plateController.text,
                            );
                        if (normalizedPlate.isEmpty) {
                          setModalState(() {
                            registrationError =
                                'Please enter your registration number';
                          });
                          return;
                        }
                        if (!VehicleRegistrationValidator.isValid(
                          normalizedPlate,
                        )) {
                          setModalState(() {
                            registrationError =
                                'Please enter a valid registration number';
                          });
                          return;
                        }

                        try {
                          await onSave(
                            colorController.text.trim(),
                            modelController.text.trim(),
                            normalizedPlate,
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                          Future.delayed(const Duration(seconds: 0), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vehicle saved')),
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

  Future<void> _confirmDeleteVehicle(
    UserModel user,
    VehicleModel vehicle,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Delete ${vehicle.licensePlate.isEmpty ? 'this vehicle' : vehicle.licensePlate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _firestoreService.deleteVehicle(user.id, vehicle.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vehicle deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showEditPhoneDialog(UserModel user) {
    final initialPhone = user.phoneNumber.trim();
    final phoneController = TextEditingController(text: initialPhone);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final hasChanges = phoneController.text.trim() != initialPhone;

          return AlertDialog(
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
              onChanged: (_) => setModalState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: hasChanges
                    ? () async {
                        try {
                          await _firestoreService.updateUserProfile(
                            userId: _currentUser!.uid,
                            phoneNumber: phoneController.text.trim(),
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                          Future.delayed(const Duration(seconds: 0), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone number updated'),
                              ),
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
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final hasChanges =
              currentPasswordController.text.isNotEmpty ||
              newPasswordController.text.isNotEmpty ||
              confirmPasswordController.text.isNotEmpty;

          return AlertDialog(
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
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                    ),
                    onChanged: (_) => setModalState(() {}),
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
                onPressed: hasChanges
                    ? () async {
                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match'),
                            ),
                          );
                          return;
                        }

                        try {
                          // Re-authenticate first
                          final credential = EmailAuthProvider.credential(
                            email: _currentUser!.email!,
                            password: currentPasswordController.text,
                          );
                          await _currentUser.reauthenticateWithCredential(
                            credential,
                          );

                          // Update password
                          await _authService.updatePassword(
                            newPassword: newPasswordController.text,
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                          Future.delayed(const Duration(seconds: 0), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully'),
                              ),
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
                      }
                    : null,
                child: const Text('Update'),
              ),
            ],
          );
        },
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
