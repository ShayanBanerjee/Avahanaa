// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get reasonBlockingDriveway => 'Blocking Driveway';

  @override
  String get reasonIllegalParking => 'Illegal Parking';

  @override
  String get reasonBlockingTraffic => 'Blocking Traffic';

  @override
  String get reasonDoubleParked => 'Double Parked';

  @override
  String get reasonEmergency => 'Emergency';

  @override
  String get reasonPrivateProperty => 'Private Property';

  @override
  String get reasonOther => 'Other';

  @override
  String get reasonUnknown => 'Vehicle Notification';

  @override
  String get guidanceEmergency =>
      'Treat this as urgent. Get to your vehicle now.';

  @override
  String get guidanceBlockingDriveway =>
      'Someone cannot get in or out. Move your vehicle soon.';

  @override
  String get guidanceBlockingTraffic =>
      'Your vehicle is holding up traffic. Move it soon.';

  @override
  String get guidanceIllegalParking =>
      'Your vehicle may be towed or fined. Check on it.';

  @override
  String get guidanceDoubleParked =>
      'You are boxing someone in. They are waiting.';

  @override
  String get guidancePrivateProperty =>
      'You are parked on private land. You may be asked to move.';

  @override
  String get guidanceOther => 'Someone at your vehicle wanted you to know.';

  @override
  String get replyOnMyWayNowOwner => 'I\'m right here';

  @override
  String get replyOnMyWayFiveOwner => 'On my way — 5 min';

  @override
  String get replyOnMyWayFifteenOwner => 'On my way — 15 min';

  @override
  String get replyCannotComeOwner => 'I can\'t get there';

  @override
  String get replySeenOwner => 'Seen — thank you';

  @override
  String get replySectionTitle => 'REPLY TO THEM';

  @override
  String get replySectionBlurb =>
      'They are still standing at your vehicle with the page open. One tap tells them you are coming.';

  @override
  String get replySending => 'Sending…';

  @override
  String get replyTelling => 'Telling them…';

  @override
  String get replyToldThem => 'They know you are coming';

  @override
  String get replySentTitle => 'They have been told';

  @override
  String replySentBody(String scannerLabel) {
    return 'Their page now reads: \"$scannerLabel\".';
  }

  @override
  String get replyFailed =>
      'Could not send your reply. Check your connection and try again.';

  @override
  String get replyYouReplied => 'You replied';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsWhatTheySaid => 'WHAT THEY SAID';

  @override
  String get alertsWhen => 'WHEN';

  @override
  String get alertsAnonymityNote =>
      'Whoever sent this stayed anonymous, and they never saw your contact details either.';

  @override
  String get alertsNew => 'NEW';

  @override
  String get alertsToday => 'TODAY';

  @override
  String get alertsYesterday => 'YESTERDAY';

  @override
  String get panicHeadlineOne => 'Someone needs you at your vehicle';

  @override
  String panicHeadlineMany(int count) {
    return '$count people need you at your vehicle';
  }

  @override
  String get panicSeeWhatHappened => 'See what happened';

  @override
  String panicViewAll(int count) {
    return 'View all $count alerts';
  }

  @override
  String get appearanceOverline => 'APPEARANCE';

  @override
  String get appearanceTitle => 'How Avahanaa looks';

  @override
  String get appearanceSystem => 'Match my phone';

  @override
  String get appearanceLight => 'Always light';

  @override
  String get appearanceDark => 'Always dark';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }
}
