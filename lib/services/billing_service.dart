/// Google Play subscriptions — the way an owner buys out of the meter entirely.
///
/// Three tiers, all the same product: the alert meter goes away. Weekly for
/// somebody who parks badly for a week, monthly for the ordinary case, yearly
/// for the discount.
///
/// ## The app never decides that anybody is subscribed
///
/// A purchase arriving here proves only that this phone said one did. What
/// grants service is [AvahanaaApi.verifySubscription]: the backend takes the
/// purchase token to Google's Play Developer API, asks what it actually bought
/// and when it expires, and writes `plan` / `planExpiresAt` on the user
/// document — fields the Firestore rules forbid the client from touching. This
/// class's job ends at handing the token over.
///
/// Renewals and cancellations never come through here at all. They arrive at
/// the backend as Real-Time Developer Notifications, because a subscription
/// that renewed at 3am must extend on a phone that is switched off.
///
/// ## Prices
///
/// The numbers in [PlanOffer.fallbackPrice] are for the one frame before the
/// store answers, and for the store being unreachable. The authoritative price
/// is always [ProductDetails.price], which arrives already localised and
/// already correct about tax — showing a hardcoded rupee figure to somebody
/// Play is charging in another currency is a store policy violation as well as
/// a lie.
library;

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/alert_wallet.dart';
import 'avahanaa_api.dart';

/// One row in the plan picker.
class PlanOffer {
  const PlanOffer({
    required this.plan,
    required this.fallbackPrice,
    required this.perWeekPaise,
    this.details,
  });

  final AvahanaaPlan plan;

  /// Shown until the store responds. Never used for anything but display.
  final String fallbackPrice;

  /// Normalised cost per week, in paise, for the "save 38%" badge.
  ///
  /// Computed from the fallback rather than the live price because it is a
  /// comparison between our own tiers, and mixing a live figure with a stale
  /// one produces a badge that lies in whichever direction the store moved.
  final int perWeekPaise;

  /// The live store product, once queried.
  final ProductDetails? details;

  String get price => details?.price ?? fallbackPrice;

  bool get isPurchasable => details != null;

  PlanOffer withDetails(ProductDetails? value) => PlanOffer(
    plan: plan,
    fallbackPrice: fallbackPrice,
    perWeekPaise: perWeekPaise,
    details: value,
  );

  /// How much cheaper this is per week than [other], as a whole percent.
  /// Returns 0 when it is not cheaper, so the caller can hide the badge.
  int savingsPercentAgainst(PlanOffer other) {
    if (other.perWeekPaise <= 0 || perWeekPaise >= other.perWeekPaise) return 0;
    final saved = other.perWeekPaise - perWeekPaise;
    return (saved * 100 / other.perWeekPaise).round();
  }
}

/// How a purchase attempt ended, in terms the UI can speak.
enum PurchaseOutcome { purchased, restored, cancelled, pending, failed, unavailable }

class PurchaseResult {
  const PurchaseResult(this.outcome, [this.message]);
  final PurchaseOutcome outcome;
  final String? message;
  bool get isSuccess =>
      outcome == PurchaseOutcome.purchased || outcome == PurchaseOutcome.restored;
}

class BillingService {
  BillingService._();

  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// The catalogue, in the order the picker shows it.
  ///
  /// Monthly sits in the middle and is the one marked recommended, because it
  /// is the tier that matches how often a parked car actually gets alerted —
  /// weekly is for a bad week, yearly is a commitment made by people who have
  /// already had the bad week.
  static final List<PlanOffer> _catalogue = <PlanOffer>[
    const PlanOffer(
      plan: AvahanaaPlan.weekly,
      fallbackPrice: '₹129',
      perWeekPaise: 12900,
    ),
    const PlanOffer(
      plan: AvahanaaPlan.monthly,
      fallbackPrice: '₹349',
      // A month is treated as 4.345 weeks so the comparison is honest rather
      // than flattering: rounding it to 4 would overstate the monthly saving.
      perWeekPaise: 8032,
    ),
    const PlanOffer(
      plan: AvahanaaPlan.yearly,
      fallbackPrice: '₹1,999',
      perWeekPaise: 3833,
    ),
  ];

  final ValueNotifier<List<PlanOffer>> offers =
      ValueNotifier<List<PlanOffer>>(List.unmodifiable(_catalogue));

  /// True once the store has been reached and the catalogue is live.
  final ValueNotifier<bool> storeAvailable = ValueNotifier<bool>(false);

  /// Emits every time a purchase finishes verifying, so open screens refresh.
  final StreamController<PurchaseResult> _results =
      StreamController<PurchaseResult>.broadcast();

