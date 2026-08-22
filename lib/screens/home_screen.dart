import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/qr_payload_builder.dart';
import '../widgets/admob_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/qr_visual.dart';
import '../widgets/ui_kit.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'qr_code_screen.dart';

/// Tag shared between the home QR plinth and the full QR screen so the code
/// flies between them instead of cross-fading.
const String kQrHeroTag = 'avahanaa-qr-hero';

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

  /// Which vehicle's QR the home tab is showing. Local only — switching the
  /// view must not rewrite the account's primary vehicle.
  String? _viewedVehicleId;

  void _openTab(int index) => setState(() => _selectedIndex = index);

  void _viewVehicle(VehicleModel vehicle) {
    setState(() => _viewedVehicleId = vehicle.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _firestoreService.streamUnreadNotificationCount(
        _currentUser!.uid,
      ),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        final screens = <Widget>[
          _HomeTab(
            state: this,
            unreadCount: unreadCount,
            onOpenInbox: () => _openTab(1),
          ),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: _AppNavBar(
            currentIndex: _selectedIndex,
            unreadCount: unreadCount,
            onTap: _openTab,
          ),
        );
      },
    );
  }

  // -- Data plumbing (unchanged behaviour) --------------------------------

  VehicleModel _selectVehicle(UserModel user, List<VehicleModel> vehicles) {
    final viewedId = _viewedVehicleId;
    if (viewedId != null) {
      for (final vehicle in vehicles) {
        if (vehicle.id == viewedId) return vehicle;
      }
    }

    final primaryId = user.primaryVehicleId.trim();
    if (primaryId.isNotEmpty) {
      for (final vehicle in vehicles) {
        if (vehicle.id == primaryId) return vehicle;
      }
    }
    return vehicles.first;
  }

  Future<void> _bootstrapLegacyVehicle(UserModel user) async {
    if (_isBootstrappingLegacyVehicle) return;

    final needsMigration =
        user.hasLegacyVehicleData || user.qrCodeId.trim().isNotEmpty;
    if (!needsMigration) return;

    _isBootstrappingLegacyVehicle = true;
    try {
      await _firestoreService.bootstrapVehiclesFromLegacyUser(user);
    } catch (e) {
      debugPrint('Error bootstrapping legacy vehicle: $e');
    } finally {
      _isBootstrappingLegacyVehicle = false;
    }
  }

  Future<void> _generateQrCode(UserModel user, VehicleModel vehicle) async {
    if (_isGeneratingQrCode || vehicle.qrCodeId.trim().isNotEmpty) return;

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

// ---------------------------------------------------------------------------
// Home tab
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.state,
    required this.unreadCount,
    required this.onOpenInbox,
  });

  final _HomeScreenState state;
  final int unreadCount;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: state._firestoreService.streamUserData(state._currentUser!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const _HomeScaffold(child: _HomeSkeleton());
        }

        if (userSnapshot.hasError) {
          return _HomeScaffold(
            child: AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Cannot reach your account',
              message:
                  'Check your connection — your QR code keeps working for '
                  'anyone who scans it, this screen just cannot refresh.',
              accent: AppColors.alert,
            ),
          );
        }

        final user = userSnapshot.data;
        if (user == null) {
          return const _HomeScaffold(
            child: AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Account details missing',
              message:
                  'We could not load your profile. Sign out and back in to '
                  'restore it.',
            ),
          );
        }

        return StreamBuilder<List<VehicleModel>>(
          stream: state._firestoreService.streamUserVehicles(user.id),
          builder: (context, vehicleSnapshot) {
            if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
              return const _HomeScaffold(child: _HomeSkeleton());
            }

            final vehicles = vehicleSnapshot.data ?? const <VehicleModel>[];

            if (vehicles.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                state._bootstrapLegacyVehicle(user);
              });

              final waitingOnMigration =
                  user.hasLegacyVehicleData || user.qrCodeId.trim().isNotEmpty;

              return _HomeScaffold(
                child: waitingOnMigration
                    ? const _PreparingView(
                        title: 'Setting up your vehicle',
                        subtitle: 'Moving your details over. One moment.',
                      )
                    : AppEmptyState(
                        icon: Icons.directions_car_outlined,
                        title: 'Add your first vehicle',
                        message:
                            'Avahanaa needs a vehicle before it can create the '
                            'QR code for your windshield.',
                        action: ElevatedButton.icon(
                          onPressed: onOpenInbox,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Go to Profile'),
                        ),
                      ),
              );
            }

            final vehicle = state._selectVehicle(user, vehicles);

            if (vehicle.qrCodeId.trim().isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                state._generateQrCode(user, vehicle);
              });
              return const _HomeScaffold(
                child: _PreparingView(
                  title: 'Creating your QR code',
                  subtitle: 'This usually takes a few seconds.',
                ),
              );
            }

            return _HomeScaffold(
              child: _HomeBody(
                state: state,
                user: user,
                vehicles: vehicles,
                vehicle: vehicle,
                unreadCount: unreadCount,
                onOpenInbox: onOpenInbox,
              ),
            );
          },
        );
      },
    );
  }
}

