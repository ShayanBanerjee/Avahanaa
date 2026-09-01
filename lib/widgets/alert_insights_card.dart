/// What the owner's alerts add up to.
///
/// Sits at the top of the alerts tab once there is enough history to say
/// anything, and is absent before that — a dashboard of zeroes is worse than
/// no dashboard, because it teaches people the section is empty and they stop
/// looking.
///
/// The headline is the response time, not the alert count. The count is
/// vanity; how fast the owner actually answers is the number that matches what
/// this product claims to do, and seeing it is what makes somebody answer
/// faster next time.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alert_insights.dart';
import '../models/vehicle_model.dart';
import '../theme/app_theme.dart';
import '../utils/notification_visuals.dart';
import 'ui_kit.dart';

class AlertInsightsCard extends StatelessWidget {
  const AlertInsightsCard({
    super.key,
    required this.insights,
    required this.vehicles,
  });

  final AlertInsights insights;

  /// Used to turn a vehicleId into something a human recognises. An id that is
  /// no longer in the list — a deleted vehicle — is skipped rather than shown
  /// as a hex string.
  final List<VehicleModel> vehicles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (!insights.hasEnoughData) return const SizedBox.shrink();

    final topReason = insights.byReason.isEmpty
        ? null
        : insights.byReason.first;
    final topVehicle = _topVehicleLabel();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsOverline, style: AppText.overline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            insights.medianResponse == null
                ? l10n.insightsNoResponsesTitle
                : l10n.insightsResponseTitle(
                    _formatDuration(l10n, insights.medianResponse!),
                  ),
            style: AppText.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.insightsWindow(insights.total),
            style: AppText.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${insights.thisMonth}',
                  label: l10n.insightsThisMonth,
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _Stat(
                  value: '${(insights.responseRate * 100).round()}%',
                  label: l10n.insightsAnswered,
                  emphasis: insights.responseRate >= 0.8,
                ),
              ),
            ],
          ),
          if (topReason != null ||
              topVehicle != null ||
              insights.busiestHour != null ||
              insights.emergencies > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            if (topReason != null)
              _Line(
                icon: ReasonVisual.of(topReason.key).icon,
                text: l10n.insightsTopReason(
                  ReasonVisual.labelIn(l10n, topReason.key),
                  topReason.count,
                ),
              ),
            if (topVehicle != null)
              _Line(
                icon: Icons.directions_car_rounded,
                text: l10n.insightsTopVehicle(topVehicle),
              ),
            if (insights.busiestHour != null)
              _Line(
                icon: Icons.schedule_rounded,
                text: l10n.insightsBusiestHour(
                  _formatHour(context, insights.busiestHour!),
                ),
              ),
            // A detail line rather than a third stat column: "Emergencies" is
            // a long word, and three columns plus dividers clipped it on a
            // 360dp screen. It also belongs with the other facts more than it
            // belongs beside two percentages.
            if (insights.emergencies > 0)
              _Line(
                icon: Icons.emergency_rounded,
                text: l10n.insightsEmergencyCount(insights.emergencies),
                tint: AppColors.alert,
              ),
          ],
        ],
      ),
    );
  }

  String? _topVehicleLabel() {
    for (final row in insights.byVehicle) {
      for (final vehicle in vehicles) {
        if (vehicle.id == row.key) {
          final plate = vehicle.licensePlate.trim();
          if (plate.isNotEmpty) return plate;
          final model = vehicle.carModel.trim();
          if (model.isNotEmpty) return model;
        }
      }
    }
    return null;
  }

  static String _formatHour(BuildContext context, int hour) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: 0),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  /// Rounded to the unit that matters at that scale — nobody needs "2 minutes
  /// and 14 seconds", and "0 hours" is not an answer.
  static String _formatDuration(AppL10n l10n, Duration d) {
    if (d.inSeconds < 90) return l10n.insightsSeconds(d.inSeconds);
    if (d.inMinutes < 90) return l10n.insightsMinutes(d.inMinutes);
    return l10n.insightsHours(d.inHours);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.emphasis = false,
  });

  final String value;
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppText.metric.copyWith(
            color: emphasis ? AppColors.successDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.border,
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.tint});

  final IconData icon;
  final String text;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tint ?? AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppText.bodySmall.copyWith(
                color: tint ?? AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
