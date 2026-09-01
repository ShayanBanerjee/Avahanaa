/// The alert wallet — who is allowed to be alarmed, and how many times.
///
/// Avahanaa's costs are real and per-alert: a Cloud Function run, an FCM push,
/// and two scheduled reminders, for a product whose users are not the ones
/// paying attention to it. This file is the meter that pays for that.
///
/// The shape of the deal:
///
/// - Every owner gets [freeAlertsPerCycle] full-strength alerts per 30-day
///   cycle, free, forever. Nobody has to do anything to get those.
/// - Past that, one rewarded ad buys one more alert
///   ([creditsPerAd]) — the UI frames it as "three ads, three alerts" because
///   that is the batch people actually sit through.
/// - Or a subscription removes the meter entirely. See [AvahanaaPlan].
///
/// ## Two things the meter must never do
///
/// **It must never silence an emergency.** [AlertBudget.emergencyIsAlwaysFree]
/// is checked before the balance is, on both sides of the wire. Someone
/// reporting a fire or a crash is not a billing event.
///
/// **It must never make an owner uncontactable.** At zero balance the alert is
/// still written to Firestore and still pushed — as a quiet notification that
/// says somebody needs them and the details are behind a restored balance. What
/// is withheld is the *alarm*: the max-importance channel, the full-screen
/// intent, and the +3/+15 minute reminders. The scanner is told none of this
/// and sees the ordinary success screen, because the state of a stranger's
/// subscription is not their business and "this owner is unmetered" is not a
/// signal anyone should be able to probe for.
///
/// Both carve-outs are constants here and in `functions/index.js`. Turning them
/// off is a deliberate act, not a refactor.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// A paid tier. `free` is the absence of one.
///
/// The ids are persisted to Firestore and sent to Google Play as product ids,
/// so they are permanent: an owner who subscribed under `avahanaa_plus_weekly`
/// keeps renewing against that id for as long as they stay subscribed. Add a
/// tier, never rename one.
enum AvahanaaPlan {
  free('free', null),
  weekly('weekly', 'avahanaa_plus_weekly'),
  monthly('monthly', 'avahanaa_plus_monthly'),
  yearly('yearly', 'avahanaa_plus_yearly');

  const AvahanaaPlan(this.id, this.productId);

  /// The value stored in `users/{uid}.plan`.
  final String id;

  /// The Google Play subscription product id, or null for [AvahanaaPlan.free].
  ///
  /// These must exist in the Play Console before a build that references them
  /// can complete a purchase. Creating them is a console action, not a code
  /// change — see `docs/monetization.md`.
  final String? productId;

  bool get isPaid => this != AvahanaaPlan.free;

  static AvahanaaPlan fromId(String? value) {
    for (final plan in AvahanaaPlan.values) {
      if (plan.id == value) return plan;
    }
    return AvahanaaPlan.free;
  }

  /// Resolves a Play product id back to a tier.
  ///
  /// Returns null for an unknown id rather than falling back to [free]: an id
  /// this build does not recognise means the app is older than the catalogue,
  /// and quietly downgrading a paying subscriber to free is the worst possible
  /// reading of that.
  static AvahanaaPlan? fromProductId(String productId) {
    for (final plan in AvahanaaPlan.values) {
      if (plan.productId == productId) return plan;
    }
    return null;
  }

  /// Every purchasable product id, for the store query at startup.
  static Set<String> get purchasableProductIds => {
    for (final plan in AvahanaaPlan.values)
      if (plan.productId != null) plan.productId!,
  };
}

/// The numbers the meter runs on.
///
/// Duplicated in `functions/index.js` as `ALERT_BUDGET`, and the server's copy
/// is the authoritative one — the client's exists so the UI can show a balance
/// without a round trip, never so it can decide an outcome.
abstract final class AlertBudget {
  /// Full-strength alerts every owner gets each cycle without paying or
  /// watching anything.
  static const int freeAlertsPerCycle = 3;

  /// How long a free cycle lasts before [AlertWallet.freeUsed] resets.
  static const Duration cycle = Duration(days: 30);

  /// What one completed rewarded ad is worth.
  static const int creditsPerAd = 1;

  /// How many ads the UI asks for in one sitting. Purely presentational —
  /// each ad is banked the moment it completes, so a person who watches two
  /// and walks away keeps two.
  static const int adsPerBatch = 3;

  /// Ceiling on ad-earned credits.
  ///
  /// Without a cap, an afternoon of ad-watching buys a year of alerts and the
  /// subscription has nothing to sell. With one, ads cover the occasional
  /// overflow month and anyone whose vehicle is genuinely alerted often
  /// subscribes — which is the honest sort of both.
  static const int maxEarnedCredits = 12;

  /// Reasons that are delivered at full strength no matter what the balance
  /// says.
  ///
  /// Mirrored by `ALWAYS_FREE_REASONS` in `functions/index.js`. Keep both
  /// sides identical: the server decides, and a client that disagrees will
  /// render a balance that does not match what actually happened.
  static const Set<String> emergencyIsAlwaysFree = {'emergency'};
}

/// A snapshot of one owner's alert budget.
///
/// Read from `users/{uid}`. Every field here is **server-written**: the
/// Firestore rules exclude all of them from the owner's own update allowlist,
/// because a balance a client can write is not a balance. The app streams it
/// and renders it; it never sets it.
class AlertWallet {
  const AlertWallet({
    this.plan = AvahanaaPlan.free,
    this.planExpiresAt,
    this.earnedCredits = 0,
    this.freeUsed = 0,
    this.cycleStartedAt,
    this.lifetimeAlertsReceived = 0,
    this.lifetimeAdsWatched = 0,
  });

