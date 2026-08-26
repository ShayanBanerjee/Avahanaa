// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppL10nKn extends AppL10n {
  AppL10nKn([String locale = 'kn']) : super(locale);

  @override
  String get reasonBlockingDriveway => 'ದಾರಿ ತಡೆದಿದೆ';

  @override
  String get reasonIllegalParking => 'ಅಕ್ರಮ ಪಾರ್ಕಿಂಗ್';

  @override
  String get reasonBlockingTraffic => 'ಸಂಚಾರ ತಡೆದಿದೆ';

  @override
  String get reasonDoubleParked => 'ಡಬಲ್ ಪಾರ್ಕಿಂಗ್';

  @override
  String get reasonEmergency => 'ತುರ್ತು ಪರಿಸ್ಥಿತಿ';

  @override
  String get reasonPrivateProperty => 'ಖಾಸಗಿ ಜಾಗ';

  @override
  String get reasonOther => 'ಇತರೆ';

  @override
  String get reasonUnknown => 'ವಾಹನ ಸೂಚನೆ';

  @override
  String get guidanceEmergency => 'ಇದು ತುರ್ತು. ಈಗಲೇ ನಿಮ್ಮ ವಾಹನದ ಬಳಿ ಹೋಗಿ.';

  @override
  String get guidanceBlockingDriveway =>
      'ಯಾರಿಗೋ ಒಳಗೆ ಅಥವಾ ಹೊರಗೆ ಹೋಗಲು ಆಗುತ್ತಿಲ್ಲ. ಬೇಗ ವಾಹನ ಸರಿಸಿ.';

  @override
  String get guidanceBlockingTraffic =>
      'ನಿಮ್ಮ ವಾಹನ ಸಂಚಾರಕ್ಕೆ ಅಡ್ಡಿಯಾಗಿದೆ. ಬೇಗ ಸರಿಸಿ.';

  @override
  String get guidanceIllegalParking =>
      'ನಿಮ್ಮ ವಾಹನವನ್ನು ಎಳೆದೊಯ್ಯಬಹುದು ಅಥವಾ ದಂಡ ಬೀಳಬಹುದು. ಪರಿಶೀಲಿಸಿ.';

  @override
  String get guidanceDoubleParked =>
      'ನೀವು ಯಾರನ್ನೋ ಸಿಲುಕಿಸಿದ್ದೀರಿ. ಅವರು ಕಾಯುತ್ತಿದ್ದಾರೆ.';

  @override
  String get guidancePrivateProperty =>
      'ನೀವು ಖಾಸಗಿ ಜಾಗದಲ್ಲಿ ನಿಲ್ಲಿಸಿದ್ದೀರಿ. ಸರಿಸಲು ಕೇಳಬಹುದು.';

  @override
  String get guidanceOther =>
      'ನಿಮ್ಮ ವಾಹನದ ಬಳಿ ಇರುವವರು ನಿಮಗೆ ತಿಳಿಸಲು ಬಯಸಿದ್ದಾರೆ.';

  @override
  String get replyOnMyWayNowOwner => 'ನಾನು ಇಲ್ಲೇ ಇದ್ದೇನೆ';

  @override
  String get replyOnMyWayFiveOwner => 'ಬರುತ್ತಿದ್ದೇನೆ — 5 ನಿಮಿಷ';

  @override
  String get replyOnMyWayFifteenOwner => 'ಬರುತ್ತಿದ್ದೇನೆ — 15 ನಿಮಿಷ';

  @override
  String get replyCannotComeOwner => 'ನನಗೆ ಬರಲು ಆಗುತ್ತಿಲ್ಲ';

  @override
  String get replySeenOwner => 'ನೋಡಿದೆ — ಧನ್ಯವಾದ';

  @override
  String get replySectionTitle => 'ಅವರಿಗೆ ಉತ್ತರಿಸಿ';

  @override
  String get replySectionBlurb =>
      'ಅವರು ಈಗಲೂ ನಿಮ್ಮ ವಾಹನದ ಬಳಿ ಪುಟ ತೆರೆದು ನಿಂತಿದ್ದಾರೆ. ಒಂದು ಸ್ಪರ್ಶ ನೀವು ಬರುತ್ತಿರುವುದನ್ನು ತಿಳಿಸುತ್ತದೆ.';

  @override
  String get replySending => 'ಕಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get replyTelling => 'ತಿಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get replyToldThem => 'ನೀವು ಬರುತ್ತಿರುವುದು ಅವರಿಗೆ ಗೊತ್ತು';

  @override
  String get replySentTitle => 'ಅವರಿಗೆ ತಿಳಿಸಲಾಗಿದೆ';

  @override
  String replySentBody(String scannerLabel) {
    return 'ಅವರ ಪುಟದಲ್ಲಿ ಈಗ ಹೀಗಿದೆ: \"$scannerLabel\".';
  }

  @override
  String get replyFailed =>
      'ನಿಮ್ಮ ಉತ್ತರ ಕಳಿಸಲು ಆಗಲಿಲ್ಲ. ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get replyYouReplied => 'ನೀವು ಉತ್ತರಿಸಿದ್ದೀರಿ';

  @override
  String get alertsTitle => 'ಸೂಚನೆಗಳು';

  @override
  String get alertsWhatTheySaid => 'ಅವರು ಹೇಳಿದ್ದು';

  @override
  String get alertsWhen => 'ಯಾವಾಗ';

  @override
  String get alertsAnonymityNote =>
      'ಇದನ್ನು ಕಳಿಸಿದವರು ಅನಾಮಧೇಯರಾಗಿಯೇ ಉಳಿದರು, ಮತ್ತು ಅವರಿಗೆ ನಿಮ್ಮ ಸಂಪರ್ಕ ವಿವರಗಳೂ ಕಾಣಲಿಲ್ಲ.';

  @override
  String get alertsNew => 'ಹೊಸದು';

  @override
  String get alertsToday => 'ಇಂದು';

  @override
  String get alertsYesterday => 'ನಿನ್ನೆ';

  @override
  String get panicHeadlineOne => 'ನಿಮ್ಮ ವಾಹನದ ಬಳಿ ಒಬ್ಬರಿಗೆ ನಿಮ್ಮ ಅಗತ್ಯವಿದೆ';

  @override
  String panicHeadlineMany(int count) {
    return 'ನಿಮ್ಮ ವಾಹನದ ಬಳಿ $count ಜನರಿಗೆ ನಿಮ್ಮ ಅಗತ್ಯವಿದೆ';
  }

  @override
  String get panicSeeWhatHappened => 'ಏನಾಯಿತು ಎಂದು ನೋಡಿ';

  @override
  String panicViewAll(int count) {
    return 'ಎಲ್ಲಾ $count ಸೂಚನೆಗಳನ್ನು ನೋಡಿ';
  }

  @override
  String get appearanceOverline => 'ಗೋಚರತೆ';

  @override
  String get appearanceTitle => 'Avahanaa ಹೇಗೆ ಕಾಣುತ್ತದೆ';

  @override
  String get appearanceSystem => 'ನನ್ನ ಫೋನ್‌ಗೆ ಹೊಂದಿಸಿ';

  @override
  String get appearanceLight => 'ಯಾವಾಗಲೂ ಬೆಳಕು';

  @override
  String get appearanceDark => 'ಯಾವಾಗಲೂ ಕತ್ತಲೆ';

  @override
  String get settingsAppearance => 'ಗೋಚರತೆ';

  @override
  String get timeJustNow => 'ಈಗಷ್ಟೇ';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes ನಿ ಹಿಂದೆ';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours ಗಂ ಹಿಂದೆ';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days ದಿ ಹಿಂದೆ';
  }
}
