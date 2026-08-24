/// How a vehicle presents itself on the home hero.
///
/// The home screen used to name the current vehicle in a single glass row and
/// switch between vehicles with a rail of plate chips. That made a garage feel
/// like a dropdown. Here the vehicle is the object on the page: one face per
/// car, swiped between, with its position in the fleet stated plainly
/// underneath.
///
/// Lives in `widgets/` rather than inside `home_screen.dart` so the layout can
/// be pumped at 320dp and 2.0x text scale by `test/ui_kit_layout_test.dart` —
/// the hero is the densest row in the app and has regressed on width before.
library;

import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../theme/app_theme.dart';
import 'hero_header.dart';
import 'ui_kit.dart';

/// Maps a written vehicle colour onto something paintable.
///
/// Owners type free text ("Pearl White", "dark blue"), so this matches on
/// substrings and gives up rather than guessing. A wrong swatch is worse than
/// no swatch: the point of the dot is that the owner recognises their own car
/// at a glance.
Color? vehicleColorSwatch(String name) {
  final value = name.trim().toLowerCase();
  if (value.isEmpty) return null;

  const swatches = <String, Color>{
    'white': Color(0xFFF8FAFC),
    'silver': Color(0xFFCBD5E1),
    'grey': Color(0xFF94A3B8),
    'gray': Color(0xFF94A3B8),
    'black': Color(0xFF1F2937),
    'red': Color(0xFFDC2626),
    'maroon': Color(0xFF7F1D1D),
    'orange': Color(0xFFEA580C),
    'yellow': Color(0xFFEAB308),
    'gold': Color(0xFFCA8A04),
    'green': Color(0xFF16A34A),
    'blue': Color(0xFF2563EB),
    'navy': Color(0xFF1E3A8A),
    'purple': Color(0xFF7C3AED),
    'brown': Color(0xFF78350F),
    'beige': Color(0xFFE7D8C1),
    'bronze': Color(0xFF9A6A3A),
  };

  for (final entry in swatches.entries) {
    if (value.contains(entry.key)) return entry.value;
  }
  return null;
}

/// One vehicle, as a glass panel for [HeroSurface].
class VehicleFace extends StatelessWidget {
  const VehicleFace({
    super.key,
    required this.vehicle,
    required this.isLive,
    this.onTap,
  });

  final VehicleModel vehicle;
  final bool isLive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final descriptor = [
      vehicle.color,
      vehicle.carModel,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final swatch = vehicleColorSwatch(vehicle.color);

    return HeroGlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _VehicleMark(swatch: swatch),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PlateBadge(plate: vehicle.licensePlate, height: 34),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  descriptor.isEmpty ? 'Your vehicle' : descriptor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleSmall.copyWith(color: AppColors.onDark),
                ),
                Text(
                  isLive
                      ? 'Reachable — your number stays hidden'
                      : 'Paused — scans are not reaching you',
                  maxLines: 1,
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
    );
  }
}

/// The colour swatch, as a lens over a car silhouette.
///
/// A pale swatch on a translucent panel would vanish, so the disc always
/// carries a hairline ring and the icon always sits at full contrast on top of
/// whatever colour is behind it.
class _VehicleMark extends StatelessWidget {
  const _VehicleMark({required this.swatch});

  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final fill = swatch ?? Colors.white.withValues(alpha: 0.18);
    final isPale = swatch == null
        ? false
        : ThemeData.estimateBrightnessForColor(swatch!) == Brightness.light;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.directions_car_rounded,
        size: 22,
        color: isPale ? AppColors.textPrimary : AppColors.onDark,
      ),
    );
  }
}

/// A swipeable rail of [VehicleFace]s with its position stated underneath.
///
/// Selection here is view-only. Swiping changes which vehicle the home screen
/// is *looking at*; it never rewrites `primaryVehicleId`, because the vehicle
/// whose QR someone is about to scan is not a preference.
class VehicleCarousel extends StatefulWidget {
  const VehicleCarousel({
    super.key,
    required this.vehicles,
    required this.selected,
    required this.isLive,
    required this.onSelect,
    this.onTapVehicle,
  });

  final List<VehicleModel> vehicles;
  final VehicleModel selected;
  final bool isLive;
  final ValueChanged<VehicleModel> onSelect;
  final ValueChanged<VehicleModel>? onTapVehicle;

  @override
  State<VehicleCarousel> createState() => _VehicleCarouselState();
}

class _VehicleCarouselState extends State<VehicleCarousel> {
  late PageController _controller;

  int get _selectedIndex {
    final index = widget.vehicles.indexWhere(
      (vehicle) => vehicle.id == widget.selected.id,
    );
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _selectedIndex);
  }

  @override
  void didUpdateWidget(VehicleCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The selection can move without a swipe — a deep link, or a vehicle being
    // deleted out from under the rail — so follow it.
    final target = _selectedIndex;
    if (_controller.hasClients && _controller.page?.round() != target) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.animateToPage(
          target,
          duration: AppMotion.normal,
          curve: AppMotion.emphasis,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The rail has to be a fixed height for [PageView] to lay out, and the
  /// content inside it grows with the system font. Scaling the box by the same
  /// factor is what keeps the panel from overflowing at 2.0x.
  double _railHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return 92 + (scale.clamp(1.0, 2.0) - 1.0) * 96;
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.vehicles;

    if (vehicles.length == 1) {
      return VehicleFace(
        vehicle: vehicles.first,
        isLive: widget.isLive,
        onTap: widget.onTapVehicle == null
            ? null
            : () => widget.onTapVehicle!(vehicles.first),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _railHeight(context),
          child: PageView.builder(
            controller: _controller,
            itemCount: vehicles.length,
            onPageChanged: (index) => widget.onSelect(vehicles[index]),
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return VehicleFace(
                vehicle: vehicle,
                isLive: widget.isLive,
                onTap: widget.onTapVehicle == null
                    ? null
                    : () => widget.onTapVehicle!(vehicle),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CarouselPosition(
          count: vehicles.length,
          index: _selectedIndex,
          onSelect: (index) => widget.onSelect(vehicles[index]),
        ),
      ],
    );
  }
}

/// Dots plus the position in words.
///
/// The dots alone are decoration — "Vehicle 2 of 3" is what actually tells
/// someone with three cars which one they are looking at, and it is the only
/// part a screen reader can use.
class _CarouselPosition extends StatelessWidget {
  const _CarouselPosition({
    required this.count,
    required this.index,
    required this.onSelect,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Past half a dozen vehicles a dot rail stops being scannable and starts
    // overflowing a 320dp screen. The sentence still says where you are.
    final showDots = count <= 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Vehicle ${index + 1} of $count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.labelSmall.copyWith(color: AppColors.onDarkMuted),
          ),
        ),
        if (showDots) const SizedBox(width: AppSpacing.sm),
        if (showDots)
          for (var i = 0; i < count; i++)
            Semantics(
              button: true,
              selected: i == index,
              label: 'Show vehicle ${i + 1}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onSelect(i),
                customBorder: const CircleBorder(),
                child: Padding(
                  // Keeps a 6px dot inside a 24px target.
                  padding: const EdgeInsets.all(9),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    width: i == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.onDark
                          : Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