  Stream<PurchaseResult> get results => _results.stream;

  bool _started = false;

  /// Connects to the store and starts listening for purchases.
  ///
  /// Must be running before any purchase is attempted, and must keep running
  /// afterwards: Play delivers a purchase asynchronously, sometimes minutes
  /// later if it was pending on a bank confirmation, and an unlistened stream
  /// means a paid subscription that never activates.
  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;

    final available = await _iap.isAvailable();
    storeAvailable.value = available;
    if (!available) {
      log('In-app purchases unavailable on this device.');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) => log('Purchase stream error: $e'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(
      AvahanaaPlan.purchasableProductIds,
    );

    if (response.error != null) {
      log('Store query failed: ${response.error!.message}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      // Almost always means the products have not been created in the Play
      // Console yet, or the build is not signed with the upload key. Worth a
      // loud log line: it presents to the user as an inexplicably empty
      // paywall.
      log('Products missing from the store: ${response.notFoundIDs.join(", ")}');
    }

    final byId = {for (final p in response.productDetails) p.id: p};
    offers.value = List.unmodifiable(
      _catalogue.map((offer) => offer.withDetails(byId[offer.plan.productId])),
    );
  }

  /// Starts a purchase. Resolves when the store hands control back, which is
  /// *not* when service is granted — that arrives on [results] after the
  /// backend has verified.
  Future<PurchaseResult> purchase(AvahanaaPlan plan) async {
    if (!storeAvailable.value) {
      return const PurchaseResult(
        PurchaseOutcome.unavailable,
        'Google Play billing is not available on this device.',
      );
    }

    final offer = offers.value.firstWhere(
      (o) => o.plan == plan,
      orElse: () => _catalogue.first,
    );
    final details = offer.details;
    if (details == null) {
      return const PurchaseResult(
        PurchaseOutcome.unavailable,
        'That plan is not available right now.',
      );
    }

    try {
      // `buyNonConsumable` is correct for subscriptions on both stores — a
      // subscription is not consumed, it is held.
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!started) {
        return const PurchaseResult(
          PurchaseOutcome.failed,
          'Google Play could not start the purchase.',
        );
      }
      return const PurchaseResult(PurchaseOutcome.pending);
    } catch (e, stack) {
      log('Purchase failed to start', error: e, stackTrace: stack);
      return const PurchaseResult(
        PurchaseOutcome.failed,
        'Google Play could not start the purchase.',
      );
    }
  }

  /// Re-delivers purchases this account already owns.
  ///
  /// Needed after a reinstall or a new device, and Play policy requires it to
  /// be reachable from the UI. Results arrive on [results] like any other
  /// purchase.
  Future<void> restore() async {
    if (!storeAvailable.value) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      log('Restore failed: $e');
      _results.add(const PurchaseResult(
        PurchaseOutcome.failed,
        'Could not reach Google Play to restore purchases.',
      ));
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _results.add(const PurchaseResult(PurchaseOutcome.pending));
          break;

        case PurchaseStatus.canceled:
          _results.add(const PurchaseResult(PurchaseOutcome.cancelled));
          break;

        case PurchaseStatus.error:
          log('Purchase error: ${purchase.error?.message}');
          _results.add(PurchaseResult(
            PurchaseOutcome.failed,
            purchase.error?.message,
          ));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verify(purchase);
          break;
      }

      // Acknowledging is not optional. Play automatically refunds any
      // subscription left unacknowledged for three days, and the refund is
      // silent — the user keeps the app and loses the charge, and we find out
      // from a support email.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verify(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) {
      _results.add(const PurchaseResult(
        PurchaseOutcome.failed,
        'Google Play did not return a receipt.',
      ));
      return;
    }

    final result = await AvahanaaApi.instance.verifySubscription(
      productId: purchase.productID,
      purchaseToken: token,
    );

    if (result.isOk) {
      _results.add(PurchaseResult(
        purchase.status == PurchaseStatus.restored
            ? PurchaseOutcome.restored
            : PurchaseOutcome.purchased,
      ));
      return;
    }

    // The charge went through and the grant did not. Say so honestly rather
    // than reporting a generic failure: the money has left, and telling
    // somebody the purchase failed when it did not is how a refund request
    // becomes a one-star review. The backend reconciles from Play's own
    // notifications, so this usually resolves itself within a minute.
    log('Subscription verification failed: ${result.error}');
    _results.add(PurchaseResult(
      PurchaseOutcome.failed,
      result.isRetryable
          ? 'Payment received. Activating — this can take a minute.'
          : result.error,
    ));
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _results.close();
    _started = false;
  }
}
