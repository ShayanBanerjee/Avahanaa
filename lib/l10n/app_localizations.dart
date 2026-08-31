import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kn'),
  ];

  /// No description provided for @reasonBlockingDriveway.
  ///
  /// In en, this message translates to:
  /// **'Blocking Driveway'**
  String get reasonBlockingDriveway;

  /// No description provided for @reasonIllegalParking.
  ///
  /// In en, this message translates to:
  /// **'Illegal Parking'**
  String get reasonIllegalParking;

  /// No description provided for @reasonBlockingTraffic.
  ///
  /// In en, this message translates to:
  /// **'Blocking Traffic'**
  String get reasonBlockingTraffic;

  /// No description provided for @reasonDoubleParked.
  ///
  /// In en, this message translates to:
  /// **'Double Parked'**
  String get reasonDoubleParked;

  /// No description provided for @reasonEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get reasonEmergency;

  /// No description provided for @reasonPrivateProperty.
  ///
  /// In en, this message translates to:
  /// **'Private Property'**
  String get reasonPrivateProperty;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @reasonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Notification'**
  String get reasonUnknown;

  /// No description provided for @guidanceEmergency.
  ///
  /// In en, this message translates to:
  /// **'Treat this as urgent. Get to your vehicle now.'**
  String get guidanceEmergency;

  /// No description provided for @guidanceBlockingDriveway.
  ///
  /// In en, this message translates to:
  /// **'Someone cannot get in or out. Move your vehicle soon.'**
  String get guidanceBlockingDriveway;

  /// No description provided for @guidanceBlockingTraffic.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle is holding up traffic. Move it soon.'**
  String get guidanceBlockingTraffic;

  /// No description provided for @guidanceIllegalParking.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle may be towed or fined. Check on it.'**
  String get guidanceIllegalParking;

  /// No description provided for @guidanceDoubleParked.
  ///
  /// In en, this message translates to:
  /// **'You are boxing someone in. They are waiting.'**
  String get guidanceDoubleParked;

  /// No description provided for @guidancePrivateProperty.
  ///
  /// In en, this message translates to:
  /// **'You are parked on private land. You may be asked to move.'**
  String get guidancePrivateProperty;

  /// No description provided for @guidanceOther.
  ///
  /// In en, this message translates to:
  /// **'Someone at your vehicle wanted you to know.'**
  String get guidanceOther;

  /// No description provided for @replyOnMyWayNowOwner.
  ///
  /// In en, this message translates to:
  /// **'I\'m right here'**
  String get replyOnMyWayNowOwner;

  /// No description provided for @replyOnMyWayFiveOwner.
  ///
  /// In en, this message translates to:
  /// **'On my way — 5 min'**
  String get replyOnMyWayFiveOwner;

  /// No description provided for @replyOnMyWayFifteenOwner.
  ///
  /// In en, this message translates to:
  /// **'On my way — 15 min'**
  String get replyOnMyWayFifteenOwner;

  /// No description provided for @replyCannotComeOwner.
  ///
  /// In en, this message translates to:
  /// **'I can\'t get there'**
  String get replyCannotComeOwner;

  /// No description provided for @replySeenOwner.
  ///
  /// In en, this message translates to:
  /// **'Seen — thank you'**
  String get replySeenOwner;

  /// No description provided for @replySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'REPLY TO THEM'**
  String get replySectionTitle;

  /// No description provided for @replySectionBlurb.
  ///
  /// In en, this message translates to:
  /// **'They are still standing at your vehicle with the page open. One tap tells them you are coming.'**
  String get replySectionBlurb;

  /// No description provided for @replySending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get replySending;

  /// No description provided for @replyTelling.
  ///
  /// In en, this message translates to:
  /// **'Telling them…'**
  String get replyTelling;

  /// No description provided for @replyToldThem.
  ///
  /// In en, this message translates to:
  /// **'They know you are coming'**
  String get replyToldThem;

  /// No description provided for @replySentTitle.
  ///
  /// In en, this message translates to:
  /// **'They have been told'**
  String get replySentTitle;

  /// No description provided for @replySentBody.
  ///
  /// In en, this message translates to:
  /// **'Their page now reads: \"{scannerLabel}\".'**
  String replySentBody(String scannerLabel);

  /// No description provided for @replyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your reply. Check your connection and try again.'**
  String get replyFailed;

  /// No description provided for @replyYouReplied.
  ///
  /// In en, this message translates to:
  /// **'You replied'**
  String get replyYouReplied;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsWhatTheySaid.
  ///
  /// In en, this message translates to:
  /// **'WHAT THEY SAID'**
  String get alertsWhatTheySaid;

  /// No description provided for @alertsWhen.
  ///
  /// In en, this message translates to:
  /// **'WHEN'**
  String get alertsWhen;

  /// No description provided for @alertsAnonymityNote.
  ///
  /// In en, this message translates to:
  /// **'Whoever sent this stayed anonymous, and they never saw your contact details either.'**
  String get alertsAnonymityNote;

  /// No description provided for @alertsNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get alertsNew;

  /// No description provided for @alertsToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get alertsToday;

  /// No description provided for @alertsYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get alertsYesterday;

  /// No description provided for @panicHeadlineOne.
  ///
  /// In en, this message translates to:
  /// **'Someone needs you at your vehicle'**
  String get panicHeadlineOne;

  /// No description provided for @panicHeadlineMany.
  ///
  /// In en, this message translates to:
  /// **'{count} people need you at your vehicle'**
  String panicHeadlineMany(int count);

  /// No description provided for @panicSeeWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'See what happened'**
  String get panicSeeWhatHappened;

  /// No description provided for @panicViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all {count} alerts'**
  String panicViewAll(int count);

  /// No description provided for @appearanceOverline.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearanceOverline;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'How Avahanaa looks'**
  String get appearanceTitle;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'Match my phone'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Always light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Always dark'**
  String get appearanceDark;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInBlurb.
  ///
  /// In en, this message translates to:
  /// **'Sign in to stay reachable.'**
  String get authSignInBlurb;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authCreateAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAnAccount;

  /// No description provided for @authCreateYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateYourAccount;

  /// No description provided for @authYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get authYourAccount;

  /// No description provided for @authYourVehicle.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get authYourVehicle;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get authPhoneOptional;

  /// No description provided for @authRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get authRegistrationNumber;

  /// No description provided for @authMakeAndModel.
  ///
  /// In en, this message translates to:
  /// **'Make and model'**
  String get authMakeAndModel;

  /// No description provided for @authColour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get authColour;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @legalPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyPolicy;

  /// No description provided for @legalTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsOfService;

  /// No description provided for @authResetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetYourPassword;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authCheckYourEmail;

  /// No description provided for @authUseDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get authUseDifferentEmail;

  /// No description provided for @authResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend the email'**
  String get authResendEmail;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get legalTitle;

  /// No description provided for @legalShortVersion.
  ///
  /// In en, this message translates to:
  /// **'The short version'**
  String get legalShortVersion;

  /// No description provided for @legalShortBody.
  ///
  /// In en, this message translates to:
  /// **'Avahanaa never reveals your phone number, email or name to whoever scans your sticker.'**
  String get legalShortBody;

  /// No description provided for @legalPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What we collect, why, and how long we keep it'**
  String get legalPrivacySubtitle;

  /// No description provided for @legalTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The rules for using Avahanaa'**
  String get legalTermsSubtitle;

  /// No description provided for @legalCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link right now.'**
  String get legalCouldNotOpen;

  /// No description provided for @qrScanToAlertMe.
  ///
  /// In en, this message translates to:
  /// **'SCAN TO ALERT ME'**
  String get qrScanToAlertMe;

  /// No description provided for @qrYourWindshieldCode.
  ///
  /// In en, this message translates to:
  /// **'Your windshield code'**
  String get qrYourWindshieldCode;

  /// No description provided for @qrPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get qrPaused;

  /// No description provided for @qrSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code for your vehicle'**
  String get qrSemanticLabel;

  /// No description provided for @vehicleReachable.
  ///
  /// In en, this message translates to:
  /// **'Reachable — your number stays hidden'**
  String get vehicleReachable;

  /// No description provided for @vehiclePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused — scans are not reaching you'**
  String get vehiclePaused;

  /// No description provided for @vehicleYourVehicle.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get vehicleYourVehicle;

  /// No description provided for @vehicleCountOf.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {index} of {count}'**
  String vehicleCountOf(int index, int count);

  /// No description provided for @vehicleShowNumber.
  ///
  /// In en, this message translates to:
  /// **'Show vehicle {index}'**
  String vehicleShowNumber(int index);

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeVehicleReachable.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle is reachable'**
  String get homeVehicleReachable;

  /// No description provided for @homeQrPaused.
  ///
  /// In en, this message translates to:
  /// **'Your QR code is paused'**
  String get homeQrPaused;

  /// No description provided for @homeAddFirstVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add your first vehicle'**
  String get homeAddFirstVehicle;

  /// No description provided for @homeAddVehicleBody.
  ///
  /// In en, this message translates to:
  /// **'Avahanaa needs a vehicle before it can create the code for your windshield.'**
  String get homeAddVehicleBody;

  /// No description provided for @homeGoToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile'**
  String get homeGoToProfile;

  /// No description provided for @homeCreatingQr.
  ///
  /// In en, this message translates to:
  /// **'Creating your QR code'**
  String get homeCreatingQr;

  /// No description provided for @homeCreatingQrBody.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds.'**
  String get homeCreatingQrBody;

  /// No description provided for @homeSettingUpVehicle.
  ///
  /// In en, this message translates to:
  /// **'Setting up your vehicle'**
  String get homeSettingUpVehicle;

  /// No description provided for @homeSettingUpBody.
  ///
  /// In en, this message translates to:
  /// **'Moving your details over. One moment.'**
  String get homeSettingUpBody;

  /// No description provided for @homeAccountMissing.
  ///
  /// In en, this message translates to:
  /// **'Account details missing'**
  String get homeAccountMissing;

  /// No description provided for @homeAccountMissingBody.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile. Sign out and back in to fix it.'**
  String get homeAccountMissingBody;

  /// No description provided for @homeCannotReach.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach your account'**
  String get homeCannotReach;

  /// No description provided for @homeCannotReachBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection — your QR code keeps working for anyone who scans it, this screen just cannot refresh.'**
  String get homeCannotReachBody;

  /// No description provided for @homePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get homePrint;

  /// No description provided for @homeCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get homeCopyLink;

  /// No description provided for @homeDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get homeDesign;

  /// No description provided for @homeScanLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Scan link copied'**
  String get homeScanLinkCopied;

  /// No description provided for @homePrinterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the printer. Try Design to save the sheet instead.'**
  String get homePrinterFailed;

  /// No description provided for @homePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get homePreparing;

  /// No description provided for @homeUnreadAlert.
  ///
  /// In en, this message translates to:
  /// **'Unread alert'**
  String get homeUnreadAlert;

  /// No description provided for @homeUnreadAlerts.
  ///
  /// In en, this message translates to:
  /// **'Unread alerts'**
  String get homeUnreadAlerts;

  /// No description provided for @homeVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get homeVehicle;

  /// No description provided for @homeVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get homeVehicles;

  /// No description provided for @homeProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get homeProtection;

  /// No description provided for @homeGettingSetUp.
  ///
  /// In en, this message translates to:
  /// **'Getting set up'**
  String get homeGettingSetUp;

  /// No description provided for @homeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get homeHowItWorks;

  /// No description provided for @homeStepPrint.
  ///
  /// In en, this message translates to:
  /// **'Print the sticker'**
  String get homeStepPrint;

  /// No description provided for @homeStepPrintBody.
  ///
  /// In en, this message translates to:
  /// **'Share or save it, then print on plain white paper.'**
  String get homeStepPrintBody;

  /// No description provided for @homeStepStick.
  ///
  /// In en, this message translates to:
  /// **'Put it on your windshield'**
  String get homeStepStick;

  /// No description provided for @homeStepStickBody.
  ///
  /// In en, this message translates to:
  /// **'Inside the glass, driver-side corner, facing out.'**
  String get homeStepStickBody;

  /// No description provided for @homeStepAlert.
  ///
  /// In en, this message translates to:
  /// **'Get alerted in seconds'**
  String get homeStepAlert;

  /// No description provided for @homeStepAlertBody.
  ///
  /// In en, this message translates to:
  /// **'A scan rings your phone, even on silent.'**
  String get homeStepAlertBody;

  /// No description provided for @homeNumberStaysYours.
  ///
  /// In en, this message translates to:
  /// **'Your number stays yours'**
  String get homeNumberStaysYours;

  /// No description provided for @homeNumberStaysYoursBody.
  ///
  /// In en, this message translates to:
  /// **'Whoever scans your code can tell you something is wrong — and that is all. They never see your phone number, your email, or your name.'**
  String get homeNumberStaysYoursBody;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @studioTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticker studio'**
  String get studioTitle;

  /// No description provided for @studioChooseALook.
  ///
  /// In en, this message translates to:
  /// **'Choose a look'**
  String get studioChooseALook;

  /// No description provided for @studioStickerDesign.
  ///
  /// In en, this message translates to:
  /// **'Sticker design'**
  String get studioStickerDesign;

  /// No description provided for @studioPutItOnPaper.
  ///
  /// In en, this message translates to:
  /// **'Put it on paper'**
  String get studioPutItOnPaper;

  /// No description provided for @studioPrintASheet.
  ///
  /// In en, this message translates to:
  /// **'Print a sheet'**
  String get studioPrintASheet;

  /// No description provided for @studioPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get studioPaper;

  /// No description provided for @studioPerSheet.
  ///
  /// In en, this message translates to:
  /// **'Per sheet'**
  String get studioPerSheet;

  /// No description provided for @studioPrintThisSheet.
  ///
  /// In en, this message translates to:
  /// **'Print this sheet'**
  String get studioPrintThisSheet;

  /// No description provided for @studioSendPdf.
  ///
  /// In en, this message translates to:
  /// **'Send PDF to a print shop'**
  String get studioSendPdf;

  /// No description provided for @studioOrSendPicture.
  ///
  /// In en, this message translates to:
  /// **'Or send it as a picture'**
  String get studioOrSendPicture;

  /// No description provided for @studioShareTheImage.
  ///
  /// In en, this message translates to:
  /// **'Share the image'**
  String get studioShareTheImage;

  /// No description provided for @studioShareOrSave.
  ///
  /// In en, this message translates to:
  /// **'Share or save image'**
  String get studioShareOrSave;

  /// No description provided for @studioCopyScanLink.
  ///
  /// In en, this message translates to:
  /// **'Copy scan link'**
  String get studioCopyScanLink;

  /// No description provided for @studioMakeItLast.
  ///
  /// In en, this message translates to:
  /// **'Make it last'**
  String get studioMakeItLast;

  /// No description provided for @studioGettingItPrinted.
  ///
  /// In en, this message translates to:
  /// **'Getting it printed'**
  String get studioGettingItPrinted;

  /// No description provided for @studioAnyoneCanScan.
  ///
  /// In en, this message translates to:
  /// **'Anyone can scan it'**
  String get studioAnyoneCanScan;

  /// No description provided for @studioAnyoneCanScanBody.
  ///
  /// In en, this message translates to:
  /// **'No app required — a phone camera or Google Lens is enough. Keep the white border around the code clean and the sticker flat.'**
  String get studioAnyoneCanScanBody;

  /// No description provided for @studioLaminate.
  ///
  /// In en, this message translates to:
  /// **'Laminate it'**
  String get studioLaminate;

  /// No description provided for @studioLaminateBody.
  ///
  /// In en, this message translates to:
  /// **'A clear sleeve works too. Bangalore sun fades ink fast.'**
  String get studioLaminateBody;

  /// No description provided for @studioFixInside.
  ///
  /// In en, this message translates to:
  /// **'Fix it inside the windshield'**
  String get studioFixInside;

  /// No description provided for @studioFixInsideBody.
  ///
  /// In en, this message translates to:
  /// **'Driver-side corner, code facing out, nothing covering it.'**
  String get studioFixInsideBody;

  /// No description provided for @studioCutAtMarks.
  ///
  /// In en, this message translates to:
  /// **'Cut at the corner marks'**
  String get studioCutAtMarks;

  /// No description provided for @studioCutAtMarksBody.
  ///
  /// In en, this message translates to:
  /// **'They sit outside the sticker, so nothing gets clipped.'**
  String get studioCutAtMarksBody;

  /// No description provided for @studioPrintFullSize.
  ///
  /// In en, this message translates to:
  /// **'Print at 100%'**
  String get studioPrintFullSize;

  /// No description provided for @studioPrintFullSizeBody.
  ///
  /// In en, this message translates to:
  /// **'Turn off \"fit to page\" or \"shrink to fit\". The sheet is already sized.'**
  String get studioPrintFullSizeBody;

  /// No description provided for @studioPaperTooSmall.
  ///
  /// In en, this message translates to:
  /// **'This paper is too small for a sticker.'**
  String get studioPaperTooSmall;

  /// No description provided for @studioStickerTooSmall.
  ///
  /// In en, this message translates to:
  /// **'This small a sticker is hard to scan from outside the car. Fewer per sheet, or bigger paper, reads better through glass.'**
  String get studioStickerTooSmall;

  /// No description provided for @studioPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the PDF.'**
  String get studioPdfFailed;

  /// No description provided for @studioImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the sticker image.'**
  String get studioImageFailed;

  /// No description provided for @studioPrinterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach a printer. Try sending the PDF instead.'**
  String get studioPrinterFailed;

  /// No description provided for @studioShareSubject.
  ///
  /// In en, this message translates to:
  /// **'My Avahanaa QR sticker'**
  String get studioShareSubject;

  /// No description provided for @studioShareText.
  ///
  /// In en, this message translates to:
  /// **'Scan this Avahanaa code to reach me about my vehicle.'**
  String get studioShareText;

  /// No description provided for @studioShareImage.
  ///
  /// In en, this message translates to:
  /// **'Share sticker image'**
  String get studioShareImage;

  /// No description provided for @studioScanLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Scan link copied'**
  String get studioScanLinkCopied;

  /// No description provided for @studioPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get studioPreparing;

  /// No description provided for @studioPreviewOf.
  ///
  /// In en, this message translates to:
  /// **'Preview of your {style} sticker for {plate}'**
  String studioPreviewOf(String style, String plate);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileYourGarage.
  ///
  /// In en, this message translates to:
  /// **'Your garage'**
  String get profileYourGarage;

  /// No description provided for @profileYourVehicles.
  ///
  /// In en, this message translates to:
  /// **'Your vehicles'**
  String get profileYourVehicles;

  /// No description provided for @profileAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileAdd;

  /// No description provided for @profileAddVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle'**
  String get profileAddVehicle;

  /// No description provided for @profileEditVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get profileEditVehicle;

  /// No description provided for @profileNoVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet'**
  String get profileNoVehicles;

  /// No description provided for @profileNoVehiclesBody.
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle and Avahanaa creates its QR sticker automatically.'**
  String get profileNoVehiclesBody;

  /// No description provided for @profileNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No details added yet'**
  String get profileNoDetails;

  /// No description provided for @profileQrActive.
  ///
  /// In en, this message translates to:
  /// **'QR ACTIVE'**
  String get profileQrActive;

  /// No description provided for @profileQrPaused.
  ///
  /// In en, this message translates to:
  /// **'QR PAUSED'**
  String get profileQrPaused;

  /// No description provided for @profilePrimary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get profilePrimary;

  /// No description provided for @profileMakePrimary.
  ///
  /// In en, this message translates to:
  /// **'MAKE PRIMARY'**
  String get profileMakePrimary;

  /// No description provided for @profileAlertsToday.
  ///
  /// In en, this message translates to:
  /// **'Alerts today'**
  String get profileAlertsToday;

  /// No description provided for @profileAlertsAllTime.
  ///
  /// In en, this message translates to:
  /// **'Alerts all time'**
  String get profileAlertsAllTime;

  /// No description provided for @profileProtectionOn.
  ///
  /// In en, this message translates to:
  /// **'Protection is on'**
  String get profileProtectionOn;

  /// No description provided for @profileProtectionOff.
  ///
  /// In en, this message translates to:
  /// **'Protection is off'**
  String get profileProtectionOff;

  /// No description provided for @profileProtectionOnBody.
  ///
  /// In en, this message translates to:
  /// **'Scans reach you on every vehicle'**
  String get profileProtectionOnBody;

  /// No description provided for @profileProtectionOffBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone scanning your sticker will see that you cannot be reached'**
  String get profileProtectionOffBody;

  /// No description provided for @profileProtectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update protection'**
  String get profileProtectionFailed;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profilePhoneNumber;

  /// No description provided for @profilePhoneNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — only used for account recovery'**
  String get profilePhoneNotSet;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @profileCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPassword;

  /// No description provided for @profileNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileNewPassword;

  /// No description provided for @profileConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profileConfirmNewPassword;

  /// No description provided for @profilePasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get profilePasswordUpdated;

  /// No description provided for @profilePhoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone number updated'**
  String get profilePhoneUpdated;

  /// No description provided for @profilePrimaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Primary vehicle updated'**
  String get profilePrimaryUpdated;

  /// No description provided for @profileLegalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Legal & privacy'**
  String get profileLegalPrivacy;

  /// No description provided for @profileLegalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy and terms of service'**
  String get profileLegalSubtitle;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profileDeleteAccountQ;

  /// No description provided for @profileDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently removes your QR codes and alerts'**
  String get profileDeleteAccountBody;

  /// No description provided for @profileDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get profileDeleteForever;

  /// No description provided for @profileDeleteVehicleQ.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle?'**
  String get profileDeleteVehicleQ;

  /// No description provided for @profileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDelete;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get profileEnterPassword;

  /// No description provided for @profileEnterRegistration.
  ///
  /// In en, this message translates to:
  /// **'Enter your registration number'**
  String get profileEnterRegistration;

  /// No description provided for @profileColourModelHint.
  ///
  /// In en, this message translates to:
  /// **'Colour and model help whoever finds your vehicle confirm they are alerting the right person.'**
  String get profileColourModelHint;

  /// No description provided for @profileQrAutoCreated.
  ///
  /// In en, this message translates to:
  /// **'Its QR sticker is created automatically.'**
  String get profileQrAutoCreated;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLanguageOverline.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get profileLanguageOverline;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'What Avahanaa speaks'**
  String get profileLanguageTitle;

  /// No description provided for @profileVehiclesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} vehicles'**
  String profileVehiclesCount(int count);

  /// No description provided for @profileSinceDate.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String profileSinceDate(String date);

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errUnexpected;

  /// No description provided for @errCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create user profile. Please try again.'**
  String get errCreateProfile;

  /// No description provided for @errSignOut.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out. Please try again.'**
  String get errSignOut;

  /// No description provided for @errResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email. Please try again.'**
  String get errResetEmail;

  /// No description provided for @errNoUser.
  ///
  /// In en, this message translates to:
  /// **'No user is currently signed in.'**
  String get errNoUser;

  /// No description provided for @errVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification email. Please try again.'**
  String get errVerifyEmail;

  /// No description provided for @errRefreshUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh user. Please try again.'**
  String get errRefreshUser;

  /// No description provided for @errUpdateEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to update email. Please try again.'**
  String get errUpdateEmail;

  /// No description provided for @errUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password. Please try again.'**
  String get errUpdatePassword;

  /// No description provided for @errDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get errDeleteAccount;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Please use at least 6 characters.'**
  String get errWeakPassword;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get errEmailInUse;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errInvalidEmail;

  /// No description provided for @errUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errUserNotFound;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get errWrongPassword;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errUserDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errTooManyRequests;

  /// No description provided for @errNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This operation is not allowed.'**
  String get errNotAllowed;

  /// No description provided for @errNeedsRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to complete this action.'**
  String get errNeedsRecentLogin;

  /// No description provided for @errSaveVehicle.
  ///
  /// In en, this message translates to:
  /// **'Failed to save vehicle'**
  String get errSaveVehicle;

  /// No description provided for @errDeleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete vehicle'**
  String get errDeleteVehicle;

  /// No description provided for @errSetPrimary.
  ///
  /// In en, this message translates to:
  /// **'Failed to set primary vehicle'**
  String get errSetPrimary;

  /// No description provided for @errQrStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update QR code status'**
  String get errQrStatus;

  /// No description provided for @errUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get errUpdateProfile;

  /// No description provided for @errDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete alert'**
  String get errDeleteNotification;

  /// No description provided for @errMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark alerts as read'**
  String get errMarkRead;

  /// No description provided for @errClearNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear alerts'**
  String get errClearNotifications;

  /// No description provided for @valEnterRegistration.
  ///
  /// In en, this message translates to:
  /// **'Please enter your registration number'**
  String get valEnterRegistration;

  /// No description provided for @valInvalidRegistration.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid registration number'**
  String get valInvalidRegistration;

  /// No description provided for @valEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get valEnterEmail;

  /// No description provided for @valInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address'**
  String get valInvalidEmail;

  /// No description provided for @valEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get valEnterPassword;

  /// No description provided for @valPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get valPasswordLength;

  /// No description provided for @valPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match'**
  String get valPasswordsDiffer;

  /// No description provided for @valEnterColour.
  ///
  /// In en, this message translates to:
  /// **'Enter your vehicle colour'**
  String get valEnterColour;

  /// No description provided for @valEnterModel.
  ///
  /// In en, this message translates to:
  /// **'Enter your vehicle model'**
  String get valEnterModel;

  /// No description provided for @valInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a valid number'**
  String get valInvalidPhone;

  /// No description provided for @alertsOptions.
  ///
  /// In en, this message translates to:
  /// **'Alert options'**
  String get alertsOptions;

  /// No description provided for @alertsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get alertsMarkAllRead;

  /// No description provided for @alertsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get alertsClearAll;

  /// No description provided for @alertsClearAllQ.
  ///
  /// In en, this message translates to:
  /// **'Clear all alerts?'**
  String get alertsClearAllQ;

  /// No description provided for @alertsClearAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every alert will be deleted from this device and your account. This cannot be undone.'**
  String get alertsClearAllBody;

  /// No description provided for @alertsCleared.
  ///
  /// In en, this message translates to:
  /// **'All alerts cleared'**
  String get alertsCleared;

  /// No description provided for @alertsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted'**
  String get alertsDeleted;

  /// No description provided for @alertsNothingToMark.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to mark'**
  String get alertsNothingToMark;

  /// No description provided for @alertsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'That alert is no longer available.'**
  String get alertsNoLongerAvailable;

  /// No description provided for @alertsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your alerts'**
  String get alertsLoadFailed;

  /// No description provided for @alertsLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. New alerts will still ring your phone.'**
  String get alertsLoadFailedBody;

  /// No description provided for @alertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to worry about'**
  String get alertsEmptyTitle;

  /// No description provided for @alertsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No one has needed to reach you about your vehicle. When someone scans your code, the alert lands here.'**
  String get alertsEmptyBody;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @commonUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get commonUpdating;

  /// No description provided for @commonLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get commonLive;

  /// No description provided for @commonPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get commonPaused;

  /// No description provided for @styleSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get styleSignature;

  /// No description provided for @styleSignatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Branded header on white paper'**
  String get styleSignatureDesc;

  /// No description provided for @styleBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get styleBold;

  /// No description provided for @styleBoldDesc.
  ///
  /// In en, this message translates to:
  /// **'High-visibility colour panel — uses a lot of ink'**
  String get styleBoldDesc;

  /// No description provided for @styleMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get styleMinimal;

  /// No description provided for @styleMinimalDesc.
  ///
  /// In en, this message translates to:
  /// **'Black and white — best for scanning'**
  String get styleMinimalDesc;

  /// No description provided for @styleMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get styleMidnight;

  /// No description provided for @styleMidnightDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep graphite panel with a white code card'**
  String get styleMidnightDesc;

  /// No description provided for @styleEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get styleEmber;

  /// No description provided for @styleEmberDesc.
  ///
  /// In en, this message translates to:
  /// **'Warm rust header — easiest to spot at dusk'**
  String get styleEmberDesc;

  /// No description provided for @styleEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get styleEmerald;

  /// No description provided for @styleEmeraldDesc.
  ///
  /// In en, this message translates to:
  /// **'Calm green header on white paper'**
  String get styleEmeraldDesc;

  /// No description provided for @styleIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get styleIndigo;

  /// No description provided for @styleIndigoDesc.
  ///
  /// In en, this message translates to:
  /// **'Indigo panel — uses a lot of ink'**
  String get styleIndigoDesc;

  /// No description provided for @styleIvory.
  ///
  /// In en, this message translates to:
  /// **'Ivory'**
  String get styleIvory;

  /// No description provided for @styleIvoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Warm cream paper with espresso ink'**
  String get styleIvoryDesc;

  /// No description provided for @sizeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sizeShare;

  /// No description provided for @sizeShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Good for WhatsApp and email'**
  String get sizeShareDesc;

  /// No description provided for @sizePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get sizePrint;

  /// No description provided for @sizePrintDesc.
  ///
  /// In en, this message translates to:
  /// **'A5 at 300dpi — take this to a print shop'**
  String get sizePrintDesc;

  /// No description provided for @paperA4Desc.
  ///
  /// In en, this message translates to:
  /// **'The default sheet at any print shop'**
  String get paperA4Desc;

  /// No description provided for @paperA5Desc.
  ///
  /// In en, this message translates to:
  /// **'Half of A4 — one sticker fills it'**
  String get paperA5Desc;

  /// No description provided for @paperA6Desc.
  ///
  /// In en, this message translates to:
  /// **'Postcard size — a small windscreen tile'**
  String get paperA6Desc;

  /// No description provided for @paperLetterDesc.
  ///
  /// In en, this message translates to:
  /// **'US office paper'**
  String get paperLetterDesc;

  /// No description provided for @profileVehicleCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 VEHICLE'**
  String get profileVehicleCountOne;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert credits'**
  String get creditsTitle;

  /// No description provided for @creditsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} full-strength alerts left'**
  String creditsRemaining(int count);

  /// No description provided for @creditsRemainingShort.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts left'**
  String creditsRemainingShort(int count);

  /// No description provided for @creditsEmptyShort.
  ///
  /// In en, this message translates to:
  /// **'Out of alerts'**
  String get creditsEmptyShort;

  /// No description provided for @creditsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of alert credits'**
  String get creditsEmptyTitle;

  /// No description provided for @creditsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Alerts still reach you — quietly, without the alarm.'**
  String get creditsEmptyBody;

  /// No description provided for @creditsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{free} free (resets in {days} days) · {earned} earned'**
  String creditsBreakdown(int free, int earned, int days);

  /// No description provided for @creditsEmergencyAlwaysFree.
  ///
  /// In en, this message translates to:
  /// **'Emergencies always ring at full volume, credits or not.'**
  String get creditsEmergencyAlwaysFree;

  /// No description provided for @creditsWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch {count} ads'**
  String creditsWatchAd(int count);

  /// No description provided for @creditsGoUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Go unlimited'**
  String get creditsGoUnlimited;

  /// No description provided for @creditsEarnedOne.
  ///
  /// In en, this message translates to:
  /// **'Credit added'**
  String get creditsEarnedOne;

  /// No description provided for @creditsAdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ad is available right now. Try again in a minute.'**
  String get creditsAdUnavailable;

  /// No description provided for @creditsAdDismissed.
  ///
  /// In en, this message translates to:
  /// **'Watch the whole ad to earn a credit.'**
  String get creditsAdDismissed;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss the one that matters'**
  String get plansTitle;

  /// No description provided for @plansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} full-strength alerts a month are free, forever. Top up with ads, or take the meter off entirely.'**
  String plansSubtitle(int count);

  /// No description provided for @plansPromiseEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergencies are never metered. A fire, a crash or an injury rings your phone at full volume whatever your balance says.'**
  String get plansPromiseEmergency;

  /// No description provided for @plansPromiseNeverSilent.
  ///
  /// In en, this message translates to:
  /// **'You are never uncontactable. At zero credits alerts still arrive — quietly, without the alarm or the reminders.'**
  String get plansPromiseNeverSilent;

  /// No description provided for @plansPromisePrivate.
  ///
  /// In en, this message translates to:
  /// **'Whoever scans your sticker is told nothing about your plan, and still never learns who you are.'**
  String get plansPromisePrivate;

  /// No description provided for @plansFreeOverline.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get plansFreeOverline;

  /// No description provided for @plansAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade attention for alerts'**
  String get plansAdTitle;

  /// No description provided for @plansAdBody.
  ///
  /// In en, this message translates to:
  /// **'Watch {ads} short ads, get {credits} more full-strength alerts. Each one is banked the moment it finishes — stop whenever you like.'**
  String plansAdBody(int ads, int credits);

  /// No description provided for @plansAdProgress.
  ///
  /// In en, this message translates to:
  /// **'{watched} of {total} watched this sitting'**
  String plansAdProgress(int watched, int total);

  /// No description provided for @plansAdCapped.
  ///
  /// In en, this message translates to:
  /// **'You\'re holding the maximum of {count} earned credits.'**
  String plansAdCapped(int count);

  /// No description provided for @plansAdCta.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad'**
  String get plansAdCta;

  /// No description provided for @plansPaidOverline.
  ///
  /// In en, this message translates to:
  /// **'AVAHANAA PLUS'**
  String get plansPaidOverline;

  /// No description provided for @plansPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Take the meter off'**
  String get plansPaidTitle;

  /// No description provided for @plansChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change your plan'**
  String get plansChangeTitle;

  /// No description provided for @plansRecommended.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get plansRecommended;

  /// No description provided for @plansCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get plansCurrent;

  /// No description provided for @plansSaving.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}% against weekly'**
  String plansSaving(int percent);

  /// No description provided for @planWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get planWeekly;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Billed every week'**
  String get planPerWeek;

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Billed every month'**
  String get planPerMonth;

  /// No description provided for @planPerYear.
  ///
  /// In en, this message translates to:
  /// **'Billed every year'**
  String get planPerYear;

  /// No description provided for @planUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get planUnlimited;

  /// No description provided for @planActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Avahanaa Plus is active'**
  String get planActiveTitle;

  /// No description provided for @planActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Unlimited full-strength alerts on every vehicle you own.'**
  String get planActiveBody;

  /// No description provided for @planRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String planRenewsOn(String date);

  /// No description provided for @planActivated.
  ///
  /// In en, this message translates to:
  /// **'Avahanaa Plus is active. Alerts are unlimited.'**
  String get planActivated;

  /// No description provided for @planPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Play could not complete that purchase.'**
  String get planPurchaseFailed;

  /// No description provided for @planRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a previous purchase'**
  String get planRestore;

  /// No description provided for @planLegalNote.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically until cancelled. Manage or cancel any time in Google Play. Prices include taxes.'**
  String get planLegalNote;

  /// No description provided for @settingsPlan.
  ///
  /// In en, this message translates to:
  /// **'Alert credits & plan'**
  String get settingsPlan;

  /// No description provided for @reasonTest.
  ///
  /// In en, this message translates to:
  /// **'Test alert'**
  String get reasonTest;

  /// No description provided for @guidanceTest.
  ///
  /// In en, this message translates to:
  /// **'You asked for this one. A real alert arrives exactly like it.'**
  String get guidanceTest;

  /// No description provided for @selfTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test the alarm'**
  String get selfTestTitle;

  /// No description provided for @selfTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send yourself a real alert'**
  String get selfTestSubtitle;

  /// No description provided for @selfTestSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get selfTestSending;

  /// No description provided for @selfTestSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Lock your phone — it should go off within seconds.'**
  String get selfTestSent;

  /// No description provided for @selfTestSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Send yourself a real alert'**
  String get selfTestSheetTitle;

  /// No description provided for @selfTestSheetBody.
  ///
  /// In en, this message translates to:
  /// **'This walks the whole path a stranger\'s scan would: the same alarm, the same lock screen takeover, the same reminders. It costs no credits.\n\nIf nothing arrives, your phone is blocking Avahanaa in the background — the alerts screen will tell you how to fix it.'**
  String get selfTestSheetBody;

  /// No description provided for @selfTestSheetCta.
  ///
  /// In en, this message translates to:
  /// **'Send the test alert'**
  String get selfTestSheetCta;

  /// No description provided for @selfTestLockHint.
  ///
  /// In en, this message translates to:
  /// **'Lock your phone now, so you see what an alert really looks like.'**
  String get selfTestLockHint;

  /// No description provided for @alertsWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where your vehicle is'**
  String get alertsWhereTitle;

  /// No description provided for @alertsWhereApprox.
  ///
  /// In en, this message translates to:
  /// **'Approximate — tap to open in Maps'**
  String get alertsWhereApprox;

  /// No description provided for @alertsWhereAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accurate to about {metres} m — tap to open in Maps'**
  String alertsWhereAccuracy(int metres);

  /// No description provided for @alertsOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get alertsOpenInMaps;

  /// No description provided for @alertsNoMapApp.
  ///
  /// In en, this message translates to:
  /// **'No map app could open that location.'**
  String get alertsNoMapApp;

  /// No description provided for @alertsWhereOverline.
  ///
  /// In en, this message translates to:
  /// **'WHERE'**
  String get alertsWhereOverline;

  /// No description provided for @readinessPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts can\'t reach this phone'**
  String get readinessPermissionTitle;

  /// No description provided for @readinessPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are switched off for Avahanaa in your phone\'s settings. Nothing will arrive until they\'re back on — not even an emergency.'**
  String get readinessPermissionBody;

  /// No description provided for @readinessPreferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve paused your own alerts'**
  String get readinessPreferenceTitle;

  /// No description provided for @readinessPreferenceBody.
  ///
  /// In en, this message translates to:
  /// **'Alerts are turned off in Avahanaa\'s settings. Your QR code still works, but nothing will reach you.'**
  String get readinessPreferenceBody;

  /// No description provided for @readinessTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'This phone isn\'t registered yet'**
  String get readinessTokenTitle;

  /// No description provided for @readinessTokenBody.
  ///
  /// In en, this message translates to:
  /// **'Avahanaa hasn\'t been able to register this device for alerts. Reopening the app usually fixes it.'**
  String get readinessTokenBody;

  /// No description provided for @readinessFullScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts won\'t take over the lock screen'**
  String get readinessFullScreenTitle;

  /// No description provided for @readinessFullScreenBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll still arrive and still make a noise — they just won\'t fill the screen when your phone is locked.'**
  String get readinessFullScreenBody;

  /// No description provided for @readinessGrantCta.
  ///
  /// In en, this message translates to:
  /// **'Turn alerts on'**
  String get readinessGrantCta;

  /// No description provided for @readinessPreferenceCta.
  ///
  /// In en, this message translates to:
  /// **'Open alert settings'**
  String get readinessPreferenceCta;

  /// No description provided for @readinessTokenCta.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get readinessTokenCta;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'kn':
      return AppL10nKn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
