/// The sharing helper behind every Firestore read in the app.
///
/// Written after a real bug: the home hero showed "3 alerts left" while the
/// profile tab, reading the same document, correctly showed 0. The difference
/// was that the home screen wrapped the already-shared stream in a second
/// `asBroadcastStream()`. These are the properties that were being relied on
/// without ever being checked.
library;

import 'dart:async';

import 'package:avahanaa/services/shared_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one upstream listener serves many subscribers', () async {
    var listens = 0;
    final source = StreamController<int>.broadcast(
      onListen: () => listens++,
    );
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    final a = <int>[], b = <int>[], c = <int>[];
    shared.stream.listen(a.add);
    shared.stream.listen(b.add);
    shared.stream.listen(c.add);
    await Future<void>.delayed(Duration.zero);

    source.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(listens, 1, reason: 'the source should be listened to exactly once');
    expect(a, [1]);
    expect(b, [1]);
    expect(c, [1]);
  });

  test('a late subscriber is handed the last value immediately', () async {
    // Without this, a tab that mounts after the document last changed renders
    // empty until the next change — which on a wallet can be a month.
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    shared.stream.listen((_) {});
    source.add(42);
    await Future<void>.delayed(Duration.zero);

    final late = <int>[];
    shared.stream.listen(late.add);
    await Future<void>.delayed(Duration.zero);

    expect(late, [42]);
  });

  test('every subscriber keeps receiving updates after the replay', () async {
    // This is the one the bug broke. The first value arrived and nothing
    // after it ever did.
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    source.add(1);
    await Future<void>.delayed(Duration.zero);

    final seen = <int>[];
    shared.stream.listen(seen.add);
    await Future<void>.delayed(Duration.zero);

    source.add(2);
    source.add(3);
    await Future<void>.delayed(Duration.zero);

    expect(seen, [1, 2, 3], reason: 'replay then live, with nothing dropped');
  });

  test('an event during subscription setup is not dropped', () async {
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    source.add(1);
    await Future<void>.delayed(Duration.zero);

    final seen = <int>[];
    final sub = shared.stream.listen(seen.add);
    // Fire immediately, before the microtask queue drains.
    source.add(2);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen, containsAllInOrder(<int>[1, 2]));
  });

  test('wrapping the shared stream again still delivers updates', () async {
    // The exact shape of the bug: home_screen did
    //   firestore.streamAlertWallet(uid).asBroadcastStream()
    // over a stream that was already shared. Guarded so the redundant wrap
    // cannot silently break delivery if anyone reintroduces it.
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    source.add(1);
    await Future<void>.delayed(Duration.zero);

    final wrapped = shared.stream.asBroadcastStream();
    final seen = <int>[];
    wrapped.listen(seen.add);
    await Future<void>.delayed(Duration.zero);

    source.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(seen, [1, 2]);
  });

  test('a subscriber that leaves and comes back still gets updates', () async {
    // The bug, exactly. A StreamBuilder deep in the home tab unmounts during
    // the skeleton -> loaded transition and remounts a frame later. If leaving
    // tears down the shared source, everything that comes back is frozen at
    // the value it had when it re-subscribed — which is how the hero sat on
    // "3 alerts left" while the profile tab, which rebuilds its stream every
    // frame, correctly showed 0.
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    final first = <int>[];
    final sub = shared.stream.listen(first.add);
    source.add(1);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // Everyone has gone. The source must still be alive.
    source.add(2);
    await Future<void>.delayed(Duration.zero);

    final second = <int>[];
    shared.stream.listen(second.add);
    await Future<void>.delayed(Duration.zero);
    source.add(3);
    await Future<void>.delayed(Duration.zero);

    expect(first, [1]);
    expect(
      second,
      [2, 3],
      reason: 'the remounted subscriber must get the latest value and then '
          'keep following the source',
    );
  });

  test('the stream is one object, so StreamBuilder does not re-subscribe', () {
    // A getter that minted a fresh stream per call would make StreamBuilder
    // re-subscribe on every rebuild, replay a value, and rebuild again — a
    // render loop that looks like a working screen while it spins.
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    expect(identical(shared.stream, shared.stream), isTrue);
  });

  test('the same stream object can be listened to more than once', () async {
    // Caching it in a `late final` and remounting used to throw
    // "Stream has already been listened to" and red-screen the app.
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    final one = <int>[], two = <int>[];
    final cached = shared.stream;
    final a = cached.listen(one.add);
    final b = cached.listen(two.add);
    await Future<void>.delayed(Duration.zero);

    source.add(5);
    await Future<void>.delayed(Duration.zero);
    await a.cancel();

    // One leaving must not take the other down with it.
    source.add(6);
    await Future<void>.delayed(Duration.zero);
    await b.cancel();

    expect(one, [5]);
    expect(two, [5, 6]);
  });

  test('errors reach every subscriber instead of killing the share', () async {
    final source = StreamController<int>.broadcast();
    final shared = SharedStream<int>(source.stream);
    addTearDown(shared.dispose);

    final errors = <Object>[];
    final values = <int>[];
    shared.stream.listen(values.add, onError: errors.add);
    await Future<void>.delayed(Duration.zero);

    source.addError('permission denied');
    await Future<void>.delayed(Duration.zero);
    source.add(7);
    await Future<void>.delayed(Duration.zero);

    expect(errors, ['permission denied']);
    expect(values, [7], reason: 'an error must not end the shared stream');
  });
}