  final AvahanaaPlan plan;

  /// When the current subscription period ends.
  ///
  /// Kept as a hard date rather than a boolean so an expired subscription
  /// degrades on its own if a renewal notification is ever missed. A stale
  /// `true` would give away service forever; a stale date simply lapses.
  final DateTime? planExpiresAt;

  /// Credits bought with attention. Capped at [AlertBudget.maxEarnedCredits].
  final int earnedCredits;

  /// Free alerts consumed in the current cycle.
  final int freeUsed;

  final DateTime? cycleStartedAt;

  final int lifetimeAlertsReceived;
  final int lifetimeAdsWatched;

  static const AlertWallet empty = AlertWallet();

  factory AlertWallet.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return AlertWallet(
      plan: AvahanaaPlan.fromId(map['plan'] as String?),
      planExpiresAt: (map['planExpiresAt'] as Timestamp?)?.toDate(),
      earnedCredits: _asInt(map['alertCredits']),
      freeUsed: _asInt(map['freeAlertsUsed']),
      cycleStartedAt: (map['cycleStartedAt'] as Timestamp?)?.toDate(),
      lifetimeAlertsReceived: _asInt(map['lifetimeAlertsReceived']),
      lifetimeAdsWatched: _asInt(map['lifetimeAdsWatched']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Whether the subscription is live *right now*.
  ///
  /// Takes [now] so the caller can pass a single clock reading and have the
  /// whole widget tree agree, and so tests do not have to sleep.
  bool isSubscribed({DateTime? now}) {
    if (!plan.isPaid) return false;
    final expiry = planExpiresAt;
    if (expiry == null) return false;
    return expiry.isAfter(now ?? DateTime.now());
  }

  /// Where the current 30-day cycle started, resolving the never-started case.
  DateTime cycleStart({DateTime? now}) {
    final started = cycleStartedAt;
    final clock = now ?? DateTime.now();
    if (started == null) return clock;
    // A cycle that ran out is treated as having rolled over even before the
    // server writes the reset, so the UI does not show "0 left" to somebody
    // whose next alert will in fact be free.
    var start = started;
    while (clock.difference(start) >= AlertBudget.cycle) {
      start = start.add(AlertBudget.cycle);
    }
    return start;
  }

  DateTime cycleRenewsAt({DateTime? now}) =>
      cycleStart(now: now).add(AlertBudget.cycle);

  /// Free alerts still available in this cycle, after rollover.
  int freeRemaining({DateTime? now}) {
    final clock = now ?? DateTime.now();
    final started = cycleStartedAt;
    final rolledOver =
        started == null || clock.difference(started) >= AlertBudget.cycle;
    final used = rolledOver ? 0 : freeUsed;
    final remaining = AlertBudget.freeAlertsPerCycle - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Everything the owner can spend: free allowance plus banked credits.
  int totalRemaining({DateTime? now}) =>
      freeRemaining(now: now) + earnedCredits;

  /// Whether the next non-emergency alert arrives as an alarm.
  bool canReceiveFullAlert({DateTime? now}) =>
      isSubscribed(now: now) || totalRemaining(now: now) > 0;

  /// True when the owner should be nudged before they are caught out.
  ///
  /// The nudge is worth showing at one remaining rather than zero: the point
  /// of the meter is that nobody discovers it at the moment it matters.
  bool needsTopUp({DateTime? now}) =>
      !isSubscribed(now: now) && totalRemaining(now: now) <= 1;

  int get creditHeadroom {
    final room = AlertBudget.maxEarnedCredits - earnedCredits;
    return room < 0 ? 0 : room;
  }

  AlertWallet copyWith({
    AvahanaaPlan? plan,
    DateTime? planExpiresAt,
    int? earnedCredits,
    int? freeUsed,
    DateTime? cycleStartedAt,
    int? lifetimeAlertsReceived,
    int? lifetimeAdsWatched,
  }) {
    return AlertWallet(
      plan: plan ?? this.plan,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      earnedCredits: earnedCredits ?? this.earnedCredits,
      freeUsed: freeUsed ?? this.freeUsed,
      cycleStartedAt: cycleStartedAt ?? this.cycleStartedAt,
      lifetimeAlertsReceived:
          lifetimeAlertsReceived ?? this.lifetimeAlertsReceived,
      lifetimeAdsWatched: lifetimeAdsWatched ?? this.lifetimeAdsWatched,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AlertWallet &&
        other.plan == plan &&
        other.planExpiresAt == planExpiresAt &&
        other.earnedCredits == earnedCredits &&
        other.freeUsed == freeUsed &&
        other.cycleStartedAt == cycleStartedAt &&
        other.lifetimeAlertsReceived == lifetimeAlertsReceived &&
        other.lifetimeAdsWatched == lifetimeAdsWatched;
  }

  @override
  int get hashCode => Object.hash(
    plan,
    planExpiresAt,
    earnedCredits,
    freeUsed,
    cycleStartedAt,
    lifetimeAlertsReceived,
    lifetimeAdsWatched,
  );

  @override
  String toString() =>
      'AlertWallet(plan: ${plan.id}, credits: $earnedCredits, '
      'freeUsed: $freeUsed, expires: $planExpiresAt)';
}
