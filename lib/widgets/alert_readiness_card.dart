/// The card that appears when this phone will not wake its owner.
///
/// Silent when everything is fine — which is the whole design. A permanent
/// "notifications: OK" panel is read once and then never again, so by the time
/// it turns red nobody is looking at it. This is absent until it has something
/// to say, and then it is the first thing on the alerts screen.
///
/// One problem, one sentence, one button. A card listing four faults reads as
/// "this app is broken" and gets dismissed; the same card naming the single
/// most damaging one gets fixed. [ReadinessReport.headline] picks it.
///
/// Amber, not alert red. Red in this app means "somebody is at your vehicle",
/// and spending it on a settings problem is how people learn to discount the
/// colour that matters.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/alert_readiness.dart';
import '../theme/app_theme.dart';
import 'metal.dart';
import 'ui_kit.dart';

class AlertReadinessCard extends StatefulWidget {
  const AlertReadinessCard({
    super.key,
    required this.report,
    required this.onFixed,
    required this.onOpenPreference,
  });

  final ReadinessReport report;

  /// Called after a permission was granted, so the caller can re-inspect.
  final VoidCallback onFixed;

  /// Sends the owner to the switch in this app's own settings — the one thing
  /// here that no permission dialog can fix.
  final VoidCallback onOpenPreference;

  @override
  State<AlertReadinessCard> createState() => _AlertReadinessCardState();
}

class _AlertReadinessCardState extends State<AlertReadinessCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final check = widget.report.headline;
    if (check == null) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final blocking = widget.report.failures.contains(check);

    return AppCard(
      color: blocking ? AppColors.warningTint : AppColors.infoSurface,
      borderColor: blocking ? AppColors.warning : AppColors.infoBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconBadge(
                icon: blocking
                    ? Icons.notifications_off_rounded
                    : Icons.info_rounded,
                color: blocking ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(l10n, check),
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _body(l10n, check),
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          MetalButton(
            label: _cta(l10n, check),
            icon: Icons.tune_rounded,
            palette: blocking ? MetalPalette.brand : MetalPalette.slate,
            foreground: blocking ? AppColors.onDark : AppColors.textPrimary,
            height: 48,
            busy: _working,
            onPressed: () => _act(check),
          ),
        ],
      ),
    );
  }

  Future<void> _act(ReadinessCheck check) async {
    if (check == ReadinessCheck.appPreference) {
      widget.onOpenPreference();
      return;
    }

    setState(() => _working = true);
    await AlertReadiness.request(check);
    if (!mounted) return;
    setState(() => _working = false);
    // Re-inspect either way. A refusal is still new information — the card
    // should not keep offering a dialog the owner has now declined twice.
    widget.onFixed();
  }

  static String _title(AppL10n l10n, ReadinessCheck check) => switch (check) {
    ReadinessCheck.notificationPermission => l10n.readinessPermissionTitle,
    ReadinessCheck.appPreference => l10n.readinessPreferenceTitle,
    ReadinessCheck.pushToken => l10n.readinessTokenTitle,
    ReadinessCheck.fullScreenIntent => l10n.readinessFullScreenTitle,
  };

  static String _body(AppL10n l10n, ReadinessCheck check) => switch (check) {
    ReadinessCheck.notificationPermission => l10n.readinessPermissionBody,
    ReadinessCheck.appPreference => l10n.readinessPreferenceBody,
    ReadinessCheck.pushToken => l10n.readinessTokenBody,
    ReadinessCheck.fullScreenIntent => l10n.readinessFullScreenBody,
  };

  static String _cta(AppL10n l10n, ReadinessCheck check) => switch (check) {
    ReadinessCheck.appPreference => l10n.readinessPreferenceCta,
    ReadinessCheck.pushToken => l10n.readinessTokenCta,
    _ => l10n.readinessGrantCta,
  };
}
