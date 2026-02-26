import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/firestore_service.dart';
import '../utils/qr_payload_builder.dart';
import '../widgets/admob_banner.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'qr_code_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  String? _lastSyncedPayloadKey;
  bool _isSyncingQrMetadata = false;
  bool _isGeneratingQrCode = false;
  bool _isBootstrappingLegacyVehicle = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeContent(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.streamUserData(_currentUser!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            children: [
              Expanded(child: Center(child: CircularProgressIndicator())),
              AdMobBanner(),
            ],
          );
        }

        if (userSnapshot.hasError) {
          return Column(
            children: [
              Expanded(
                child: Center(child: Text('Error: ${userSnapshot.error}')),
              ),
              const AdMobBanner(),
            ],
          );
        }

        final user = userSnapshot.data;

        if (user == null) {
          return const Column(
            children: [
              Expanded(child: Center(child: Text('User data not found'))),
              AdMobBanner(),
            ],
          );
        }

        return StreamBuilder<List<VehicleModel>>(
          stream: _firestoreService.streamUserVehicles(user.id),
          builder: (context, vehicleSnapshot) {
            if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                children: [
                  Expanded(child: Center(child: CircularProgressIndicator())),
                  AdMobBanner(),
                ],
              );
            }

            if (vehicleSnapshot.hasError) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text('Error: ${vehicleSnapshot.error}'),
                    ),
                  ),
                  const AdMobBanner(),
                ],
              );
            }

            final vehicles = vehicleSnapshot.data ?? const <VehicleModel>[];

            if (vehicles.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _bootstrapLegacyVehicle(user);
              });

              final waitingOnMigration =
                  user.hasLegacyVehicleData || user.qrCodeId.trim().isNotEmpty;

              return Column(
                children: [
                  Expanded(
                    child: _buildWaitingForQRCode(
                      title: waitingOnMigration
                          ? 'Preparing your vehicle...'
                          : 'No vehicles found',
                      subtitle: waitingOnMigration
                          ? 'Migrating your existing profile data'
                          : 'Add a vehicle from Profile to generate QR',
                    ),
                  ),
                  const AdMobBanner(),
                ],
              );
            }

            final selectedVehicle = _selectVehicle(user, vehicles);

            if (selectedVehicle.qrCodeId.trim().isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _generateQrCode(user, selectedVehicle);
              });
              return Column(
                children: [
                  Expanded(child: _buildWaitingForQRCode()),
                  const AdMobBanner(),
                ],
              );
            }

            return Column(
              children: [
                Expanded(child: _buildMainContent(user, selectedVehicle)),
                const AdMobBanner(),
              ],
            );
          },
        );
      },
    );
  }

  VehicleModel _selectVehicle(UserModel user, List<VehicleModel> vehicles) {
    final primaryId = user.primaryVehicleId.trim();
    if (primaryId.isNotEmpty) {
      for (final vehicle in vehicles) {
        if (vehicle.id == primaryId) {
          return vehicle;
        }
      }
    }
    return vehicles.first;
  }

  Future<void> _bootstrapLegacyVehicle(UserModel user) async {
    if (_isBootstrappingLegacyVehicle) {
      return;
    }

    final needsMigration =
        user.hasLegacyVehicleData || user.qrCodeId.trim().isNotEmpty;
    if (!needsMigration) {
      return;
    }

    _isBootstrappingLegacyVehicle = true;
    try {
      await _firestoreService.bootstrapVehiclesFromLegacyUser(user);
    } catch (e) {
      debugPrint('Error bootstrapping legacy vehicle: $e');
    } finally {
      _isBootstrappingLegacyVehicle = false;
    }
  }

  Widget _buildWaitingForQRCode({
    String title = 'Generating your QR code...',
    String subtitle = 'This usually takes a few seconds',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(UserModel user, VehicleModel vehicle) {
    final qrPayload = QrPayloadBuilder.buildPayload(
      user: user,
      vehicle: vehicle,
    );

    if (vehicle.qrCodeId.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncQrMetadata(user, vehicle, qrPayload);
      });
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 10, 10, 10), Color(0xFF002b5c)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (vehicle.licensePlate.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      vehicle.licensePlate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // QR Code Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QRCodeScreen(user: user, vehicle: vehicle),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Your Vehicle QR Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view full size',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                            errorCorrectionLevel: QrErrorCorrectLevel.L,
                            gapless: true,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Icon(
                          Icons.touch_app,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<int>(
                stream: _firestoreService.streamUnreadNotificationCount(
                  _currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.notifications_active,
                            label: 'Unread',
                            value: unreadCount.toString(),
                            color: const Color(0xFF2563EB),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildStatItem(
                            icon: Icons.qr_code,
                            label: 'QR Status',
                            value: vehicle.isActive ? 'Active' : 'Inactive',
                            color: vehicle.isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Instructions Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                color: const Color(0xFFF0F9FF),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                          SizedBox(width: 12),
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep('1', 'Print your QR code'),
                      _buildInstructionStep(
                        '2',
                        'Place it on your car windshield',
                      ),
                      _buildInstructionStep(
                        '3',
                        'Receive instant notifications',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQrCode(UserModel user, VehicleModel vehicle) async {
    if (_isGeneratingQrCode || vehicle.qrCodeId.trim().isNotEmpty) {
      return;
    }

    _isGeneratingQrCode = true;
    try {
      final payload = await _firestoreService.ensureVehicleQrCode(
        user: user,
        vehicle: vehicle,
        syncLegacyUserFields: true,
      );
      if (mounted) {
        _lastSyncedPayloadKey = '${vehicle.id}:$payload';
      }
    } catch (e) {
      debugPrint('Error generating QR code: $e');
    } finally {
      _isGeneratingQrCode = false;
    }
  }

  void _syncQrMetadata(UserModel user, VehicleModel vehicle, String payload) {
    final syncKey = '${vehicle.id}:$payload';
    if (vehicle.qrCodeId.trim().isEmpty ||
        _isSyncingQrMetadata ||
        _lastSyncedPayloadKey == syncKey) {
      return;
    }

    _isSyncingQrMetadata = true;

    _firestoreService
        .syncVehicleQrMetadata(
          user: user,
          vehicle: vehicle,
          isActive: vehicle.isActive,
        )
        .then((_) {
          _lastSyncedPayloadKey = syncKey;
        })
        .catchError((e) {
          debugPrint('Error syncing QR metadata: $e');
        })
        .whenComplete(() {
          _isSyncingQrMetadata = false;
        });
  }
}
