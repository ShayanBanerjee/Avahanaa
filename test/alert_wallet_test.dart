/// The meter's arithmetic, which is the part that has to be right.
///
/// Every case here is one where getting it wrong means either giving service
/// away or — much worse — telling an owner they have no alerts left when they
/// do. The second kind is what most of these guard.
library;

import 'package:avahanaa/models/alert_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 1, 12);

  group('free allowance', () {
    test('a brand-new wallet has the full free allowance', () {
      expect(
        AlertWallet.empty.freeRemaining(now: now),
        AlertBudget.freeAlertsPerCycle,
      );
      expect(AlertWallet.empty.canReceiveFullAlert(now: now), isTrue);
    });

    test('consumed alerts come off the allowance', () {
      final wallet = AlertWallet(freeUsed: 2, cycleStartedAt: now);
      expect(
        wallet.freeRemaining(now: now),
        AlertBudget.freeAlertsPerCycle - 2,
      );
    });

    test('a spent allowance reads as zero, never negative', () {
      // The server should never write more used than the allowance, but a
      // negative here would surface as a *negative balance* in the UI and, worse,
      // would subtract from earned credits in totalRemaining.
      final wallet = AlertWallet(freeUsed: 99, cycleStartedAt: now);
      expect(wallet.freeRemaining(now: now), 0);
    });

    test('the allowance comes back when the cycle lapses', () {
      final wallet = AlertWallet(
        freeUsed: AlertBudget.freeAlertsPerCycle,
        cycleStartedAt: now.subtract(AlertBudget.cycle),
      );
      // Rolled over client-side rather than waiting for the server's write, so
      // that nobody is shown "0 left" when their next alert is in fact free.
      expect(
        wallet.freeRemaining(now: now),
        AlertBudget.freeAlertsPerCycle,
      );
      expect(wallet.canReceiveFullAlert(now: now), isTrue);
    });

    test('a cycle start far in the past rolls forward, not to the epoch', () {
      final wallet = AlertWallet(
        freeUsed: 3,
        cycleStartedAt: now.subtract(AlertBudget.cycle * 7),
      );
      final start = wallet.cycleStart(now: now);
      expect(now.difference(start) < AlertBudget.cycle, isTrue);
      expect(wallet.cycleRenewsAt(now: now).isAfter(now), isTrue);
    });
  });

  group('earned credits', () {
    test('credits add on top of the free allowance', () {
      final wallet = AlertWallet(
        freeUsed: AlertBudget.freeAlertsPerCycle,
        cycleStartedAt: now,
        earnedCredits: 2,
      );
      expect(wallet.freeRemaining(now: now), 0);
      expect(wallet.totalRemaining(now: now), 2);
      expect(wallet.canReceiveFullAlert(now: now), isTrue);
    });

    test('headroom stops at the cap and never goes negative', () {
      expect(
        AlertWallet(earnedCredits: AlertBudget.maxEarnedCredits).creditHeadroom,
        0,
      );
      expect(
        AlertWallet(
          earnedCredits: AlertBudget.maxEarnedCredits + 5,
        ).creditHeadroom,
        0,
      );
    });
  });

  group('subscription', () {
    test('an unexpired paid plan is unmetered', () {
      final wallet = AlertWallet(
        plan: AvahanaaPlan.monthly,
        planExpiresAt: now.add(const Duration(days: 20)),
        freeUsed: AlertBudget.freeAlertsPerCycle,
        cycleStartedAt: now,
      );
      expect(wallet.isSubscribed(now: now), isTrue);
      expect(wallet.canReceiveFullAlert(now: now), isTrue);
      // A subscriber is never nudged to top up, even at a zero balance.
      expect(wallet.needsTopUp(now: now), isFalse);
    });

    test('an expired plan lapses on its own', () {
      // The grant is a date rather than a boolean precisely so a missed
      // renewal notification degrades instead of giving service away forever.
      final wallet = AlertWallet(
        plan: AvahanaaPlan.weekly,
        planExpiresAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(wallet.isSubscribed(now: now), isFalse);
    });

    test('a paid plan with no expiry is not trusted', () {
      final wallet = AlertWallet(plan: AvahanaaPlan.yearly);
      expect(wallet.isSubscribed(now: now), isFalse);
    });
  });

  group('the top-up nudge', () {
    test('fires at one remaining, not at zero', () {
      // The whole design brief is that nobody discovers the meter at the moment
      // somebody is standing next to their car.
      final oneLeft = AlertWallet(
        freeUsed: AlertBudget.freeAlertsPerCycle - 1,
        cycleStartedAt: now,
      );
      expect(oneLeft.totalRemaining(now: now), 1);
      expect(oneLeft.needsTopUp(now: now), isTrue);

      final twoLeft = AlertWallet(
        freeUsed: AlertBudget.freeAlertsPerCycle - 2,
        cycleStartedAt: now,
      );
      expect(twoLeft.needsTopUp(now: now), isFalse);
    });
  });

  group('plan identity', () {
    test('product ids resolve back to their tier', () {
      for (final plan in AvahanaaPlan.values) {
        final productId = plan.productId;
        if (productId == null) continue;
        expect(AvahanaaPlan.fromProductId(productId), plan);
      }
    });

    test('an unknown product id resolves to null, not to free', () {
      // Silently downgrading a paying subscriber because this build predates
      // their tier is the worst available reading of an unknown id.
      expect(AvahanaaPlan.fromProductId('avahanaa_plus_lifetime'), isNull);
    });

    test('every paid tier is purchasable and free is not', () {
      expect(
        AvahanaaPlan.purchasableProductIds.length,
        AvahanaaPlan.values.where((p) => p.isPaid).length,
      );
      expect(AvahanaaPlan.free.productId, isNull);
    });

    test('a plan id that is not recognised falls back to free', () {
      expect(AvahanaaPlan.fromId('platinum'), AvahanaaPlan.free);
      expect(AvahanaaPlan.fromId(null), AvahanaaPlan.free);
    });
  });

  group('the safety floor', () {
    test('emergency is on the always-free list', () {
      // Mirrored by ALWAYS_FREE_REASONS in the backend. If this ever stops
      // being true, a paywall has been placed in front of a fire.
      expect(AlertBudget.emergencyIsAlwaysFree, contains('emergency'));
    });

    test('a wallet that failed to load reads as a fresh cycle', () {
      // AlertWallet.fromMap is handed an empty map on a read failure, and the
      // safe direction to be wrong in is "you have alerts", not "you do not".
      expect(AlertWallet.fromMap(null), AlertWallet.empty);
      expect(AlertWallet.fromMap(const {}).canReceiveFullAlert(now: now), isTrue);
    });
  });
}
