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

  @override
  String get authWelcomeBack => 'ಮತ್ತೆ ಸ್ವಾಗತ';

  @override
  String get authSignInBlurb => 'ಸಂಪರ್ಕದಲ್ಲಿ ಇರಲು ಸೈನ್ ಇನ್ ಮಾಡಿ.';

  @override
  String get authEmail => 'ಇಮೇಲ್';

  @override
  String get authPassword => 'ಪಾಸ್‌ವರ್ಡ್';

  @override
  String get authSignIn => 'ಸೈನ್ ಇನ್';

  @override
  String get authForgotPassword => 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರಾ?';

  @override
  String get authCreateAnAccount => 'ಖಾತೆ ತೆರೆಯಿರಿ';

  @override
  String get authCreateYourAccount => 'ನಿಮ್ಮ ಖಾತೆ ತೆರೆಯಿರಿ';

  @override
  String get authYourAccount => 'ನಿಮ್ಮ ಖಾತೆ';

  @override
  String get authYourVehicle => 'ನಿಮ್ಮ ವಾಹನ';

  @override
  String get authConfirmPassword => 'ಪಾಸ್‌ವರ್ಡ್ ಖಚಿತಪಡಿಸಿ';

  @override
  String get authPhoneOptional => 'ಫೋನ್ ಸಂಖ್ಯೆ (ಐಚ್ಛಿಕ)';

  @override
  String get authRegistrationNumber => 'ನೋಂದಣಿ ಸಂಖ್ಯೆ';

  @override
  String get authMakeAndModel => 'ಕಂಪನಿ ಮತ್ತು ಮಾದರಿ';

  @override
  String get authColour => 'ಬಣ್ಣ';

  @override
  String get authCreateAccount => 'ಖಾತೆ ತೆರೆಯಿರಿ';

  @override
  String get legalPrivacyPolicy => 'ಗೌಪ್ಯತಾ ನೀತಿ';

  @override
  String get legalTermsOfService => 'ಸೇವಾ ನಿಯಮಗಳು';

  @override
  String get authResetYourPassword => 'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಿ';

  @override
  String get authSendResetLink => 'ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ಕಳಿಸಿ';

  @override
  String get authBackToSignIn => 'ಸೈನ್ ಇನ್‌ಗೆ ಹಿಂತಿರುಗಿ';

  @override
  String get authCheckYourEmail => 'ನಿಮ್ಮ ಇಮೇಲ್ ನೋಡಿ';

  @override
  String get authUseDifferentEmail => 'ಬೇರೆ ಇಮೇಲ್ ಬಳಸಿ';

  @override
  String get authResendEmail => 'ಇಮೇಲ್ ಮತ್ತೆ ಕಳಿಸಿ';

  @override
  String get legalTitle => 'ಕಾನೂನು ಮತ್ತು ಗೌಪ್ಯತೆ';

  @override
  String get legalShortVersion => 'ಸಂಕ್ಷಿಪ್ತವಾಗಿ';

  @override
  String get legalShortBody =>
      'ನಿಮ್ಮ ಸ್ಟಿಕರ್ ಸ್ಕ್ಯಾನ್ ಮಾಡುವವರಿಗೆ Avahanaa ನಿಮ್ಮ ಫೋನ್ ಸಂಖ್ಯೆ, ಇಮೇಲ್ ಅಥವಾ ಹೆಸರನ್ನು ಎಂದಿಗೂ ತೋರಿಸುವುದಿಲ್ಲ.';

  @override
  String get legalPrivacySubtitle =>
      'ನಾವು ಏನು ಸಂಗ್ರಹಿಸುತ್ತೇವೆ, ಏಕೆ, ಮತ್ತು ಎಷ್ಟು ಕಾಲ ಇಡುತ್ತೇವೆ';

  @override
  String get legalTermsSubtitle => 'Avahanaa ಬಳಕೆಯ ನಿಯಮಗಳು';

  @override
  String get legalCouldNotOpen => 'ಈಗ ಲಿಂಕ್ ತೆರೆಯಲು ಆಗಲಿಲ್ಲ.';

  @override
  String get qrScanToAlertMe => 'ನನಗೆ ತಿಳಿಸಲು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ';

  @override
  String get qrYourWindshieldCode => 'ನಿಮ್ಮ ವಿಂಡ್‌ಶೀಲ್ಡ್ ಕೋಡ್';

  @override
  String get qrPaused => 'ವಿರಾಮ';

  @override
  String get qrSemanticLabel => 'ನಿಮ್ಮ ವಾಹನದ QR ಕೋಡ್';

  @override
  String get vehicleReachable => 'ತಲುಪಬಹುದು — ನಿಮ್ಮ ಸಂಖ್ಯೆ ಗುಪ್ತವಾಗಿರುತ್ತದೆ';

  @override
  String get vehiclePaused => 'ವಿರಾಮ — ಸ್ಕ್ಯಾನ್‌ಗಳು ನಿಮ್ಮನ್ನು ತಲುಪುತ್ತಿಲ್ಲ';

  @override
  String get vehicleYourVehicle => 'ನಿಮ್ಮ ವಾಹನ';

  @override
  String vehicleCountOf(int index, int count) {
    return 'ವಾಹನ $index / $count';
  }

  @override
  String vehicleShowNumber(int index) {
    return 'ವಾಹನ $index ತೋರಿಸಿ';
  }

  @override
  String get homeGoodMorning => 'ಶುಭೋದಯ';

  @override
  String get homeGoodAfternoon => 'ಶುಭ ಮಧ್ಯಾಹ್ನ';

  @override
  String get homeGoodEvening => 'ಶುಭ ಸಂಜೆ';

  @override
  String get homeVehicleReachable => 'ನಿಮ್ಮ ವಾಹನ ತಲುಪಬಹುದಾಗಿದೆ';

  @override
  String get homeQrPaused => 'ನಿಮ್ಮ QR ಕೋಡ್ ವಿರಾಮದಲ್ಲಿದೆ';

  @override
  String get homeAddFirstVehicle => 'ನಿಮ್ಮ ಮೊದಲ ವಾಹನ ಸೇರಿಸಿ';

  @override
  String get homeAddVehicleBody =>
      'ವಿಂಡ್‌ಶೀಲ್ಡ್‌ಗೆ ಕೋಡ್ ರಚಿಸುವ ಮೊದಲು Avahanaa ಗೆ ಒಂದು ವಾಹನ ಬೇಕು.';

  @override
  String get homeGoToProfile => 'ಪ್ರೊಫೈಲ್‌ಗೆ ಹೋಗಿ';

  @override
  String get homeCreatingQr => 'ನಿಮ್ಮ QR ಕೋಡ್ ರಚಿಸಲಾಗುತ್ತಿದೆ';

  @override
  String get homeCreatingQrBody => 'ಇದಕ್ಕೆ ಸಾಮಾನ್ಯವಾಗಿ ಕೆಲವು ಸೆಕೆಂಡುಗಳು ಬೇಕು.';

  @override
  String get homeSettingUpVehicle => 'ನಿಮ್ಮ ವಾಹನ ಸಿದ್ಧಪಡಿಸಲಾಗುತ್ತಿದೆ';

  @override
  String get homeSettingUpBody =>
      'ನಿಮ್ಮ ವಿವರಗಳನ್ನು ವರ್ಗಾಯಿಸಲಾಗುತ್ತಿದೆ. ಒಂದು ಕ್ಷಣ.';

  @override
  String get homeAccountMissing => 'ಖಾತೆಯ ವಿವರಗಳು ಸಿಗಲಿಲ್ಲ';

  @override
  String get homeAccountMissingBody =>
      'ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ಲೋಡ್ ಆಗಲಿಲ್ಲ. ಸೈನ್ ಔಟ್ ಮಾಡಿ ಮತ್ತೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.';

  @override
  String get homeCannotReach => 'ನಿಮ್ಮ ಖಾತೆ ತಲುಪಲು ಆಗುತ್ತಿಲ್ಲ';

  @override
  String get homeCannotReachBody =>
      'ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ — ಸ್ಕ್ಯಾನ್ ಮಾಡುವವರಿಗೆ ನಿಮ್ಮ QR ಕೋಡ್ ಕೆಲಸ ಮಾಡುತ್ತಲೇ ಇದೆ, ಈ ಪರದೆ ಮಾತ್ರ ರಿಫ್ರೆಶ್ ಆಗುತ್ತಿಲ್ಲ.';

  @override
  String get homePrint => 'ಮುದ್ರಿಸಿ';

  @override
  String get homeCopyLink => 'ಲಿಂಕ್ ನಕಲಿಸಿ';

  @override
  String get homeDesign => 'ವಿನ್ಯಾಸ';

  @override
  String get homeScanLinkCopied => 'ಸ್ಕ್ಯಾನ್ ಲಿಂಕ್ ನಕಲಾಗಿದೆ';

  @override
  String get homePrinterFailed =>
      'ಪ್ರಿಂಟರ್ ತೆರೆಯಲು ಆಗಲಿಲ್ಲ. ಬದಲಿಗೆ ವಿನ್ಯಾಸದಲ್ಲಿ ಹಾಳೆ ಉಳಿಸಿ.';

  @override
  String get homePreparing => 'ಸಿದ್ಧವಾಗುತ್ತಿದೆ…';

  @override
  String get homeUnreadAlert => 'ಓದದ ಸೂಚನೆ';

  @override
  String get homeUnreadAlerts => 'ಓದದ ಸೂಚನೆಗಳು';

  @override
  String get homeVehicle => 'ವಾಹನ';

  @override
  String get homeVehicles => 'ವಾಹನಗಳು';

  @override
  String get homeProtection => 'ರಕ್ಷಣೆ';

  @override
  String get homeGettingSetUp => 'ಸಿದ್ಧಪಡಿಸುವುದು';

  @override
  String get homeHowItWorks => 'ಇದು ಹೇಗೆ ಕೆಲಸ ಮಾಡುತ್ತದೆ';

  @override
  String get homeStepPrint => 'ಸ್ಟಿಕರ್ ಮುದ್ರಿಸಿ';

  @override
  String get homeStepPrintBody =>
      'ಹಂಚಿ ಅಥವಾ ಉಳಿಸಿ, ನಂತರ ಸಾದಾ ಬಿಳಿ ಕಾಗದದ ಮೇಲೆ ಮುದ್ರಿಸಿ.';

  @override
  String get homeStepStick => 'ವಿಂಡ್‌ಶೀಲ್ಡ್ ಮೇಲೆ ಅಂಟಿಸಿ';

  @override
  String get homeStepStickBody =>
      'ಗಾಜಿನ ಒಳಗೆ, ಚಾಲಕನ ಕಡೆ ಮೂಲೆಯಲ್ಲಿ, ಹೊರಮುಖವಾಗಿ.';

  @override
  String get homeStepAlert => 'ಸೆಕೆಂಡುಗಳಲ್ಲಿ ಸೂಚನೆ ಪಡೆಯಿರಿ';

  @override
  String get homeStepAlertBody =>
      'ಸ್ಕ್ಯಾನ್ ಆದರೆ ಸೈಲೆಂಟ್‌ನಲ್ಲೂ ನಿಮ್ಮ ಫೋನ್ ಸದ್ದು ಮಾಡುತ್ತದೆ.';

  @override
  String get homeNumberStaysYours => 'ನಿಮ್ಮ ಸಂಖ್ಯೆ ನಿಮ್ಮದೇ';

  @override
  String get homeNumberStaysYoursBody =>
      'ನಿಮ್ಮ ಕೋಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡುವವರು ಏನೋ ತಪ್ಪಾಗಿದೆ ಎಂದಷ್ಟೇ ತಿಳಿಸಬಹುದು. ನಿಮ್ಮ ಫೋನ್ ಸಂಖ್ಯೆ, ಇಮೇಲ್ ಅಥವಾ ಹೆಸರು ಅವರಿಗೆ ಎಂದಿಗೂ ಕಾಣುವುದಿಲ್ಲ.';

  @override
  String get navHome => 'ಮುಖಪುಟ';

  @override
  String get navAlerts => 'ಸೂಚನೆಗಳು';

  @override
  String get navProfile => 'ಪ್ರೊಫೈಲ್';

  @override
  String get studioTitle => 'ಸ್ಟಿಕರ್ ಸ್ಟುಡಿಯೋ';

  @override
  String get studioChooseALook => 'ಒಂದು ವಿನ್ಯಾಸ ಆರಿಸಿ';

  @override
  String get studioStickerDesign => 'ಸ್ಟಿಕರ್ ವಿನ್ಯಾಸ';

  @override
  String get studioPutItOnPaper => 'ಕಾಗದದ ಮೇಲೆ ಹಾಕಿ';

  @override
  String get studioPrintASheet => 'ಒಂದು ಹಾಳೆ ಮುದ್ರಿಸಿ';

  @override
  String get studioPaper => 'ಕಾಗದ';

  @override
  String get studioPerSheet => 'ಪ್ರತಿ ಹಾಳೆಗೆ';

  @override
  String get studioPrintThisSheet => 'ಈ ಹಾಳೆ ಮುದ್ರಿಸಿ';

  @override
  String get studioSendPdf => 'ಪ್ರಿಂಟ್ ಅಂಗಡಿಗೆ PDF ಕಳಿಸಿ';

  @override
  String get studioOrSendPicture => 'ಅಥವಾ ಚಿತ್ರವಾಗಿ ಕಳಿಸಿ';

  @override
  String get studioShareTheImage => 'ಚಿತ್ರ ಹಂಚಿ';

  @override
  String get studioShareOrSave => 'ಚಿತ್ರ ಹಂಚಿ ಅಥವಾ ಉಳಿಸಿ';

  @override
  String get studioCopyScanLink => 'ಸ್ಕ್ಯಾನ್ ಲಿಂಕ್ ನಕಲಿಸಿ';

  @override
  String get studioMakeItLast => 'ಬಾಳಿಕೆ ಬರುವಂತೆ ಮಾಡಿ';

  @override
  String get studioGettingItPrinted => 'ಮುದ್ರಿಸುವ ಬಗ್ಗೆ';

  @override
  String get studioAnyoneCanScan => 'ಯಾರು ಬೇಕಾದರೂ ಸ್ಕ್ಯಾನ್ ಮಾಡಬಹುದು';

  @override
  String get studioAnyoneCanScanBody =>
      'ಯಾವುದೇ ಆ್ಯಪ್ ಬೇಡ — ಫೋನ್ ಕ್ಯಾಮೆರಾ ಅಥವಾ Google Lens ಸಾಕು. ಕೋಡ್ ಸುತ್ತಲಿನ ಬಿಳಿ ಅಂಚು ಸ್ವಚ್ಛವಾಗಿಟ್ಟು ಸ್ಟಿಕರ್ ಸಮತಟ್ಟಾಗಿರಲಿ.';

  @override
  String get studioLaminate => 'ಲ್ಯಾಮಿನೇಟ್ ಮಾಡಿ';

  @override
  String get studioLaminateBody =>
      'ಪಾರದರ್ಶಕ ಕವರ್ ಕೂಡ ಸಾಕು. ಬೆಂಗಳೂರಿನ ಬಿಸಿಲಿಗೆ ಶಾಯಿ ಬೇಗ ಮಾಸುತ್ತದೆ.';

  @override
  String get studioFixInside => 'ವಿಂಡ್‌ಶೀಲ್ಡ್ ಒಳಗೆ ಅಂಟಿಸಿ';

  @override
  String get studioFixInsideBody =>
      'ಚಾಲಕನ ಕಡೆ ಮೂಲೆ, ಕೋಡ್ ಹೊರಮುಖವಾಗಿ, ಮೇಲೆ ಏನೂ ಮುಚ್ಚದಂತೆ.';

  @override
  String get studioCutAtMarks => 'ಮೂಲೆ ಗುರುತುಗಳಲ್ಲಿ ಕತ್ತರಿಸಿ';

  @override
  String get studioCutAtMarksBody =>
      'ಅವು ಸ್ಟಿಕರ್‌ನ ಹೊರಗಿವೆ, ಹಾಗಾಗಿ ಏನೂ ಕತ್ತರಿಸಿ ಹೋಗುವುದಿಲ್ಲ.';

  @override
  String get studioPrintFullSize => '100% ನಲ್ಲಿ ಮುದ್ರಿಸಿ';

  @override
  String get studioPrintFullSizeBody =>
      '\"fit to page\" ಅಥವಾ \"shrink to fit\" ಆಫ್ ಮಾಡಿ. ಹಾಳೆ ಈಗಾಗಲೇ ಸರಿಯಾದ ಗಾತ್ರದಲ್ಲಿದೆ.';

  @override
  String get studioPaperTooSmall => 'ಸ್ಟಿಕರ್‌ಗೆ ಈ ಕಾಗದ ತುಂಬಾ ಚಿಕ್ಕದು.';

  @override
  String get studioStickerTooSmall =>
      'ಇಷ್ಟು ಚಿಕ್ಕ ಸ್ಟಿಕರ್ ಅನ್ನು ಕಾರಿನ ಹೊರಗಿನಿಂದ ಸ್ಕ್ಯಾನ್ ಮಾಡುವುದು ಕಷ್ಟ. ಪ್ರತಿ ಹಾಳೆಗೆ ಕಡಿಮೆ, ಅಥವಾ ದೊಡ್ಡ ಕಾಗದ, ಗಾಜಿನ ಮೂಲಕ ಚೆನ್ನಾಗಿ ಕಾಣುತ್ತದೆ.';

  @override
  String get studioPdfFailed => 'PDF ರಚಿಸಲು ಆಗಲಿಲ್ಲ.';

  @override
  String get studioImageFailed => 'ಸ್ಟಿಕರ್ ಚಿತ್ರ ರಚಿಸಲು ಆಗಲಿಲ್ಲ.';

  @override
  String get studioPrinterFailed =>
      'ಪ್ರಿಂಟರ್ ತಲುಪಲು ಆಗಲಿಲ್ಲ. ಬದಲಿಗೆ PDF ಕಳಿಸಿ ನೋಡಿ.';

  @override
  String get studioShareSubject => 'ನನ್ನ Avahanaa QR ಸ್ಟಿಕರ್';

  @override
  String get studioShareText =>
      'ನನ್ನ ವಾಹನದ ಬಗ್ಗೆ ನನ್ನನ್ನು ತಲುಪಲು ಈ Avahanaa ಕೋಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ.';

  @override
  String get studioShareImage => 'ಸ್ಟಿಕರ್ ಚಿತ್ರ ಹಂಚಿ';

  @override
  String get studioScanLinkCopied => 'ಸ್ಕ್ಯಾನ್ ಲಿಂಕ್ ನಕಲಾಗಿದೆ';

  @override
  String get studioPreparing => 'ಸಿದ್ಧವಾಗುತ್ತಿದೆ…';

  @override
  String studioPreviewOf(String style, String plate) {
    return '$plate ಗಾಗಿ ನಿಮ್ಮ $style ಸ್ಟಿಕರ್‌ನ ಮುನ್ನೋಟ';
  }

  @override
  String get profileTitle => 'ಪ್ರೊಫೈಲ್';

  @override
  String get profileAccount => 'ಖಾತೆ';

  @override
  String get profileSettings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get profileYourGarage => 'ನಿಮ್ಮ ಗ್ಯಾರೇಜ್';

  @override
  String get profileYourVehicles => 'ನಿಮ್ಮ ವಾಹನಗಳು';

  @override
  String get profileAdd => 'ಸೇರಿಸಿ';

  @override
  String get profileAddVehicle => 'ವಾಹನ ಸೇರಿಸಿ';

  @override
  String get profileEditVehicle => 'ವಾಹನ ಸಂಪಾದಿಸಿ';

  @override
  String get profileNoVehicles => 'ಇನ್ನೂ ವಾಹನಗಳಿಲ್ಲ';

  @override
  String get profileNoVehiclesBody =>
      'ವಾಹನ ಸೇರಿಸಿದರೆ Avahanaa ಅದರ QR ಸ್ಟಿಕರ್ ಅನ್ನು ತಾನೇ ರಚಿಸುತ್ತದೆ.';

  @override
  String get profileNoDetails => 'ಇನ್ನೂ ವಿವರಗಳಿಲ್ಲ';

  @override
  String get profileQrActive => 'QR ಸಕ್ರಿಯ';

  @override
  String get profileQrPaused => 'QR ವಿರಾಮ';

  @override
  String get profilePrimary => 'ಮುಖ್ಯ';

  @override
  String get profileMakePrimary => 'ಮುಖ್ಯ ಮಾಡಿ';

  @override
  String get profileAlertsToday => 'ಇಂದಿನ ಸೂಚನೆಗಳು';

  @override
  String get profileAlertsAllTime => 'ಒಟ್ಟು ಸೂಚನೆಗಳು';

  @override
  String get profileProtectionOn => 'ರಕ್ಷಣೆ ಚಾಲೂ ಇದೆ';

  @override
  String get profileProtectionOff => 'ರಕ್ಷಣೆ ಆಫ್ ಆಗಿದೆ';

  @override
  String get profileProtectionOnBody =>
      'ಎಲ್ಲಾ ವಾಹನಗಳ ಸ್ಕ್ಯಾನ್‌ಗಳು ನಿಮ್ಮನ್ನು ತಲುಪುತ್ತವೆ';

  @override
  String get profileProtectionOffBody =>
      'ನಿಮ್ಮ ಸ್ಟಿಕರ್ ಸ್ಕ್ಯಾನ್ ಮಾಡುವವರಿಗೆ ನಿಮ್ಮನ್ನು ತಲುಪಲು ಆಗುವುದಿಲ್ಲ ಎಂದು ಕಾಣುತ್ತದೆ';

  @override
  String get profileProtectionFailed => 'ರಕ್ಷಣೆ ಬದಲಾಯಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get profilePhoneNumber => 'ಫೋನ್ ಸಂಖ್ಯೆ';

  @override
  String get profilePhoneNotSet =>
      'ಹೊಂದಿಸಿಲ್ಲ — ಖಾತೆ ಮರುಪಡೆಯಲು ಮಾತ್ರ ಬಳಸಲಾಗುತ್ತದೆ';

  @override
  String get profileChangePassword => 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಿಸಿ';

  @override
  String get profileCurrentPassword => 'ಈಗಿನ ಪಾಸ್‌ವರ್ಡ್';

  @override
  String get profileNewPassword => 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್';

  @override
  String get profileConfirmNewPassword => 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ಖಚಿತಪಡಿಸಿ';

  @override
  String get profilePasswordUpdated => 'ಪಾಸ್‌ವರ್ಡ್ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get profilePhoneUpdated => 'ಫೋನ್ ಸಂಖ್ಯೆ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get profilePrimaryUpdated => 'ಮುಖ್ಯ ವಾಹನ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get profileLegalPrivacy => 'ಕಾನೂನು ಮತ್ತು ಗೌಪ್ಯತೆ';

  @override
  String get profileLegalSubtitle => 'ಗೌಪ್ಯತಾ ನೀತಿ ಮತ್ತು ಸೇವಾ ನಿಯಮಗಳು';

  @override
  String get profileSignOut => 'ಸೈನ್ ಔಟ್';

  @override
  String get profileDeleteAccount => 'ಖಾತೆ ಅಳಿಸಿ';

  @override
  String get profileDeleteAccountQ => 'ಖಾತೆ ಅಳಿಸಬೇಕೆ?';

  @override
  String get profileDeleteAccountBody =>
      'ನಿಮ್ಮ QR ಕೋಡ್‌ಗಳು ಮತ್ತು ಸೂಚನೆಗಳನ್ನು ಶಾಶ್ವತವಾಗಿ ತೆಗೆದುಹಾಕುತ್ತದೆ';

  @override
  String get profileDeleteForever => 'ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಿ';

  @override
  String get profileDeleteVehicleQ => 'ವಾಹನ ಅಳಿಸಬೇಕೆ?';

  @override
  String get profileDelete => 'ಅಳಿಸಿ';

  @override
  String get profileCancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get profileSave => 'ಉಳಿಸಿ';

  @override
  String get profileEnterPassword => 'ಖಚಿತಪಡಿಸಲು ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ';

  @override
  String get profileEnterRegistration => 'ನಿಮ್ಮ ನೋಂದಣಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ';

  @override
  String get profileColourModelHint =>
      'ಬಣ್ಣ ಮತ್ತು ಮಾದರಿ, ವಾಹನ ಕಂಡವರಿಗೆ ಸರಿಯಾದ ವ್ಯಕ್ತಿಗೆ ತಿಳಿಸುತ್ತಿದ್ದೇವೆ ಎಂದು ಖಚಿತಪಡಿಸಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ.';

  @override
  String get profileQrAutoCreated => 'ಅದರ QR ಸ್ಟಿಕರ್ ತಾನೇ ರಚನೆಯಾಗುತ್ತದೆ.';

  @override
  String get profileLanguage => 'ಭಾಷೆ';

  @override
  String get profileLanguageOverline => 'ಭಾಷೆ';

  @override
  String get profileLanguageTitle => 'Avahanaa ಯಾವ ಭಾಷೆ ಮಾತನಾಡುತ್ತದೆ';

  @override
  String profileVehiclesCount(int count) {
    return '$count ವಾಹನಗಳು';
  }

  @override
  String profileSinceDate(String date) {
    return '$date ರಿಂದ';
  }

  @override
  String get errUnexpected => 'ಅನಿರೀಕ್ಷಿತ ದೋಷ ಸಂಭವಿಸಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errCreateProfile =>
      'ಬಳಕೆದಾರ ಪ್ರೊಫೈಲ್ ರಚಿಸಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errSignOut => 'ಸೈನ್ ಔಟ್ ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errResetEmail =>
      'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳಿಸಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errNoUser => 'ಸದ್ಯ ಯಾರೂ ಸೈನ್ ಇನ್ ಆಗಿಲ್ಲ.';

  @override
  String get errVerifyEmail =>
      'ಪರಿಶೀಲನಾ ಇಮೇಲ್ ಕಳಿಸಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errRefreshUser =>
      'ಬಳಕೆದಾರರ ಮಾಹಿತಿ ರಿಫ್ರೆಶ್ ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errUpdateEmail => 'ಇಮೇಲ್ ನವೀಕರಿಸಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errUpdatePassword =>
      'ಪಾಸ್‌ವರ್ಡ್ ನವೀಕರಿಸಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errDeleteAccount => 'ಖಾತೆ ಅಳಿಸಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errWeakPassword => 'ಪಾಸ್‌ವರ್ಡ್ ದುರ್ಬಲವಾಗಿದೆ. ಕನಿಷ್ಠ 6 ಅಕ್ಷರ ಬಳಸಿ.';

  @override
  String get errEmailInUse => 'ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಈಗಾಗಲೇ ಖಾತೆ ಇದೆ.';

  @override
  String get errInvalidEmail => 'ಸರಿಯಾದ ಇಮೇಲ್ ವಿಳಾಸ ನಮೂದಿಸಿ.';

  @override
  String get errUserNotFound => 'ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ಸಿಗಲಿಲ್ಲ.';

  @override
  String get errWrongPassword => 'ಪಾಸ್‌ವರ್ಡ್ ತಪ್ಪಾಗಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errUserDisabled => 'ಈ ಖಾತೆಯನ್ನು ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.';

  @override
  String get errTooManyRequests =>
      'ತುಂಬಾ ಪ್ರಯತ್ನಗಳಾಗಿವೆ. ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get errNotAllowed => 'ಈ ಕ್ರಿಯೆಗೆ ಅನುಮತಿ ಇಲ್ಲ.';

  @override
  String get errNeedsRecentLogin =>
      'ಈ ಕ್ರಿಯೆ ಪೂರ್ಣಗೊಳಿಸಲು ಮತ್ತೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.';

  @override
  String get errSaveVehicle => 'ವಾಹನ ಉಳಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errDeleteVehicle => 'ವಾಹನ ಅಳಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errSetPrimary => 'ಮುಖ್ಯ ವಾಹನ ಹೊಂದಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errQrStatus => 'QR ಕೋಡ್ ಸ್ಥಿತಿ ನವೀಕರಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errUpdateProfile => 'ಪ್ರೊಫೈಲ್ ನವೀಕರಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errDeleteNotification => 'ಸೂಚನೆ ಅಳಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errMarkRead => 'ಸೂಚನೆಗಳನ್ನು ಓದಿದೆ ಎಂದು ಗುರುತಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get errClearNotifications => 'ಸೂಚನೆಗಳನ್ನು ತೆರವುಗೊಳಿಸಲು ಆಗಲಿಲ್ಲ';

  @override
  String get valEnterRegistration => 'ನಿಮ್ಮ ನೋಂದಣಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ';

  @override
  String get valInvalidRegistration => 'ಸರಿಯಾದ ನೋಂದಣಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ';

  @override
  String get valEnterEmail => 'ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸ ನಮೂದಿಸಿ';

  @override
  String get valInvalidEmail => 'ಇದು ಇಮೇಲ್ ವಿಳಾಸದಂತೆ ಕಾಣುತ್ತಿಲ್ಲ';

  @override
  String get valEnterPassword => 'ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ';

  @override
  String get valPasswordLength => 'ಕನಿಷ್ಠ 6 ಅಕ್ಷರ ಬಳಸಿ';

  @override
  String get valPasswordsDiffer => 'ಪಾಸ್‌ವರ್ಡ್‌ಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ';

  @override
  String get valEnterColour => 'ನಿಮ್ಮ ವಾಹನದ ಬಣ್ಣ ನಮೂದಿಸಿ';

  @override
  String get valEnterModel => 'ನಿಮ್ಮ ವಾಹನದ ಮಾದರಿ ನಮೂದಿಸಿ';

  @override
  String get valInvalidPhone => 'ಇದು ಸರಿಯಾದ ಸಂಖ್ಯೆಯಂತೆ ಕಾಣುತ್ತಿಲ್ಲ';

  @override
  String get alertsOptions => 'ಸೂಚನೆ ಆಯ್ಕೆಗಳು';

  @override
  String get alertsMarkAllRead => 'ಎಲ್ಲವನ್ನೂ ಓದಿದೆ ಎಂದು ಗುರುತಿಸಿ';

  @override
  String get alertsClearAll => 'ಎಲ್ಲವನ್ನೂ ತೆರವುಗೊಳಿಸಿ';

  @override
  String get alertsClearAllQ => 'ಎಲ್ಲಾ ಸೂಚನೆಗಳನ್ನು ತೆರವುಗೊಳಿಸಬೇಕೆ?';

  @override
  String get alertsClearAllBody =>
      'ಪ್ರತಿ ಸೂಚನೆಯೂ ಈ ಫೋನ್ ಮತ್ತು ನಿಮ್ಮ ಖಾತೆಯಿಂದ ಅಳಿಸಿಹೋಗುತ್ತದೆ. ಇದನ್ನು ಹಿಂಪಡೆಯಲು ಆಗುವುದಿಲ್ಲ.';

  @override
  String get alertsCleared => 'ಎಲ್ಲಾ ಸೂಚನೆಗಳನ್ನು ತೆರವುಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get alertsDeleted => 'ಸೂಚನೆ ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get alertsNothingToMark => 'ಗುರುತಿಸಲು ಏನೂ ಉಳಿದಿಲ್ಲ';

  @override
  String get alertsNoLongerAvailable => 'ಆ ಸೂಚನೆ ಈಗ ಲಭ್ಯವಿಲ್ಲ.';

  @override
  String get alertsLoadFailed => 'ನಿಮ್ಮ ಸೂಚನೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಆಗಲಿಲ್ಲ';

  @override
  String get alertsLoadFailedBody =>
      'ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ. ಹೊಸ ಸೂಚನೆಗಳು ಈಗಲೂ ನಿಮ್ಮ ಫೋನ್‌ನಲ್ಲಿ ಸದ್ದು ಮಾಡುತ್ತವೆ.';

  @override
  String get alertsEmptyTitle => 'ಚಿಂತಿಸುವ ಅಗತ್ಯವಿಲ್ಲ';

  @override
  String get alertsEmptyBody =>
      'ನಿಮ್ಮ ವಾಹನದ ಬಗ್ಗೆ ಯಾರೂ ನಿಮ್ಮನ್ನು ಸಂಪರ್ಕಿಸಬೇಕಾಗಿ ಬಂದಿಲ್ಲ. ಯಾರಾದರೂ ನಿಮ್ಮ ಕೋಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿದರೆ ಸೂಚನೆ ಇಲ್ಲಿ ಬರುತ್ತದೆ.';

  @override
  String get commonShowPassword => 'ಪಾಸ್‌ವರ್ಡ್ ತೋರಿಸಿ';

  @override
  String get commonHidePassword => 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆಮಾಡಿ';

  @override
  String get commonUpdating => 'ನವೀಕರಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get commonLive => 'ಸಕ್ರಿಯ';

  @override
  String get commonPaused => 'ವಿರಾಮ';

  @override
  String get styleSignature => 'ಸಿಗ್ನೇಚರ್';

  @override
  String get styleSignatureDesc => 'ಬಿಳಿ ಕಾಗದದ ಮೇಲೆ ಬ್ರ್ಯಾಂಡ್ ಹೆಡರ್';

  @override
  String get styleBold => 'ಬೋಲ್ಡ್';

  @override
  String get styleBoldDesc => 'ಎದ್ದುಕಾಣುವ ಬಣ್ಣದ ಫಲಕ — ಹೆಚ್ಚು ಶಾಯಿ ಬೇಕು';

  @override
  String get styleMinimal => 'ಮಿನಿಮಲ್';

  @override
  String get styleMinimalDesc => 'ಕಪ್ಪು-ಬಿಳುಪು — ಸ್ಕ್ಯಾನ್‌ಗೆ ಅತ್ಯುತ್ತಮ';

  @override
  String get styleMidnight => 'ಮಿಡ್‌ನೈಟ್';

  @override
  String get styleMidnightDesc => 'ಗಾಢ ಬೂದು ಫಲಕ, ಬಿಳಿ ಕೋಡ್ ಕಾರ್ಡ್';

  @override
  String get styleEmber => 'ಎಂಬರ್';

  @override
  String get styleEmberDesc =>
      'ಬೆಚ್ಚಗಿನ ತುಕ್ಕು ಬಣ್ಣದ ಹೆಡರ್ — ಮುಸ್ಸಂಜೆಯಲ್ಲಿ ಸುಲಭವಾಗಿ ಕಾಣುತ್ತದೆ';

  @override
  String get styleEmerald => 'ಎಮರಾಲ್ಡ್';

  @override
  String get styleEmeraldDesc => 'ಬಿಳಿ ಕಾಗದದ ಮೇಲೆ ಶಾಂತ ಹಸಿರು ಹೆಡರ್';

  @override
  String get styleIndigo => 'ಇಂಡಿಗೋ';

  @override
  String get styleIndigoDesc => 'ಇಂಡಿಗೋ ಫಲಕ — ಹೆಚ್ಚು ಶಾಯಿ ಬೇಕು';

  @override
  String get styleIvory => 'ಐವರಿ';

  @override
  String get styleIvoryDesc => 'ಬೆಚ್ಚಗಿನ ಕೆನೆ ಕಾಗದ, ಕಡುಕಂದು ಶಾಯಿ';

  @override
  String get sizeShare => 'ಹಂಚಿಕೆ';

  @override
  String get sizeShareDesc => 'WhatsApp ಮತ್ತು ಇಮೇಲ್‌ಗೆ ಸೂಕ್ತ';

  @override
  String get sizePrint => 'ಮುದ್ರಣ';

  @override
  String get sizePrintDesc =>
      '300dpi ನಲ್ಲಿ A5 — ಇದನ್ನು ಪ್ರಿಂಟ್ ಅಂಗಡಿಗೆ ಒಯ್ಯಿರಿ';

  @override
  String get paperA4Desc => 'ಯಾವುದೇ ಪ್ರಿಂಟ್ ಅಂಗಡಿಯ ಸಾಮಾನ್ಯ ಹಾಳೆ';

  @override
  String get paperA5Desc => 'A4 ನ ಅರ್ಧ — ಒಂದು ಸ್ಟಿಕರ್ ತುಂಬುತ್ತದೆ';

  @override
  String get paperA6Desc => 'ಪೋಸ್ಟ್‌ಕಾರ್ಡ್ ಗಾತ್ರ — ಸಣ್ಣ ವಿಂಡ್‌ಸ್ಕ್ರೀನ್ ತುಣುಕು';

  @override
  String get paperLetterDesc => 'US ಕಚೇರಿ ಕಾಗದ';

  @override
  String get profileVehicleCountOne => '1 ವಾಹನ';

  @override
  String get creditsTitle => 'ಎಚ್ಚರಿಕೆ ಕ್ರೆಡಿಟ್‌ಗಳು';

  @override
  String creditsRemaining(int count) {
    return '$count ಪೂರ್ಣ-ಬಲದ ಎಚ್ಚರಿಕೆಗಳು ಬಾಕಿ';
  }

  @override
  String creditsRemainingShort(int count) {
    return '$count ಎಚ್ಚರಿಕೆಗಳು ಬಾಕಿ';
  }

  @override
  String get creditsEmptyShort => 'ಎಚ್ಚರಿಕೆಗಳು ಮುಗಿದಿವೆ';

  @override
  String get creditsEmptyTitle => 'ನಿಮ್ಮ ಎಚ್ಚರಿಕೆ ಕ್ರೆಡಿಟ್‌ಗಳು ಮುಗಿದಿವೆ';

  @override
  String get creditsEmptyBody =>
      'ಎಚ್ಚರಿಕೆಗಳು ಇನ್ನೂ ತಲುಪುತ್ತವೆ — ಅಲಾರಂ ಇಲ್ಲದೆ, ಮೌನವಾಗಿ.';

  @override
  String creditsBreakdown(int free, int earned, int days) {
    return '$free ಉಚಿತ ($days ದಿನಗಳಲ್ಲಿ ಮರುಹೊಂದಿಕೆ) · $earned ಗಳಿಸಿದ್ದು';
  }

  @override
  String get creditsEmergencyAlwaysFree =>
      'ತುರ್ತು ಪರಿಸ್ಥಿತಿಗಳು ಕ್ರೆಡಿಟ್ ಇರಲಿ ಇಲ್ಲದಿರಲಿ ಪೂರ್ಣ ಶಬ್ದದಲ್ಲಿ ಮೊಳಗುತ್ತವೆ.';

  @override
  String creditsWatchAd(int count) {
    return '$count ಜಾಹೀರಾತು ನೋಡಿ';
  }

  @override
  String get creditsGoUnlimited => 'ಅನಿಯಮಿತ ಪಡೆಯಿರಿ';

  @override
  String get creditsEarnedOne => 'ಕ್ರೆಡಿಟ್ ಸೇರಿಸಲಾಗಿದೆ';

  @override
  String get creditsAdUnavailable =>
      'ಈಗ ಯಾವುದೇ ಜಾಹೀರಾತು ಲಭ್ಯವಿಲ್ಲ. ಒಂದು ನಿಮಿಷದಲ್ಲಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get creditsAdDismissed => 'ಕ್ರೆಡಿಟ್ ಗಳಿಸಲು ಪೂರ್ಣ ಜಾಹೀರಾತು ನೋಡಿ.';

  @override
  String get plansTitle => 'ಮುಖ್ಯವಾದ ಎಚ್ಚರಿಕೆಯನ್ನು ಎಂದಿಗೂ ತಪ್ಪಿಸಬೇಡಿ';

  @override
  String plansSubtitle(int count) {
    return 'ತಿಂಗಳಿಗೆ $count ಪೂರ್ಣ-ಬಲದ ಎಚ್ಚರಿಕೆಗಳು ಎಂದೆಂದಿಗೂ ಉಚಿತ. ಜಾಹೀರಾತುಗಳಿಂದ ತುಂಬಿಸಿ, ಅಥವಾ ಮಿತಿಯನ್ನೇ ತೆಗೆದುಹಾಕಿ.';
  }

  @override
  String get plansPromiseEmergency =>
      'ತುರ್ತು ಪರಿಸ್ಥಿತಿಗೆ ಎಂದಿಗೂ ಮಿತಿ ಇಲ್ಲ. ಬೆಂಕಿ, ಅಪಘಾತ ಅಥವಾ ಗಾಯ — ನಿಮ್ಮ ಬಾಕಿ ಏನೇ ಇರಲಿ, ಫೋನ್ ಪೂರ್ಣ ಶಬ್ದದಲ್ಲಿ ಮೊಳಗುತ್ತದೆ.';

  @override
  String get plansPromiseNeverSilent =>
      'ನೀವು ಎಂದಿಗೂ ಸಂಪರ್ಕಕ್ಕೆ ಸಿಗದವರಾಗುವುದಿಲ್ಲ. ಶೂನ್ಯ ಕ್ರೆಡಿಟ್‌ನಲ್ಲೂ ಎಚ್ಚರಿಕೆಗಳು ಬರುತ್ತವೆ — ಅಲಾರಂ ಮತ್ತು ಜ್ಞಾಪನೆಗಳಿಲ್ಲದೆ, ಮೌನವಾಗಿ.';

  @override
  String get plansPromisePrivate =>
      'ನಿಮ್ಮ ಸ್ಟಿಕರ್ ಸ್ಕ್ಯಾನ್ ಮಾಡುವವರಿಗೆ ನಿಮ್ಮ ಯೋಜನೆಯ ಬಗ್ಗೆ ಏನೂ ತಿಳಿಯುವುದಿಲ್ಲ, ಮತ್ತು ನೀವು ಯಾರೆಂದೂ ತಿಳಿಯುವುದಿಲ್ಲ.';

  @override
  String get plansFreeOverline => 'ಉಚಿತ';

  @override
  String get plansAdTitle => 'ಗಮನವನ್ನು ಎಚ್ಚರಿಕೆಗಳಾಗಿ ಬದಲಿಸಿ';

  @override
  String plansAdBody(int ads, int credits) {
    return '$ads ಸಣ್ಣ ಜಾಹೀರಾತುಗಳನ್ನು ನೋಡಿ, ಇನ್ನೂ $credits ಪೂರ್ಣ-ಬಲದ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಪಡೆಯಿರಿ. ಪ್ರತಿಯೊಂದೂ ಮುಗಿದ ಕ್ಷಣವೇ ಜಮೆಯಾಗುತ್ತದೆ — ಯಾವಾಗ ಬೇಕಾದರೂ ನಿಲ್ಲಿಸಿ.';
  }

  @override
  String plansAdProgress(int watched, int total) {
    return 'ಈ ಸಲ $total ರಲ್ಲಿ $watched ನೋಡಲಾಗಿದೆ';
  }

  @override
  String plansAdCapped(int count) {
    return 'ನೀವು ಗರಿಷ್ಠ $count ಗಳಿಸಿದ ಕ್ರೆಡಿಟ್‌ಗಳನ್ನು ಹೊಂದಿದ್ದೀರಿ.';
  }

  @override
  String get plansAdCta => 'ಜಾಹೀರಾತು ನೋಡಿ';

  @override
  String get plansPaidOverline => 'ಅವಾಹನಾ ಪ್ಲಸ್';

  @override
  String get plansPaidTitle => 'ಮಿತಿಯನ್ನು ತೆಗೆದುಹಾಕಿ';

  @override
  String get plansChangeTitle => 'ನಿಮ್ಮ ಯೋಜನೆ ಬದಲಾಯಿಸಿ';

  @override
  String get plansRecommended => 'ಜನಪ್ರಿಯ';

  @override
  String get plansCurrent => 'ಪ್ರಸ್ತುತ';

  @override
  String plansSaving(int percent) {
    return 'ವಾರದ ದರಕ್ಕಿಂತ $percent% ಉಳಿತಾಯ';
  }

  @override
  String get planWeekly => 'ವಾರಕ್ಕೊಮ್ಮೆ';

  @override
  String get planMonthly => 'ತಿಂಗಳಿಗೊಮ್ಮೆ';

  @override
  String get planYearly => 'ವರ್ಷಕ್ಕೊಮ್ಮೆ';

  @override
  String get planFree => 'ಉಚಿತ';

  @override
  String get planPerWeek => 'ಪ್ರತಿ ವಾರ ಬಿಲ್ ಆಗುತ್ತದೆ';

  @override
  String get planPerMonth => 'ಪ್ರತಿ ತಿಂಗಳು ಬಿಲ್ ಆಗುತ್ತದೆ';

  @override
  String get planPerYear => 'ಪ್ರತಿ ವರ್ಷ ಬಿಲ್ ಆಗುತ್ತದೆ';

  @override
  String get planUnlimited => 'ಅನಿಯಮಿತ';

  @override
  String get planActiveTitle => 'ಅವಾಹನಾ ಪ್ಲಸ್ ಸಕ್ರಿಯವಾಗಿದೆ';

  @override
  String get planActiveBody =>
      'ನಿಮ್ಮ ಎಲ್ಲಾ ವಾಹನಗಳಿಗೆ ಅನಿಯಮಿತ ಪೂರ್ಣ-ಬಲದ ಎಚ್ಚರಿಕೆಗಳು.';

  @override
  String planRenewsOn(String date) {
    return '$date ರಂದು ನವೀಕರಣ';
  }

  @override
  String get planActivated => 'ಅವಾಹನಾ ಪ್ಲಸ್ ಸಕ್ರಿಯವಾಗಿದೆ. ಎಚ್ಚರಿಕೆಗಳು ಅನಿಯಮಿತ.';

  @override
  String get planPurchaseFailed =>
      'Google Play ಆ ಖರೀದಿಯನ್ನು ಪೂರ್ಣಗೊಳಿಸಲಾಗಲಿಲ್ಲ.';

  @override
  String get planRestore => 'ಹಿಂದಿನ ಖರೀದಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಿ';

  @override
  String get planLegalNote =>
      'ಚಂದಾದಾರಿಕೆಗಳು ರದ್ದುಗೊಳಿಸುವವರೆಗೆ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ನವೀಕರಣಗೊಳ್ಳುತ್ತವೆ. Google Play ನಲ್ಲಿ ಯಾವಾಗ ಬೇಕಾದರೂ ನಿರ್ವಹಿಸಿ ಅಥವಾ ರದ್ದುಗೊಳಿಸಿ. ಬೆಲೆಗಳಲ್ಲಿ ತೆರಿಗೆ ಸೇರಿದೆ.';

  @override
  String get settingsPlan => 'ಎಚ್ಚರಿಕೆ ಕ್ರೆಡಿಟ್‌ಗಳು ಮತ್ತು ಯೋಜನೆ';

  @override
  String get reasonTest => 'ಪರೀಕ್ಷಾ ಎಚ್ಚರಿಕೆ';

  @override
  String get guidanceTest =>
      'ಇದನ್ನು ನೀವೇ ಕೇಳಿದ್ದೀರಿ. ನಿಜವಾದ ಎಚ್ಚರಿಕೆ ಥೇಟ್ ಹೀಗೇ ಬರುತ್ತದೆ.';

  @override
  String get selfTestTitle => 'ಅಲಾರಂ ಪರೀಕ್ಷಿಸಿ';

  @override
  String get selfTestSubtitle => 'ನಿಮಗೇ ನಿಜವಾದ ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಿ';

  @override
  String get selfTestSending => 'ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get selfTestSent =>
      'ಕಳುಹಿಸಲಾಗಿದೆ. ಫೋನ್ ಲಾಕ್ ಮಾಡಿ — ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ ಮೊಳಗಬೇಕು.';

  @override
  String get selfTestSheetTitle => 'ನಿಮಗೇ ನಿಜವಾದ ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಿ';

  @override
  String get selfTestSheetBody =>
      'ಅಪರಿಚಿತರ ಸ್ಕ್ಯಾನ್ ನಡೆಸುವ ಇಡೀ ಹಾದಿಯನ್ನೇ ಇದು ನಡೆಯುತ್ತದೆ: ಅದೇ ಅಲಾರಂ, ಅದೇ ಲಾಕ್ ಸ್ಕ್ರೀನ್, ಅದೇ ಜ್ಞಾಪನೆಗಳು. ಇದಕ್ಕೆ ಯಾವ ಕ್ರೆಡಿಟ್ ಖರ್ಚಾಗುವುದಿಲ್ಲ.\n\nಏನೂ ಬರದಿದ್ದರೆ, ನಿಮ್ಮ ಫೋನ್ ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಅವಾಹನಾವನ್ನು ತಡೆಯುತ್ತಿದೆ — ಸರಿಪಡಿಸುವುದು ಹೇಗೆಂದು ಎಚ್ಚರಿಕೆಗಳ ಪರದೆ ತಿಳಿಸುತ್ತದೆ.';

  @override
  String get selfTestSheetCta => 'ಪರೀಕ್ಷಾ ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಿ';

  @override
  String get selfTestLockHint =>
      'ಈಗ ಫೋನ್ ಲಾಕ್ ಮಾಡಿ, ಆಗ ನಿಜವಾದ ಎಚ್ಚರಿಕೆ ಹೇಗಿರುತ್ತದೆ ಎಂದು ಕಾಣುತ್ತದೆ.';

  @override
  String get alertsWhereTitle => 'ನಿಮ್ಮ ವಾಹನ ಎಲ್ಲಿದೆ';

  @override
  String get alertsWhereApprox => 'ಅಂದಾಜು — Maps ನಲ್ಲಿ ತೆರೆಯಲು ಟ್ಯಾಪ್ ಮಾಡಿ';

  @override
  String alertsWhereAccuracy(int metres) {
    return 'ಸುಮಾರು $metres ಮೀ ನಿಖರ — Maps ನಲ್ಲಿ ತೆರೆಯಲು ಟ್ಯಾಪ್ ಮಾಡಿ';
  }

  @override
  String get alertsOpenInMaps => 'Maps ನಲ್ಲಿ ತೆರೆಯಿರಿ';

  @override
  String get alertsNoMapApp => 'ಆ ಸ್ಥಳವನ್ನು ಯಾವ ನಕ್ಷೆ ಆ್ಯಪ್ ಕೂಡ ತೆರೆಯಲಾಗಲಿಲ್ಲ.';

  @override
  String get alertsWhereOverline => 'ಎಲ್ಲಿ';

  @override
  String get readinessPermissionTitle =>
      'ಈ ಫೋನ್‌ಗೆ ಎಚ್ಚರಿಕೆಗಳು ತಲುಪಲಾಗುತ್ತಿಲ್ಲ';

  @override
  String get readinessPermissionBody =>
      'ನಿಮ್ಮ ಫೋನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಅವಾಹನಾಗೆ ಅಧಿಸೂಚನೆಗಳು ಆಫ್ ಆಗಿವೆ. ಅವು ಮತ್ತೆ ಆನ್ ಆಗುವವರೆಗೆ ಏನೂ ಬರುವುದಿಲ್ಲ — ತುರ್ತು ಕೂಡ ಇಲ್ಲ.';

  @override
  String get readinessPreferenceTitle =>
      'ನಿಮ್ಮ ಎಚ್ಚರಿಕೆಗಳನ್ನು ನೀವೇ ವಿರಾಮಗೊಳಿಸಿದ್ದೀರಿ';

  @override
  String get readinessPreferenceBody =>
      'ಅವಾಹನಾ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಎಚ್ಚರಿಕೆಗಳು ಆಫ್ ಆಗಿವೆ. ನಿಮ್ಮ QR ಇನ್ನೂ ಕೆಲಸ ಮಾಡುತ್ತದೆ, ಆದರೆ ನಿಮಗೆ ಏನೂ ತಲುಪುವುದಿಲ್ಲ.';

  @override
  String get readinessTokenTitle => 'ಈ ಫೋನ್ ಇನ್ನೂ ನೋಂದಣಿಯಾಗಿಲ್ಲ';

  @override
  String get readinessTokenBody =>
      'ಎಚ್ಚರಿಕೆಗಳಿಗಾಗಿ ಈ ಸಾಧನವನ್ನು ಅವಾಹನಾ ನೋಂದಾಯಿಸಲಾಗಿಲ್ಲ. ಆ್ಯಪ್ ಮತ್ತೆ ತೆರೆದರೆ ಸಾಮಾನ್ಯವಾಗಿ ಸರಿಯಾಗುತ್ತದೆ.';

  @override
  String get readinessFullScreenTitle =>
      'ಎಚ್ಚರಿಕೆಗಳು ಲಾಕ್ ಸ್ಕ್ರೀನ್ ಆವರಿಸುವುದಿಲ್ಲ';

  @override
  String get readinessFullScreenBody =>
      'ಅವು ಇನ್ನೂ ಬರುತ್ತವೆ ಮತ್ತು ಶಬ್ದ ಮಾಡುತ್ತವೆ — ಫೋನ್ ಲಾಕ್ ಆಗಿದ್ದಾಗ ಪೂರ್ಣ ಪರದೆ ತುಂಬುವುದಿಲ್ಲ ಅಷ್ಟೇ.';

  @override
  String get readinessGrantCta => 'ಎಚ್ಚರಿಕೆಗಳನ್ನು ಆನ್ ಮಾಡಿ';

  @override
  String get readinessPreferenceCta => 'ಎಚ್ಚರಿಕೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ';

  @override
  String get readinessTokenCta => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get creditsEarnedPending =>
      'ಜಾಹೀರಾತು ಪೂರ್ಣಗೊಂಡಿದೆ. ನಿಮ್ಮ ಕ್ರೆಡಿಟ್ ಶೀಘ್ರದಲ್ಲೇ ಕಾಣಿಸುತ್ತದೆ.';

  @override
  String get readinessFullScreenCta => 'ಲಾಕ್ ಸ್ಕ್ರೀನ್ ಎಚ್ಚರಿಕೆಗಳಿಗೆ ಅನುಮತಿಸಿ';
}
