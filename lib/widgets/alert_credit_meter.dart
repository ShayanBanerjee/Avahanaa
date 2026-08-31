/// The alert budget, made visible before it matters.
///
/// The meter's one real design constraint is that nobody should ever discover
/// it at the moment somebody is standing next to their car. So it lives on the
/// home screen in its calm state — a quiet line saying how many alerts are
/// left — and only escalates to a card with an action when the balance is
/// nearly gone.
///
/// It is deliberately *not* an alert-red surface even at zero. Red in this app
/// means "somebody is at your vehicle" and nothing else; a billing state
/// wearing that colour would teach people to ignore the colour that matters.
/// Empty is amber.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alert_wallet.dart';
import '../theme/app_theme.dart';
import 'metal.dart';
import 'ui_kit.dart';

/// How much room the meter is allowed to take.
enum CreditMeterSize {
  /// A single line, for the home hero. Says the number and gets out of the way.
  inline,

  /// A full card with the top-up action, for the profile and the empty state.
  card,
}

class AlertCreditMeter extends StatelessWidget {
  const AlertCreditMeter({
    super.key,
    required this.wallet,
    required this.onManage,
    this.onWatchAd,
    this.size = CreditMeterSize.card,
    this.busy = false,
  });

  final AlertWallet wallet;

  /// Opens the plan picker.
  final VoidCallback onManage;

  /// Starts a rewarded ad. Null hides the option — on a device with no ads
  /// available, offering one that cannot play is worse than not offering it.
  final VoidCallback? onWatchAd;

  final CreditMeterSize size;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final now = DateTime.now();
    final subscribed = wallet.isSubscribed(now: now);
    final remaining = wallet.totalRemaining(now: now);

    if (size == CreditMeterSize.inline) {
      return _InlineMeter(
        wallet: wallet,
        onManage: onManage,
        subscribed: subscribed,
        remaining: remaining,
      );
    }

    if (subscribed) return _SubscribedCard(wallet: wallet, onManage: onManage);

    final empty = remaining <= 0;
    final low = wallet.needsTopUp(now: now);

    return AppCard(
      color: empty
          ? AppColors.warningTint
          : (low ? AppColors.infoSurface : AppColors.surface),
      borderColor: empty ? AppColors.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: empty ? Icons.battery_alert_rounded : Icons.bolt_rounded,
                color: empty ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empty ? l10n.creditsEmptyTitle : l10n.creditsTitle,
                      style: AppText.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empty
                          ? l10n.creditsEmptyBody
                          : l10n.creditsRemaining(remaining),
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // The number is the point of the card, so it is set at metric
              // scale and animated — a balance that jumps without moving is
              // the one thing people miss when an ad has just paid out.
              AnimatedCounter(
                value: remaining,
                style: AppText.metric.copyWith(
                  color: empty ? AppColors.warning : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _AllowanceBar(wallet: wallet, now: now),
          const SizedBox(height: AppSpacing.lg),
          // Emergencies are never metered, and saying so here is the whole
          // reason this card can exist without being frightening.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.creditsEmergencyAlwaysFree,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (onWatchAd != null) ...[
                Expanded(
                  child: MetalButton(
                    label: l10n.creditsWatchAd(AlertBudget.adsPerBatch),
                    icon: Icons.play_circle_outline_rounded,
                    palette: MetalPalette.slate,
                    foreground: AppColors.textPrimary,
                    height: 48,
                    busy: busy,
                    onPressed: wallet.creditHeadroom > 0 ? onWatchAd : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: MetalButton(
                  label: l10n.creditsGoUnlimited,
                  icon: Icons.all_inclusive_rounded,
                  height: 48,
                  onPressed: onManage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Free allowance and earned credits as two segments of one bar.
///
/// Split rather than summed because they behave differently — the free half
/// comes back on its own next month, the earned half does not — and somebody
/// deciding whether to watch an ad needs to see which half they are burning.
class _AllowanceBar extends StatelessWidget {
  const _AllowanceBar({required this.wallet, required this.now});

  final AlertWallet wallet;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final free = wallet.freeRemaining(now: now);
    final earned = wallet.earnedCredits;
    final total = AlertBudget.freeAlertsPerCycle +
        (earned > 0 ? earned : 0);

    // Pips while they are countable, a proportional bar once they are not.
    //
    // Twelve 20px slivers on a 320dp screen is not a thing anyone counts — it
    // reads as a progress bar with a rendering fault. Past eight the bar says
    // the same thing in the form people actually parse at that size, and the
    // numbers underneath carry the exact figures either way.
    final asPips = total <= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: asPips
                ? Row(
                    children: [
                      for (var i = 0; i < total; i++) ...[
                        Expanded(
                          child: AnimatedContainer(
                            duration: AppMotion.normal,
                            curve: AppMotion.entrance,
                            color: i < free
                                ? AppColors.primary
                                : (i < free + earned
                                      ? AppColors.success
                                      : AppColors.border),
                          ),
                        ),
                        if (i != total - 1) const SizedBox(width: 3),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      if (free > 0)
                        Expanded(
                          flex: free,
                          child: ColoredBox(color: AppColors.primary),
                        ),
                      if (earned > 0)
                        Expanded(
                          flex: earned,
                          child: ColoredBox(color: AppColors.success),
                        ),
                      if (total - free - earned > 0)
                        Expanded(
                          flex: total - free - earned,
                          child: ColoredBox(color: AppColors.border),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppL10n.of(context).creditsBreakdown(
            free,
            earned,
            _daysUntil(wallet.cycleRenewsAt(now: now), now),
          ),
          style: AppText.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  static int _daysUntil(DateTime target, DateTime now) {
    final days = target.difference(now).inDays;
    return days < 0 ? 0 : days;
  }
}

class _SubscribedCard extends StatelessWidget {
  const _SubscribedCard({required this.wallet, required this.onManage});

  final AlertWallet wallet;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AppCard(
      onTap: onManage,
      child: Row(
        children: [
          AppIconBadge(
            icon: Icons.all_inclusive_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planActiveTitle,
                  style: AppText.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.planRenewsOn(
                    MaterialLocalizations.of(context).formatMediumDate(
                      wallet.planExpiresAt ?? DateTime.now(),
                    ),
                  ),
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _InlineMeter extends StatelessWidget {
  const _InlineMeter({
    required this.wallet,
    required this.onManage,
    required this.subscribed,
    required this.remaining,
  });

  final AlertWallet wallet;
  final VoidCallback onManage;
  final bool subscribed;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final empty = !subscribed && remaining <= 0;

    // Pinned ink: this sits on the hero gradient, which does not follow the
    // theme. `AppColors.onDark` here is the difference between legible at
    // night and invisible.
    final foreground = empty ? AppColors.onDark : AppColors.onDarkMuted;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onManage,
        borderRadius: AppRadius.controlAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                subscribed
                    ? Icons.all_inclusive_rounded
                    : (empty ? Icons.battery_alert_rounded : Icons.bolt_rounded),
                size: 15,
                color: foreground,
              ),
              const SizedBox(width: 6),
              Text(
                subscribed
                    ? l10n.planUnlimited
                    : (empty
                          ? l10n.creditsEmptyShort
                          : l10n.creditsRemainingShort(remaining)),
                style: AppText.labelSmall.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
