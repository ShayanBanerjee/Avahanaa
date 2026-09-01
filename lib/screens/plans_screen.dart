/// The paywall — or rather, the meter's escape hatch.
///
/// Calm mode. Nobody arrives here mid-emergency; they arrive because the home
/// screen said they were running low, or because they tapped the balance out of
/// curiosity. So it can afford to explain itself, and it should: a meter on
/// safety alerts is a thing people are entitled to be suspicious of, and the
/// answer to that suspicion is to state the carve-outs on the same screen as
/// the prices rather than in a support article.
///
/// Two ways off the meter, presented as equals rather than as a real option and
/// a decoy: watch ads, or subscribe. The ad path is genuinely sufficient for
/// somebody whose car is alerted twice a year, and pretending otherwise to push
/// a subscription would be the kind of dark pattern that gets an app pulled.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alert_wallet.dart';
import '../services/billing_service.dart';
import '../services/rewarded_ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_header.dart';
import '../widgets/metal.dart';
import '../widgets/ui_kit.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({
    super.key,
    required this.wallet,
    required this.onWatchAd,
  });

  final AlertWallet wallet;

  /// Runs one rewarded ad and resolves to whether a credit was earned. Owned by
  /// the caller so that the ad + claim round trip has exactly one
  /// implementation, shared with the home screen's top-up button.
  final Future<bool> Function() onWatchAd;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final BillingService _billing = BillingService.instance;

  StreamSubscription<PurchaseResult>? _purchases;
  AvahanaaPlan? _purchasing;
  bool _watchingAd = false;
  int _adsThisSitting = 0;

  @override
  void initState() {
    super.initState();
    // Idempotent: the app starts billing at launch, and this is here for the
    // case where the store was unreachable then and might not be now.
    unawaited(_billing.start());
    unawaited(RewardedAdService.instance.preload());
    _purchases = _billing.results.listen(_onPurchaseResult);
  }

  @override
  void dispose() {
    _purchases?.cancel();
    super.dispose();
  }

  void _onPurchaseResult(PurchaseResult result) {
    if (!mounted) return;
    final l10n = AppL10n.of(context);

    switch (result.outcome) {
      case PurchaseOutcome.pending:
        // Google Play's own sheet is on screen. Anything we show is behind it.
        return;
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        setState(() => _purchasing = null);
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          l10n.planActivated,
          kind: AppSnackKind.success,
        );
        // The wallet stream on the screen behind this one repaints on its own
        // the moment the backend writes the grant, so there is nothing to
        // refresh here — popping is the whole completion.
        Navigator.of(context).maybePop();
        return;
      case PurchaseOutcome.cancelled:
        setState(() => _purchasing = null);
        return;
      case PurchaseOutcome.failed:
      case PurchaseOutcome.unavailable:
        setState(() => _purchasing = null);
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          result.message ?? l10n.planPurchaseFailed,
          kind: AppSnackKind.error,
        );
        return;
    }
  }

  Future<void> _buy(PlanOffer offer) async {
    setState(() => _purchasing = offer.plan);
    final result = await _billing.purchase(offer.plan);
    if (!mounted) return;
    if (result.outcome != PurchaseOutcome.pending) {
      _onPurchaseResult(result);
    }
  }

  Future<void> _watchAd() async {
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    final earned = await widget.onWatchAd();
    if (!mounted) return;
    setState(() {
      _watchingAd = false;
      if (earned) _adsThisSitting++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final wallet = widget.wallet;
    final subscribed = wallet.isSubscribed();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeroSurface(
              padding: EdgeInsets.zero,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.onDark,
                            ),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subscribed ? l10n.planActiveTitle : l10n.plansTitle,
                        style: AppText.displayMedium.copyWith(
                          color: AppColors.onDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subscribed
                            ? l10n.planActiveBody
                            : l10n.plansSubtitle(
                                AlertBudget.freeAlertsPerCycle,
                              ),
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.onDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverList.list(
              children: [
                _PromiseCard(),
                const SizedBox(height: AppSpacing.xl),
                if (!subscribed) ...[
                  SectionHeader(
                    overline: l10n.plansFreeOverline,
                    title: l10n.plansAdTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AdCard(
                    wallet: wallet,
                    watched: _adsThisSitting,
                    busy: _watchingAd,
                    onWatch: wallet.creditHeadroom > 0 ? _watchAd : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                SectionHeader(
                  overline: l10n.plansPaidOverline,
                  title: subscribed ? l10n.plansChangeTitle : l10n.plansPaidTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                ValueListenableBuilder<List<PlanOffer>>(
                  valueListenable: _billing.offers,
                  builder: (context, offers, _) {
                    final weekly = offers.firstWhere(
                      (o) => o.plan == AvahanaaPlan.weekly,
                      orElse: () => offers.first,
                    );
                    return Column(
                      children: [
                        for (final offer in offers) ...[
                          _PlanCard(
                            offer: offer,
                            reference: weekly,
                            current: wallet.plan == offer.plan && subscribed,
                            recommended: offer.plan == AvahanaaPlan.monthly,
                            busy: _purchasing == offer.plan,
                            onTap: _purchasing == null
                                ? () => _buy(offer)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: _billing.restore,
                    child: Text(l10n.planRestore),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.planLegalNote,
                  style: AppText.caption.copyWith(
                    color: AppColors.textTertiary,
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

/// What the meter will never do.
///
/// First card on the screen, above the prices, on purpose. Somebody who has
/// just been told their safety alerts are metered deserves the carve-outs
/// before the pitch, not after it.
class _PromiseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final promises = <(IconData, String)>[
      (Icons.emergency_rounded, l10n.plansPromiseEmergency),
      (Icons.notifications_active_rounded, l10n.plansPromiseNeverSilent),
      (Icons.visibility_off_rounded, l10n.plansPromisePrivate),
    ];

    return AppCard(
      color: AppColors.infoSurface,
      borderColor: AppColors.infoBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < promises.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(promises[i].$1, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    promises[i].$2,
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.wallet,
    required this.watched,
    required this.busy,
    required this.onWatch,
  });

  final AlertWallet wallet;
  final int watched;
  final bool busy;
  final VoidCallback? onWatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final full = wallet.creditHeadroom <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.plansAdBody(AlertBudget.adsPerBatch, AlertBudget.adsPerBatch),
            style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Progress through this sitting. Each pip fills as an ad completes,
          // and each one is already banked — quitting after two keeps two, and
          // showing the pips is how that promise is made visible.
          Row(
            children: [
              for (var i = 0; i < AlertBudget.adsPerBatch; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.normal,
                    curve: AppMotion.entrance,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < watched
                          ? AppColors.success
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            full
                ? l10n.plansAdCapped(AlertBudget.maxEarnedCredits)
                : l10n.plansAdProgress(watched, AlertBudget.adsPerBatch),
            style: AppText.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          MetalButton(
            label: l10n.plansAdCta,
            icon: Icons.play_circle_outline_rounded,
            palette: MetalPalette.slate,
            foreground: AppColors.textPrimary,
            busy: busy,
            onPressed: onWatch,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.offer,
    required this.reference,
    required this.current,
    required this.recommended,
    required this.busy,
    required this.onTap,
  });

  final PlanOffer offer;
  final PlanOffer reference;
  final bool current;
  final bool recommended;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final savings = offer.savingsPercentAgainst(reference);

    return AppCard(
      onTap: busy ? null : onTap,
      borderColor: recommended ? AppColors.primary : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _label(l10n, offer.plan),
                        style: AppText.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (recommended && !current) ...[
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label: l10n.plansRecommended,
                        color: AppColors.primary,
                      ),
                    ],
                    if (current) ...[
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label: l10n.plansCurrent,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  savings > 0
                      ? l10n.plansSaving(savings)
                      : _period(l10n, offer.plan),
                  style: AppText.bodySmall.copyWith(
                    color: savings > 0
                        ? AppColors.successDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              offer.price,
              style: AppText.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
        ],
      ),
    );
  }

  static String _label(AppL10n l10n, AvahanaaPlan plan) => switch (plan) {
    AvahanaaPlan.weekly => l10n.planWeekly,
    AvahanaaPlan.monthly => l10n.planMonthly,
    AvahanaaPlan.yearly => l10n.planYearly,
    AvahanaaPlan.free => l10n.planFree,
  };

  static String _period(AppL10n l10n, AvahanaaPlan plan) => switch (plan) {
    AvahanaaPlan.weekly => l10n.planPerWeek,
    AvahanaaPlan.monthly => l10n.planPerMonth,
    AvahanaaPlan.yearly => l10n.planPerYear,
    AvahanaaPlan.free => '',
  };
}
