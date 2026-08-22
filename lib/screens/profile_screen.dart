import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_registration_validator.dart';
import '../widgets/admob_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/ui_kit.dart';
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _firestoreService.streamUserData(_currentUser!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const _ProfileSkeleton();
                }

                final user = userSnapshot.data;
                if (user == null) {
                  return AppEmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Profile unavailable',
                    message:
                        'We could not load your account details. Sign out and '
                        'back in to restore them.',
                    action: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  );
                }

                return StreamBuilder<List<VehicleModel>>(
                  stream: _firestoreService.streamUserVehicles(user.id),
                  builder: (context, vehiclesSnapshot) {
                    final vehicles =
                        vehiclesSnapshot.data ?? const <VehicleModel>[];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(
                            user: user,
                            vehicleCount: vehicles.length,
                            onSignOut: _handleLogout,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.xl,
                              AppSpacing.lg,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                EntranceFade(
                                  child: _buildProtectionCard(user, vehicles),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                EntranceFade(
                                  delay: const Duration(milliseconds: 60),
                                  child: _buildVehiclesSection(user, vehicles),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                EntranceFade(
                                  delay: const Duration(milliseconds: 120),
                                  child: _buildStatsCard(),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                EntranceFade(
                                  delay: const Duration(milliseconds: 180),
                                  child: _buildAccountSection(user),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                EntranceFade(
                                  delay: const Duration(milliseconds: 240),
                                  child: _buildDangerZone(),
                                ),
                              ],
                            ),
                          ),
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

  // -- Sections -----------------------------------------------------------

  /// The master switch. Promoted out of a settings list into its own card
  /// because it decides whether the product works at all.
  Widget _buildProtectionCard(UserModel user, List<VehicleModel> vehicles) {
    final isOn = user.notificationsEnabled;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: isOn
          ? AppColors.success.withValues(alpha: 0.35)
          : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: isOn ? Icons.verified_user_rounded : Icons.shield_outlined,
                color: isOn ? AppColors.success : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOn ? 'Protection is on' : 'Protection is off',
                      style: AppText.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isUpdatingNotificationPreference
                          ? 'Updating…'
                          : isOn
                          ? 'Scans reach you on every vehicle'
                          : 'Scans will not reach you',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: _isUpdatingNotificationPreference
                    ? null
                    : (value) => _handleNotificationToggle(vehicles, value),
              ),
            ],
          ),
          if (!isOn) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: AppRadius.controlAll,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Anyone scanning your sticker will see that you cannot '
                      'be reached right now.',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehiclesSection(UserModel user, List<VehicleModel> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          overline: 'Your garage',
          title: vehicles.length == 1 ? 'Your vehicle' : 'Your vehicles',
          action: TextButton.icon(
            onPressed: () => _showAddVehicleSheet(user),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add'),
          ),
        ),
        if (vehicles.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const AppIconBadge(
                  icon: Icons.directions_car_outlined,
                  color: AppColors.primary,
                  size: 52,
                  iconSize: 26,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('No vehicles yet', style: AppText.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add a vehicle and Avahanaa creates its QR sticker '
                  'automatically.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => _showAddVehicleSheet(user),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add a vehicle'),
                ),
              ],
            ),
          )
        else
          for (final vehicle in vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _VehicleCard(
                vehicle: vehicle,
                isPrimary: user.primaryVehicleId.trim() == vehicle.id,
                onEdit: () => _showEditVehicleSheet(user, vehicle),
                onDelete: () => _confirmDeleteVehicle(user, vehicle),
                onSetPrimary: () => _setPrimaryVehicle(user, vehicle),
              ),
            ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _firestoreService.getNotificationStats(_currentUser!.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const {'today': 0, 'total': 0};

        return AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppStatTile(
                  icon: Icons.today_rounded,
                  value: '${stats['today'] ?? 0}',
                  label: 'Alerts today',
                ),
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: AppColors.border,
              ),
              Expanded(
                child: AppStatTile(
                  icon: Icons.history_rounded,
                  value: '${stats['total'] ?? 0}',
                  label: 'Alerts all time',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(overline: 'Settings', title: 'Account'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              AppListRow(
                icon: Icons.phone_rounded,
                title: 'Phone number',
                subtitle: user.phoneNumber.trim().isEmpty
                    ? 'Not set — only used for account recovery'
                    : user.phoneNumber,
                onTap: () => _showEditPhoneSheet(user),
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              AppListRow(
                icon: Icons.lock_rounded,
                title: 'Change password',
                onTap: _showChangePasswordSheet,
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              AppListRow(
                icon: Icons.policy_rounded,
                title: 'Legal & privacy',
                subtitle: 'Privacy policy and terms of service',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalDocumentsScreen(),
                    ),
                  );
                },
              ),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              AppListRow(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                iconColor: AppColors.textSecondary,
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return AppCard(
      padding: EdgeInsets.zero,
      color: AppColors.alertSurface,
      borderColor: AppColors.alertBorder,
      child: AppListRow(
        icon: Icons.delete_forever_rounded,
        iconColor: AppColors.alert,
        titleColor: AppColors.alertDeep,
        title: 'Delete account',
        subtitle: 'Permanently removes your QR codes and alerts',
        onTap: _showDeleteAccountDialog,
      ),
    );
  }

  // -- Actions ------------------------------------------------------------

  Future<void> _handleNotificationToggle(
    List<VehicleModel> vehicles,
    bool isEnabled,
  ) async {
    final userId = _currentUser?.uid;
    if (userId == null || _isUpdatingNotificationPreference) return;

    setState(() => _isUpdatingNotificationPreference = true);
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

      if (!mounted) return;
      showAppSnackBar(
        messenger,
        isEnabled
            ? 'Protection on — scans will reach you'
            : 'Protection off — scans will not reach you',
        kind: isEnabled ? AppSnackKind.success : AppSnackKind.neutral,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        messenger,
        'Could not update protection: $e',
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingNotificationPreference = false);
      }
    }
  }

  Future<void> _setPrimaryVehicle(UserModel user, VehicleModel vehicle) async {
    final messenger = ScaffoldMessenger.of(context);
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
      showAppSnackBar(
        messenger,
        'Primary vehicle updated',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, 'Error: $e', kind: AppSnackKind.error);
    }
  }

  Future<void> _showAddVehicleSheet(UserModel user) async {
    await _showVehicleSheet(
      title: 'Add a vehicle',
      subtitle: 'Its QR sticker is created automatically.',
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

  Future<void> _showEditVehicleSheet(
    UserModel user,
    VehicleModel vehicle,
  ) async {
    await _showVehicleSheet(
      title: 'Edit vehicle',
      subtitle: 'The QR code stays the same.',
      initialColor: vehicle.color,
      initialModel: vehicle.carModel,
      initialPlate: vehicle.licensePlate,
      onSave: (color, model, plate) async {
        final isPrimaryVehicle =
            user.primaryVehicleId.trim().isEmpty ||
            user.primaryVehicleId == vehicle.id;

        final savedVehicle = await _firestoreService.upsertVehicle(
          userId: user.id,
          vehicle: vehicle.copyWith(
            color: color,
            carModel: model,
            licensePlate: plate,
            assetNumber: plate,
          ),
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

  Future<void> _showVehicleSheet({
    required String title,
    required String subtitle,
    String initialColor = '',
    String initialModel = '',
    String initialPlate = '',
    required Future<void> Function(String color, String model, String plate)
    onSave,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VehicleFormSheet(
        title: title,
        subtitle: subtitle,
        initialColor: initialColor,
        initialModel: initialModel,
        initialPlate: initialPlate,
        onSave: onSave,
      ),
    );

    if (saved == true && mounted) {
      showAppSnackBar(messenger, 'Vehicle saved', kind: AppSnackKind.success);
    }
  }

  Future<void> _confirmDeleteVehicle(
    UserModel user,
    VehicleModel vehicle,
  ) async {
    final label = vehicle.licensePlate.trim().isEmpty
        ? 'this vehicle'
        : vehicle.licensePlate.trim();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text(
          'Deleting $label also retires its QR code. Any sticker already on '
          'the windshield will stop working.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _firestoreService.deleteVehicle(user.id, vehicle.id);
      if (!mounted) return;
      showAppSnackBar(messenger, 'Vehicle deleted', kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, 'Error: $e', kind: AppSnackKind.error);
    }
  }

  Future<void> _showEditPhoneSheet(UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PhoneFormSheet(
        initialPhone: user.phoneNumber,
        onSave: (phone) => _firestoreService.updateUserProfile(
          userId: user.id,
          phoneNumber: phone,
        ),
      ),
    );

    if (saved == true && mounted) {
      showAppSnackBar(
        messenger,
        'Phone number updated',
        kind: AppSnackKind.success,
      );
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PasswordFormSheet(
        onSave: (currentPassword, newPassword) async {
          final credential = EmailAuthProvider.credential(
            email: currentUser.email!,
            password: currentPassword,
          );
          await currentUser.reauthenticateWithCredential(credential);
          await _authService.updatePassword(newPassword: newPassword);
        },
      ),
    );

    if (saved == true && mounted) {
      showAppSnackBar(messenger, 'Password updated', kind: AppSnackKind.success);
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (!mounted || password == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: password,
      );
      await _authService.deleteAccount(credential: credential);

      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, 'Error: $e', kind: AppSnackKind.error);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your QR stickers keep working while you are signed out, but alerts '
          'will not reach this phone until you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final navigator = Navigator.of(context);
    await _authService.signOut();

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.vehicleCount,
    required this.onSignOut,
  });

  final UserModel user;
  final int vehicleCount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final email = user.email.trim();
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();

    return HeroSurface(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.hero),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: AppText.titleLarge.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  color: AppColors.onDark,
                  tooltip: 'Sign out',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.hero,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppText.displayMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: 36,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              email.isEmpty ? 'Your account' : email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.titleMedium.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                StatusPill(
                  label: vehicleCount == 1
                      ? '1 VEHICLE'
                      : '$vehicleCount VEHICLES',
                  color: AppColors.success,
                  icon: Icons.directions_car_rounded,
                  onDark: true,
                ),
                if (user.createdAt != null)
                  StatusPill(
                    label:
                        'SINCE ${DateFormat('MMM y').format(user.createdAt!).toUpperCase()}',
                    color: AppColors.primary,
                    icon: Icons.event_rounded,
                    onDark: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle card
// ---------------------------------------------------------------------------

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.isPrimary,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  final VehicleModel vehicle;
  final bool isPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    final descriptor = [
      vehicle.color,
      vehicle.carModel,
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return AppCard(
      onTap: onEdit,
      borderColor: isPrimary
          ? AppColors.success.withValues(alpha: 0.4)
          : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: vehicle.licensePlate.trim().isEmpty
                    ? Text('Unnamed vehicle', style: AppText.titleMedium)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: PlateBadge(
                          plate: vehicle.licensePlate,
                          height: 36,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textTertiary,
                ),
                tooltip: 'Vehicle options',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'primary':
                      onSetPrimary();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit details')),
                  if (!isPrimary)
                    const PopupMenuItem(
                      value: 'primary',
                      child: Text('Make primary'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.alert),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            descriptor.isEmpty ? 'No details added yet' : descriptor,
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusPill(
                label: vehicle.isActive ? 'QR ACTIVE' : 'QR PAUSED',
                color: vehicle.isActive
                    ? AppColors.success
                    : AppColors.textTertiary,
                icon: vehicle.isActive
                    ? Icons.qr_code_rounded
                    : Icons.qr_code_scanner_rounded,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isPrimary)
                const StatusPill(
                  label: 'PRIMARY',
                  color: AppColors.primary,
                  icon: Icons.star_rounded,
                )
              else
                TextButton(
                  onPressed: onSetPrimary,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: AppText.labelSmall,
                  ),
                  child: const Text('MAKE PRIMARY'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form sheets
// ---------------------------------------------------------------------------

/// Shared chrome for the editing sheets: grabber, title, keyboard inset.
class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetGrabber(),
              Text(title, style: AppText.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleFormSheet extends StatefulWidget {
  const _VehicleFormSheet({
    required this.title,
    required this.subtitle,
    required this.initialColor,
    required this.initialModel,
    required this.initialPlate,
    required this.onSave,
  });

  final String title;
  final String subtitle;
  final String initialColor;
  final String initialModel;
  final String initialPlate;
  final Future<void> Function(String color, String model, String plate) onSave;

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  late final String _normalisedInitialPlate =
      VehicleRegistrationValidator.normalize(widget.initialPlate);
  late final TextEditingController _plateController = TextEditingController(
    text: _normalisedInitialPlate,
  );
  late final TextEditingController _colorController = TextEditingController(
    text: widget.initialColor.trim(),
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.initialModel.trim(),
  );

  String? _plateError;
  String? _submitError;
  bool _isSaving = false;

  @override
  void dispose() {
    _plateController.dispose();
    _colorController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _colorController.text.trim() != widget.initialColor.trim() ||
        _modelController.text.trim() != widget.initialModel.trim() ||
        VehicleRegistrationValidator.normalize(_plateController.text) !=
            _normalisedInitialPlate;
  }

  Future<void> _submit() async {
    final plate = VehicleRegistrationValidator.normalize(
      _plateController.text,
    );

    if (plate.isEmpty) {
      setState(() => _plateError = 'Enter your registration number');
      return;
    }
    if (!VehicleRegistrationValidator.isValid(plate)) {
      setState(() => _plateError = 'That does not look like a valid number');
      return;
    }

    setState(() {
      _isSaving = true;
      _plateError = null;
      _submitError = null;
    });

    try {
      await widget.onSave(
        _colorController.text.trim(),
        _modelController.text.trim(),
        plate,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      children: [
        TextField(
          controller: _plateController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          inputFormatters: [UpperCaseTextFormatter()],
          decoration: InputDecoration(
            labelText: 'Registration number',
            hintText: 'KA01AB1234',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            errorText: _plateError,
          ),
          onChanged: (_) => setState(() => _plateError = null),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _colorController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Colour',
            hintText: 'White',
            prefixIcon: Icon(Icons.palette_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _modelController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Make and model',
            hintText: 'Maruti Swift',
            prefixIcon: Icon(Icons.directions_car_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Colour and model help whoever finds your vehicle confirm they are '
          'looking at the right one.',
          style: AppText.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _submitError!,
            style: AppText.bodySmall.copyWith(color: AppColors.alert),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (!_hasChanges || _isSaving) ? null : _submit,
            child: _isSaving
                ? const _ButtonSpinner()
                : const Text('Save vehicle'),
          ),
        ),
      ],
    );
  }
}

class _PhoneFormSheet extends StatefulWidget {
  const _PhoneFormSheet({required this.initialPhone, required this.onSave});

  final String initialPhone;
  final Future<void> Function(String phone) onSave;

  @override
  State<_PhoneFormSheet> createState() => _PhoneFormSheetState();
}

class _PhoneFormSheetState extends State<_PhoneFormSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialPhone.trim(),
  );
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(_controller.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _controller.text.trim() != widget.initialPhone.trim();

    return _FormSheet(
      title: 'Phone number',
      subtitle:
          'Used only for account recovery. It is never shown to anyone who '
          'scans your QR code.',
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => hasChanges ? _submit() : null,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: AppText.bodySmall.copyWith(color: AppColors.alert),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (!hasChanges || _isSaving) ? null : _submit,
            child: _isSaving ? const _ButtonSpinner() : const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _PasswordFormSheet extends StatefulWidget {
  const _PasswordFormSheet({required this.onSave});

  final Future<void> Function(String currentPassword, String newPassword)
  onSave;

  @override
  State<_PasswordFormSheet> createState() => _PasswordFormSheetState();
}

class _PasswordFormSheetState extends State<_PasswordFormSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newController.text.length < 6) {
      setState(() => _error = 'Use at least 6 characters');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'The new passwords do not match');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(_currentController.text, _newController.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _currentController.text.isNotEmpty &&
        _newController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty;

    return _FormSheet(
      title: 'Change password',
      subtitle: 'You will stay signed in on this device.',
      children: [
        TextField(
          controller: _currentController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Current password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _newController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'New password',
            prefixIcon: Icon(Icons.lock_reset_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _confirmController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => canSubmit ? _submit() : null,
          decoration: const InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: Icon(Icons.lock_reset_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: AppText.bodySmall.copyWith(color: AppColors.alert),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (!canSubmit || _isSaving) ? null : _submit,
            child: _isSaving
                ? const _ButtonSpinner()
                : const Text('Update password'),
          ),
        ),
      ],
    );
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
      setState(() => _errorText = 'Enter your password to confirm');
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently deletes your account, every vehicle, every QR '
              'code and every alert. Stickers already on your windshield will '
              'stop working. This cannot be undone.',
              style: AppText.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Current password',
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
          style: TextButton.styleFrom(foregroundColor: AppColors.alert),
          child: const Text('Delete forever'),
        ),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onDark),
      ),
    );
  }
}

/// Registration numbers are always stored and displayed uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          AppSkeleton(height: 250, radius: 0),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSkeleton(height: 96),
                SizedBox(height: AppSpacing.lg),
                AppSkeleton(height: 150),
                SizedBox(height: AppSpacing.lg),
                AppSkeleton(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
