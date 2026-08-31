/// "Which car, and where?" — answered on the alert itself.
///
/// An owner with three vehicles gets an alert and has no idea which windscreen
/// somebody was standing at. The plate on the card answers the first half; this
/// answers the second, and turns "someone is at your car" into "someone is at
/// your car outside the office", which is the difference between anxiety and a
/// decision.
///
/// Shown only when the person scanning chose to share it, which is a minority
/// of alerts. Everything here is additive: the sheet reads correctly with this
/// widget absent, and it is absent most of the time.
///
/// Calm-mode styling on a panic-mode sheet, deliberately. This is reference
/// information under the thing that matters, not a second alarm — the header
/// band above it already carries the severity, and a second saturated surface
/// would compete with it.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/scan_location.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

class ScanLocationCard extends StatelessWidget {
  const ScanLocationCard({super.key, required this.location});

  final ScanLocation location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final accuracy = location.accuracyMetres;

    return Semantics(
      button: true,
      label: l10n.alertsOpenInMaps,
      child: AppCard(
        onTap: () => _openMap(context),
        child: Row(
          children: [
            AppIconBadge(
              icon: Icons.place_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.alertsWhereTitle,
                    style: AppText.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // The accuracy is stated rather than implied. A pin drawn
                  // identically for a 110 m fix and a 2 km one is lying about
                  // one of them, and the owner is about to walk somewhere on
                  // the strength of it.
                  Text(
                    accuracy == null
                        ? l10n.alertsWhereApprox
                        : l10n.alertsWhereAccuracy(accuracy),
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppL10n.of(context);

    // `geo:` first, because it opens whichever map app the owner actually
    // uses. It fails on a device with none registered — and on the emulator,
    // which is where this is usually first tried — so the https URL is the
    // fallback rather than the other way round.
    for (final uri in [
      Uri.parse(location.geoUri),
      Uri.parse(location.webMapUrl),
    ]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {
        // Try the next one. A missing handler throws on some Android builds
        // rather than returning false.
      }
    }

    if (!context.mounted) return;
    showAppSnackBar(messenger, l10n.alertsNoMapApp, kind: AppSnackKind.error);
  }
}
