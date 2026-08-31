/// Rewarded ads — the way an owner buys an alert with attention instead of
/// money.
///
/// One completed ad is worth [AlertBudget.creditsPerAd] alerts. The UI asks for
/// three in a row because that is the batch that gets somebody from empty to
/// comfortable, but each one banks the moment it finishes, so quitting after
/// two keeps two.
///
/// ## Why the credit is not granted here
///
/// This class can tell you an ad finished. It cannot tell you that truthfully —
/// it runs on the user's phone, and a phone can be made to say anything. So the
/// balance is moved by AdMob's **server-side verification** callback, which
/// Google sends directly to `POST /api/wallet/ssv` with an ECDSA signature over
/// the query string. The app's part is to mint a nonce, hand it to the ad as
/// custom data, and afterwards poke the backend to look for the callback now
/// rather than later. See `docs/monetization.md`.
///
/// That is also why [showAd] returns a token rather than a boolean: the caller
/// needs the nonce to make that poke.
///
/// ## Preloading
///
/// A rewarded ad takes a second or two to fetch, and the moment somebody taps
/// "watch an ad" is the worst moment to start. One ad is kept warm from the
/// time the wallet first looks low, and the next is fetched as soon as one is
/// spent.
library;

import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/alert_wallet.dart';

/// How showing an ad ended.
enum AdOutcome {
  /// Watched to the reward point. A credit is on its way.
  earned,

  /// Closed early, or the SDK reported no reward.
  dismissed,

  /// Nothing to show — no fill, no network, or the platform has no ads.
  unavailable,

  /// The SDK failed while presenting.
  failed,
}

class AdAttempt {
  const AdAttempt(this.outcome, {this.rewardToken});

  final AdOutcome outcome;

  /// The SSV nonce for this impression. Present only when [outcome] is
  /// [AdOutcome.earned].
  final String? rewardToken;

  bool get earned => outcome == AdOutcome.earned;
}

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  /// Google's always-fills test unit. Used in every non-release build so that
  /// development never sends invalid traffic to the live unit — AdMob suspends
  /// accounts for that, and an ad account suspension takes the revenue and the
  /// banner down together.
  static const String _testUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _liveUnitId = 'ca-app-pub-1536607795745971/4200000001';

  static String get _unitId => kReleaseMode ? _liveUnitId : _testUnitId;

  final Random _random = Random.secure();

  RewardedAd? _ad;
  bool _loading = false;
  DateTime? _loadedAt;

  /// Rewarded ads go stale. Google's guidance is to discard after an hour;
  /// showing an expired ad is a guaranteed present-failure.
  static const Duration _freshness = Duration(minutes: 50);

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isReady {
    final loadedAt = _loadedAt;
    if (_ad == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _freshness;
  }

  /// Fetches an ad if there is not already a fresh one waiting.
  ///
  /// Safe and cheap to call speculatively — from the wallet card appearing, or
  /// right after a credit is spent. Never throws and never blocks the caller;
  /// the worst case is that [isReady] stays false.
  Future<void> preload() async {
    if (!_supported || _loading || isReady) return;
    _loading = true;

    // `MobileAds.initialize()` is kicked off unawaited in `main` so the launch
    // path is not held open by an ad SDK. Awaiting it here is free once it has
    // run, and correct in the race.
    await MobileAds.instance.initialize();

    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          log('Rewarded ad failed to load: ${error.code} ${error.message}');
          _ad = null;
          _loadedAt = null;
          _loading = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    // Bounded, because a load that never calls back would otherwise leave
    // `_loading` true forever and wedge every later attempt.
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _loading = false;
      },
    );
  }

  /// Presents a rewarded ad and resolves once it closes.
  ///
  /// Loads on demand when nothing is warm, which is the slow path the caller
  /// should be showing a spinner over.
  Future<AdAttempt> showAd() async {
    if (!_supported) return const AdAttempt(AdOutcome.unavailable);

    if (!isReady) {
      await preload();
    }
    final ad = _ad;
    if (ad == null) return const AdAttempt(AdOutcome.unavailable);

    // Taken now, before the ad is handed over: the SDK owns the object after
    // `show`, and the fields must not be read from the callbacks.
    _ad = null;
    _loadedAt = null;

    final rewardToken = _mintRewardToken();

    // Both halves matter. `userId` is who to credit — Google echoes it back in
    // the signed callback, so the backend never has to trust the app for it.
    // `customData` is a per-impression nonce, and it is what the app polls on
    // afterwards to find out whether its own reward has landed yet.
    ad.setServerSideOptions(ServerSideVerificationOptions(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      customData: rewardToken,
    ));

    var earned = false;
    final closed = Completer<AdOutcome>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) {
          closed.complete(earned ? AdOutcome.earned : AdOutcome.dismissed);
        }
        // The next one is almost always wanted: somebody who watched one ad to
        // top up is usually watching three.
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('Rewarded ad failed to show: ${error.code} ${error.message}');
        ad.dispose();
        if (!closed.isCompleted) closed.complete(AdOutcome.failed);
        unawaited(preload());
      },
    );

    await ad.show(onUserEarnedReward: (_, _) => earned = true);

    final outcome = await closed.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => earned ? AdOutcome.earned : AdOutcome.failed,
    );

    return AdAttempt(
      outcome,
      rewardToken: outcome == AdOutcome.earned ? rewardToken : null,
    );
  }

  /// A single-use nonce tying this impression to the SSV callback Google will
  /// make. 128 bits from a secure source — it is the only thing standing
  /// between a replayed callback and a free credit.
  String _mintRewardToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
  }
}
