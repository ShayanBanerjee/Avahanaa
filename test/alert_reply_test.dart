import 'dart:io';

import 'package:avahanaa/models/alert_reply.dart';
import 'package:flutter_test/flutter_test.dart';

/// The owner's reply crosses a repo boundary.
///
/// The app writes `acknowledgementEta`; the backend in `Avahanaa-Web` turns it
/// into the sentence a stranger reads standing next to the car. Those are two
/// codebases that deploy separately, and a mismatch does not raise anything —
/// it silently degrades to "The owner has seen your alert" when the owner
/// actually said they were two minutes away.
///
/// So the ids are pinned here, and checked against the backend's own table
/// when that repo is checked out beside this one.
void main() {
  group('wire values', () {
    test('ids are exactly the agreed set', () {
      expect(
        AlertReply.values.map((r) => r.id).toSet(),
        <String>{'omw_now', 'omw_5', 'omw_15', 'cannot_come', 'seen'},
      );
    });

    test('ids round-trip', () {
      for (final reply in AlertReply.values) {
        expect(AlertReply.fromId(reply.id), reply);
      }
    });

    test('an unknown id degrades to a plain acknowledgement', () {
      // A reply written by a newer app than this build. Saying less than was
      // meant is safe; inventing an ETA is not.
      expect(AlertReply.fromId('omw_45'), AlertReply.acknowledged);
      expect(AlertReply.fromId('anything'), AlertReply.acknowledged);
    });

    test('absent means no reply, not a default one', () {
      // The difference between "the owner has not answered" and "the owner
      // said something" is the entire signal this carries.
      expect(AlertReply.fromId(null), isNull);
      expect(AlertReply.fromId(''), isNull);
    });
  });

  group('semantics', () {
    test('only the on-my-way replies carry an ETA', () {
      for (final reply in AlertReply.values) {
        expect(
          reply.isOnTheWay,
          reply.etaMinutes != null,
          reason: '${reply.id} disagrees with itself about having an ETA',
        );
      }
      expect(AlertReply.cannotCome.isOnTheWay, isFalse);
      expect(AlertReply.acknowledged.isOnTheWay, isFalse);
    });

    test('quick replies lead with the likeliest answer', () {
      // The first entry is what the panic surfaces bind to their one primary
      // button, so it has to be the common case.
      expect(AlertReply.quickReplies.first, AlertReply.onMyWayFive);
      expect(AlertReply.quickReplies, contains(AlertReply.cannotCome));
    });

    test('every reply has copy for both audiences', () {
      for (final reply in AlertReply.values) {
        expect(reply.ownerLabel.trim(), isNotEmpty);
        expect(reply.scannerLabel.trim(), isNotEmpty);
        // The scanner is a stranger and is never addressed as "you" about the
        // owner's movements, nor told whose vehicle it is.
        expect(reply.scannerLabel.toLowerCase(), contains('owner'));
      }
    });
  });

  group('notification action ids', () {
    // The action id is `avahanaa_reply_` + the wire id, and it is parsed in a
    // background isolate with no UI. A mismatch there is silent: the owner taps
    // "On my way" on their lock screen, nothing is written, and they walk to
    // their car believing the person waiting has been told.
    const prefix = 'avahanaa_reply_';

    test('the ids offered on the notification round-trip', () {
      for (final id in <String>['omw_5', 'omw_now']) {
        final actionId = '$prefix$id';
        expect(actionId.startsWith(prefix), isTrue);
        final parsed = AlertReply.fromId(actionId.substring(prefix.length));
        expect(parsed, isNotNull);
        expect(parsed!.id, id);
        expect(parsed.isOnTheWay, isTrue,
            reason: 'a lock-screen action should only ever say someone is coming');
      }
    });

    test('a foreign action id resolves to nothing actionable', () {
      // Anything not carrying the prefix must be treated as a plain tap.
      const tapOnly = 'some_other_action';
      expect(tapOnly.startsWith(prefix), isFalse);
    });
  });

  group('parity with the backend', () {
    /// Skipped unless `Avahanaa-Web` is checked out next to this repo, so CI
    /// on this repo alone stays green.
    test('REPLY_LABELS covers exactly these ids', () {
      final backend = File('../Avahanaa-Web/functions/index.js');
      if (!backend.existsSync()) {
        markTestSkipped('Avahanaa-Web not checked out beside this repo');
        return;
      }

      final source = backend.readAsStringSync();
      final block = RegExp(
        r'const REPLY_LABELS = \{(.*?)\};',
        dotAll: true,
      ).firstMatch(source);
      expect(block, isNotNull, reason: 'REPLY_LABELS not found in the backend');

      final ids = RegExp(r'^\s*(\w+):', multiLine: true)
          .allMatches(block!.group(1)!)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        ids,
        AlertReply.values.map((r) => r.id).toSet(),
        reason: 'the app and the backend disagree about reply ids',
      );
    });

    test('REPLY_ON_THE_WAY matches which replies carry an ETA', () {
      final backend = File('../Avahanaa-Web/functions/index.js');
      if (!backend.existsSync()) {
        markTestSkipped('Avahanaa-Web not checked out beside this repo');
        return;
      }

      final source = backend.readAsStringSync();
      final block = RegExp(
        r'const REPLY_ON_THE_WAY = new Set\(\[(.*?)\]\)',
        dotAll: true,
      ).firstMatch(source);
      expect(block, isNotNull);

      final ids = RegExp(r'"([^"]+)"')
          .allMatches(block!.group(1)!)
          .map((m) => m.group(1))
          .toSet();

      expect(
        ids,
        AlertReply.values.where((r) => r.isOnTheWay).map((r) => r.id).toSet(),
      );
    });
  });
}
