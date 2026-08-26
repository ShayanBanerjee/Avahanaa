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
