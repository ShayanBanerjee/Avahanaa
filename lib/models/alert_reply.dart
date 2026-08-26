/// The owner's half of the conversation.
///
/// Someone scanned a sticker and is standing next to the vehicle, watching a
/// web page. This is what the owner can send back to that page.
///
/// **It is a fixed set, not free text, and that is deliberate.** A free-form
/// channel between two anonymous strangers is a harassment vector in both
/// directions, and it would quietly undo the thing the product promises: the
/// scanner learns nothing about the owner, and the owner learns nothing about
/// the scanner. A closed set of replies carries the only information that
/// actually de-escalates the moment — *is someone coming, and roughly when* —
/// and carries nothing else.
///
/// It is also the right shape for the moment it is used in. The owner is
/// reading this on a lock screen, walking, possibly at night, possibly already
/// anxious. One tap is the entire interaction budget. A text field would not
/// get used.
library;

import '../l10n/app_localizations.dart';

/// A reply the owner can send. The `id` is the wire value and is written to
/// `notifications/{id}.acknowledgementEta`; never renumber or rename one, as
/// old app versions stay installed for months.
enum AlertReply {
  onMyWayNow(
    id: 'omw_now',
    ownerLabel: "I'm right here",
    scannerLabel: 'The owner is on their way now',
    etaMinutes: 1,
  ),
  onMyWayFive(
    id: 'omw_5',
    ownerLabel: 'On my way — 5 min',
    scannerLabel: 'The owner is on their way — about 5 minutes',
    etaMinutes: 5,
  ),
  onMyWayFifteen(
    id: 'omw_15',
    ownerLabel: 'On my way — 15 min',
    scannerLabel: 'The owner is on their way — about 15 minutes',
    etaMinutes: 15,
  ),
  cannotCome(
    id: 'cannot_come',
    ownerLabel: "I can't get there",
    scannerLabel: "The owner has seen this but can't get there right now",
    etaMinutes: null,
  ),
  acknowledged(
    id: 'seen',
    ownerLabel: 'Seen — thank you',
    scannerLabel: 'The owner has seen your alert',
    etaMinutes: null,
  );

  const AlertReply({
    required this.id,
    required this.ownerLabel,
    required this.scannerLabel,
    required this.etaMinutes,
  });

  /// Wire value. Stable — the backend and the scan page both key off it.
  final String id;

  /// What the owner taps, in English. Kept for logs and for the notification
  /// actions, which Android builds before any locale is resolved.
  final String ownerLabel;

  /// What the owner taps, in the reader's language.
  String ownerLabelIn(AppL10n l10n) => switch (this) {
    AlertReply.onMyWayNow => l10n.replyOnMyWayNowOwner,
    AlertReply.onMyWayFive => l10n.replyOnMyWayFiveOwner,
    AlertReply.onMyWayFifteen => l10n.replyOnMyWayFifteenOwner,
    AlertReply.cannotCome => l10n.replyCannotComeOwner,
    AlertReply.acknowledged => l10n.replySeenOwner,
  };

  /// What the scanner reads. Written in the third person, because the person
  /// reading it is a stranger who should not be addressed as though the owner
  /// knows them.
  final String scannerLabel;

  /// Rough minutes, or null when the reply carries no ETA. Used only to render
  /// a countdown; never treated as a promise.
  final int? etaMinutes;

  /// Whether this reply means somebody is actually coming. Drives whether the
  /// scan page shows a countdown or a plain acknowledgement.
  bool get isOnTheWay => etaMinutes != null;

  /// The replies offered on a panic surface, in tap order.
  ///
  /// Ordered by how likely they are, not by duration: the common case is "I am
  /// close and coming", so it sits under the thumb.
  static const List<AlertReply> quickReplies = <AlertReply>[
    AlertReply.onMyWayFive,
    AlertReply.onMyWayNow,
    AlertReply.onMyWayFifteen,
    AlertReply.cannotCome,
  ];

  /// Resolves a wire value, tolerating anything unknown.
  ///
  /// An unrecognised id means the sender is newer than this build. Falling back
  /// to a plain acknowledgement is always safe — it says less than intended,
  /// never more.
  static AlertReply? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final reply in AlertReply.values) {
      if (reply.id == id) return reply;
    }
    return AlertReply.acknowledged;
  }
}
