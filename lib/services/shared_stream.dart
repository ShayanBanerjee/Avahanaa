/// One upstream listener, many subscribers, with the last value replayed.
///
/// Extracted from [FirestoreService] when a real bug landed: the home screen
/// wrapped an already-shared stream in `asBroadcastStream()`, and the hero went
/// on showing "3 alerts left" while the profile tab — reading the same
/// document — correctly showed 0. Redundant stream wrapping is exactly where
/// that class of bug lives, and a private helper inside a Firestore service
/// could not be unit-tested at all.
///
/// Two properties, and both matter:
///
/// **Replay.** A late subscriber to a plain broadcast stream sees nothing until
/// the next event. On a Firestore document that changes a handful of times a
/// month, that is a tab which renders empty until something happens. Each new
/// subscriber is handed the last known value immediately.
///
/// **No gap.** The replay happens *after* the subscriber is wired to the live
/// controller, never before. The other order drops any event that lands in
/// between — which, on a wallet, is a credit that silently never appears.
library;

import 'dart:async';

class SharedStream<T> {
  SharedStream(Stream<T> source) {
    _subscription = source.listen(
      (event) {
        _latest = event;
        _hasLatest = true;
        if (!_controller.isClosed) _controller.add(event);
      },
      onError: (Object error, StackTrace stack) {
        if (!_controller.isClosed) _controller.addError(error, stack);
      },
    );
  }

  final StreamController<T> _controller = StreamController<T>.broadcast();
  late final StreamSubscription<T> _subscription;

  T? _latest;
  bool _hasLatest = false;

  /// Whether a value has arrived from upstream yet.
  bool get hasValue => _hasLatest;

  /// A subscribable view that replays the last value, then follows the source.
  ///
  /// **One object, many listeners, stable identity.** All three matter:
  ///
  /// *Many listeners*, because several widgets watch the same document and a
  /// single-subscription stream throws "Stream has already been listened to"
  /// the second time a `StreamBuilder` remounts.
  ///
  /// *Stable identity*, because `StreamBuilder` re-subscribes whenever the
  /// stream instance changes. A getter that minted a new stream per call would
  /// re-subscribe on every rebuild, replay a value, rebuild again — a render
  /// loop that looks like the screen working while it spins.
  ///
  /// `Stream.multi` gives each listener its own controller, which is what lets
  /// the replay be per-subscriber rather than a single shared buffer, and it
  /// propagates pause and cancel properly.
  late final Stream<T> stream = Stream<T>.multi((controller) {
    // Replay first, then follow. Ordering is safe here in a way it is not for
    // a plain controller: `Stream.multi` gives this listener a private
    // controller, so nothing can slip in between the two lines.
    if (_hasLatest) controller.add(_latest as T);

    final forward = _controller.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = forward.cancel;
  }, isBroadcast: true);

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
