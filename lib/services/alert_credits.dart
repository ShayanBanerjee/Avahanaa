/// One place where "watch an ad, get a credit" is implemented.
///
/// Three screens offer the top-up — the home hero when the balance runs low,
/// the plan picker, and the empty state on the alerts tab — and all three have
/// to handle the same five outcomes, so none of them implement it.
///
/// The sequence is: show the ad, then ask the backend to look for Google's
/// server-side verification callback. The second half is the interesting one.
/// The credit is granted by that callback, not by this code, and the callback
/// arrives at the backend on Google's schedule — usually within a second, but
/// not always. So the claim is retried a few times before giving up, and giving
/// up is *not* reported as a failure: the credit is still coming, and telling
/// somebody who just watched an ad that it did not count is both wrong and the
/// fastest way to lose them.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/ui_kit.dart';
import 'avahanaa_api.dart';
import 'rewarded_ad_service.dart';

abstract final class AlertCredits {
  /// Runs one rewarded ad and settles the credit.
  ///
  /// Returns true when a credit was earned. Reports its own failures through a
  /// snackbar on [context], so callers only need the boolean to advance a
  /// progress indicator.
  static Future<bool> topUp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppL10n.of(context);

    final attempt = await RewardedAdService.instance.showAd();

    switch (attempt.outcome) {
      case AdOutcome.unavailable:
      case AdOutcome.failed:
        showAppSnackBar(
          messenger,
          l10n.creditsAdUnavailable,
          kind: AppSnackKind.error,
        );
        return false;

      case AdOutcome.dismissed:
        // Not an error. Somebody chose to close the ad, and scolding them for
        // it in red is out of proportion.
        showAppSnackBar(messenger, l10n.creditsAdDismissed);
        return false;

      case AdOutcome.earned:
        break;
    }

    final token = attempt.rewardToken;
    if (token == null) return false;

    // The wallet stream repaints from Firestore the moment the backend writes
    // the credit, so nothing here has to plumb the new balance back. This is
    // only a nudge to settle it now rather than on the next poll.
    await _claimWithRetries(token);

    if (!context.mounted) return true;
    showAppSnackBar(
      messenger,
      l10n.creditsEarnedOne,
      kind: AppSnackKind.success,
    );
    return true;
  }

  /// Polls the claim endpoint while Google's callback is still in flight.
  ///
  /// Short and bounded: three tries over about four seconds, which covers the
  /// overwhelming majority of callbacks without leaving a spinner up. A claim
  /// that has not landed by then still lands — `deliverAlert`-style, the
  /// callback writes the credit whenever it arrives and the stream picks it up.
  static Future<void> _claimWithRetries(String rewardToken) async {
    const delays = [Duration.zero, Duration(seconds: 1), Duration(seconds: 3)];
    for (final delay in delays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      final result = await AvahanaaApi.instance.claimAdReward(
        rewardToken: rewardToken,
      );
      // Settled: the credit is written and the wallet stream has it.
      if (result.isOk && result.data != null) return;
      // A hard failure — a bad token, a signed-out user — will fail the same
      // way on every retry, so stop asking.
      if (!result.isOk && !result.isRetryable) return;
    }
  }
}
