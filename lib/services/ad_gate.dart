/// Whether this app is currently allowed to show ads.
///
/// A subscriber who still sees banners has not been sold anything, and "no
/// ads" is half of what Avahanaa Plus is. But the ad slots are scattered —
/// the home strip today, more later — and threading a boolean from the wallet
/// stream to each of them would mean every new slot is a chance to forget.
///
/// So there is one notifier. The wallet stream sets it; every ad widget
/// watches it. A plain global for the same reasons `themeController` is one:
/// exactly one instance, read before any tree exists, and this codebase
/// deliberately has no state-management package.
///
/// It defaults to *showing* ads. An app that has not yet loaded the wallet is
/// far more likely to belong to a free user than a subscriber, and a banner
/// that appears for a second and vanishes is a smaller insult than one that
/// pops in after the screen has settled.
library;

import 'package:flutter/foundation.dart';

import '../models/alert_wallet.dart';

/// True when ad slots should render.
final ValueNotifier<bool> adsAllowed = ValueNotifier<bool>(true);

/// Called from wherever the wallet is streamed.
///
/// Idempotent, and a no-op when the value has not changed — [ValueNotifier]
/// already suppresses identical writes, so this can be called from a build
/// method without causing a rebuild loop.
void syncAdGateWithWallet(AlertWallet wallet) {
  adsAllowed.value = !wallet.isSubscribed();
}