/// Every home state shares the same shell: content above, ad strip pinned
/// below. Keeping it in one place stops the ad from jumping between states.
class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const AdMobBanner(),
      ],
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.state,
    required this.user,
    required this.vehicles,
    required this.vehicle,
    required this.unreadCount,
    required this.onOpenInbox,
  });

  final _HomeScreenState state;
  final UserModel user;
  final List<VehicleModel> vehicles;
  final VehicleModel vehicle;
  final int unreadCount;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    final qrPayload = QrPayloadBuilder.buildPayload(
      user: user,
      vehicle: vehicle,
    );

    if (vehicle.qrCodeId.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state._syncQrMetadata(user, vehicle, qrPayload);
      });
    }

    final isLive = vehicle.isActive && user.notificationsEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeHero(
            user: user,
            vehicle: vehicle,
            vehicles: vehicles,
            isLive: isLive,
            unreadCount: unreadCount,
            onSelectVehicle: state._viewVehicle,
          ),

          // Panic mode: an unread alert outranks everything below it.
          _CriticalAlertBanner(
            state: state,
            user: user,
            onOpenInbox: onOpenInbox,
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
                  delay: const Duration(milliseconds: 60),
                  child: _QrCard(
                    user: user,
                    vehicle: vehicle,
                    payload: qrPayload,
                    isLive: isLive,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                EntranceFade(
                  delay: const Duration(milliseconds: 120),
                  child: _StatsRow(
                    unreadCount: unreadCount,
                    vehicleCount: vehicles.length,
                    isLive: isLive,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                EntranceFade(
                  delay: const Duration(milliseconds: 180),
                  child: const _HowItWorksCard(),
                ),
                const SizedBox(height: AppSpacing.lg),
                EntranceFade(
                  delay: const Duration(milliseconds: 240),
                  child: const _PrivacyPromiseCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.user,
    required this.vehicle,
    required this.vehicles,
    required this.isLive,
    required this.unreadCount,
    required this.onSelectVehicle,
  });

  final UserModel user;
  final VehicleModel vehicle;
  final List<VehicleModel> vehicles;
  final bool isLive;
  final int unreadCount;
  final ValueChanged<VehicleModel> onSelectVehicle;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final descriptor = [
      vehicle.color,
      vehicle.carModel,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return HeroSurface(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.hero),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.onDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLive
                            ? 'Your vehicle is reachable'
                            : 'Your QR code is paused',
                        style: AppText.headlineLarge.copyWith(
                          color: AppColors.onDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                StatusPill(
                  label: isLive ? 'LIVE' : 'PAUSED',
                  color: isLive ? AppColors.success : AppColors.warning,
                  icon: isLive
                      ? Icons.shield_rounded
                      : Icons.pause_circle_outline_rounded,
                  onDark: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (vehicles.length > 1) ...[
              _VehicleSwitcher(
                vehicles: vehicles,
                selected: vehicle,
                onSelect: onSelectVehicle,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            HeroGlassPanel(
              child: Row(
                children: [
                  Flexible(child: PlateBadge(plate: vehicle.licensePlate)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          descriptor.isEmpty ? 'Your vehicle' : descriptor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.titleSmall.copyWith(
                            color: AppColors.onDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLive
                              ? 'Anyone can alert you. No one sees your number.'
                              : 'Scans are not reaching you right now.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.onDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal chips for accounts with more than one vehicle. Selection is
/// view-only — it never rewrites `primaryVehicleId`.
class _VehicleSwitcher extends StatelessWidget {
  const _VehicleSwitcher({
    required this.vehicles,
    required this.selected,
    required this.onSelect,
  });

  final List<VehicleModel> vehicles;
  final VehicleModel selected;
  final ValueChanged<VehicleModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = vehicles[index];
          final isSelected = item.id == selected.id;
          final label = item.licensePlate.trim().isEmpty
              ? 'Vehicle ${index + 1}'
              : item.licensePlate.trim().toUpperCase();

          return Semantics(
            button: true,
            selected: isSelected,
            child: Material(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: isSelected ? null : () => onSelect(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppText.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.primaryDeep
                            : AppColors.onDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.user,
    required this.vehicle,
    required this.payload,
    required this.isLive,
  });

  final UserModel user;
  final VehicleModel vehicle;
  final String payload;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => QRCodeScreen(user: user, vehicle: vehicle),
          ),
        );
      },
      child: Column(
        children: [
          Text('Your windshield code', style: AppText.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isLive
                ? 'Scannable with any phone camera — no app needed'
                : 'Currently paused. Scans will not reach you.',
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          QrHeroPlinth(
            data: payload,
            isActive: isLive,
            size: 180,
            heroTag: kQrHeroTag,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.open_in_full_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tap to print or share',
                style: AppText.labelMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.unreadCount,
    required this.vehicleCount,
    required this.isLive,
  });

  final int unreadCount;
  final int vehicleCount;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppStatTile(
              icon: Icons.mark_email_unread_rounded,
              value: unreadCount.toString(),
              label: unreadCount == 1 ? 'Unread alert' : 'Unread alerts',
              color: unreadCount > 0 ? AppColors.alert : AppColors.primary,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: AppStatTile(
              icon: Icons.directions_car_rounded,
              value: vehicleCount.toString(),
              label: vehicleCount == 1 ? 'Vehicle' : 'Vehicles',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: AppStatTile(
              icon: isLive
                  ? Icons.verified_user_rounded
                  : Icons.shield_outlined,
              value: isLive ? 'On' : 'Off',
              label: 'Protection',
              color: isLive ? AppColors.success : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.border,
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(overline: 'Getting set up', title: 'How it works'),
          const NumberedStep(
            number: '1',
            title: 'Print the sticker',
            detail: 'Share or save it, then print on plain white paper.',
          ),
          const NumberedStep(
            number: '2',
            title: 'Put it on your windshield',
            detail: 'Inside the glass, driver-side corner, facing out.',
          ),
          const NumberedStep(
            number: '3',
            title: 'Get alerted in seconds',
            detail: 'A scan rings your phone, even on silent.',
            accent: AppColors.success,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

/// The product promise, stated plainly. This is the reason someone chooses
/// Avahanaa over writing their number on a card, so it earns a place on the
/// home screen rather than being buried in the privacy policy.
class _PrivacyPromiseCard extends StatelessWidget {
  const _PrivacyPromiseCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.infoSurface,
      borderColor: AppColors.infoBorder,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconBadge(
            icon: Icons.lock_person_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your number stays yours', style: AppText.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Whoever scans your code can tell you something is wrong — '
                  'and that is all. They never see your phone number, your '
                  'email, or your name.',
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panic mode
// ---------------------------------------------------------------------------

/// Shown at the top of home whenever an alert is unread.
///
/// Designed panic-first: oversized type, maximum contrast, a single primary
/// action, and no competing decoration. Someone reading this may be walking
/// fast toward their car.
class _CriticalAlertBanner extends StatelessWidget {
  const _CriticalAlertBanner({
    required this.state,
    required this.user,
    required this.onOpenInbox,
  });

  final _HomeScreenState state;
  final UserModel user;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: state._firestoreService.streamUserNotifications(user.id),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <NotificationModel>[];
        final unread = notifications.where((n) => !n.read).toList();
        if (unread.isEmpty) return const SizedBox.shrink();

        final latest = unread.first;
        final detail = latest.message.trim().isEmpty
            ? latest.reasonText
            : latest.message.trim();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            0,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.heroAll,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.alertGradient,
              ),
              boxShadow: AppShadows.glow(AppColors.alert),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // Top-aligned so the icon tracks the first line of the
                    // headline instead of drifting to the middle when it wraps.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: BreathingPulse(
                          child: Icon(
                            Icons.warning_rounded,
                            color: AppColors.onDark,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          unread.length == 1
                              ? 'Someone needs you at your vehicle'
                              : '${unread.length} people need you at your vehicle',
                          style: AppText.panicTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyLarge.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    latest.timeAgo,
                    style: AppText.labelMedium.copyWith(
                      color: AppColors.onDarkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => NotificationsScreen(
                              initialNotificationId: latest.id,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.alertDeep,
                        textStyle: AppText.labelLarge.copyWith(fontSize: 17),
                      ),
                      child: const Text('See what happened'),
                    ),
                  ),
                  if (unread.length > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onOpenInbox,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onDark,
                        ),
                        child: Text('View all ${unread.length} alerts'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading + placeholder states
// ---------------------------------------------------------------------------

class _PreparingView extends StatelessWidget {
  const _PreparingView({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, textAlign: TextAlign.center, style: AppText.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors the real layout so the screen does not reflow when data lands.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSkeleton(height: 208, radius: 0),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AppSkeleton(height: 340),
                SizedBox(height: AppSpacing.lg),
                AppSkeleton(height: 120),
                SizedBox(height: AppSpacing.lg),
                AppSkeleton(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _AppNavBar extends StatelessWidget {
  const _AppNavBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Alerts',
                badgeCount: unreadCount,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: badgeCount > 0 ? '$label, $badgeCount unread' : label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.controlAll,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              // 48dp minimum tap target.
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryTint : Colors.transparent,
                borderRadius: AppRadius.controlAll,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(isActive ? activeIcon : icon, color: color, size: 24),
                      if (badgeCount > 0)
                        Positioned(
                          right: -9,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(
                              color: AppColors.alert,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              textAlign: TextAlign.center,
                              style: AppText.labelSmall.copyWith(
                                color: AppColors.onDark,
                                fontSize: 10,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppText.labelSmall.copyWith(
                      color: color,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
