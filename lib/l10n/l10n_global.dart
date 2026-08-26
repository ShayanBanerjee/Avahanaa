/// Localizations for code that has no `BuildContext`.
///
/// The services in this app throw human-readable strings for writes the user
/// initiated, and the screens catch them and show a SnackBar — that split is a
/// documented convention (`CLAUDE.md`) and worth keeping. But it leaves those
/// strings stranded: `FirestoreService` has no widget tree to look a
/// translation up in, and threading an `AppL10n` through every service call
/// would be a lot of plumbing to move a dozen error messages.
///
/// So they resolve through the navigator, which is the one context that exists
/// for as long as the app does.
///
/// This is deliberately *not* the general way to reach localizations. Anything
/// with a context should use `AppL10n.of(context)`, which is correct in nested
/// navigators and rebuilds properly when the locale changes. This exists for
/// the places where no context can honestly be obtained.
library;

import 'package:flutter/widgets.dart';

import '../services/notification_navigation_service.dart';
import 'app_localizations.dart';
import 'app_localizations_en.dart';

/// The active localizations, or English if the tree is not up yet.
///
/// Falls back rather than throwing: a service that cannot name its own error
/// should still report the error. An English message is a far better failure
/// than a crash inside a `catch` block.
AppL10n get appL10n {
  try {
    final context = NotificationNavigationService.navigatorKey.currentContext;
    if (context != null) {
      final l10n = Localizations.of<AppL10n>(context, AppL10n);
      if (l10n != null) return l10n;
    }
  } catch (_) {
    // `GlobalKey.currentContext` reaches for `WidgetsBinding.instance`, which
    // throws outright if no binding exists — a plain `dart test` with no
    // widget harness, or a background isolate that never called `runApp`.
    // Both are places this getter is legitimately reached from, and neither is
    // a reason to fail the call that was actually being made.
  }
  return AppL10nEn();
}
