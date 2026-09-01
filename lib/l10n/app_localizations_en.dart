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

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authSignInBlurb => 'Sign in to stay reachable.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authCreateAnAccount => 'Create an account';

  @override
  String get authCreateYourAccount => 'Create your account';

  @override
  String get authYourAccount => 'Your account';

  @override
  String get authYourVehicle => 'Your vehicle';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authPhoneOptional => 'Phone number (optional)';

  @override
  String get authRegistrationNumber => 'Registration number';

  @override
  String get authMakeAndModel => 'Make and model';

  @override
  String get authColour => 'Colour';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String get legalTermsOfService => 'Terms of Service';

  @override
  String get authResetYourPassword => 'Reset your password';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authCheckYourEmail => 'Check your email';

  @override
  String get authUseDifferentEmail => 'Use a different email';

  @override
  String get authResendEmail => 'Resend the email';

  @override
  String get legalTitle => 'Legal & Privacy';

  @override
  String get legalShortVersion => 'The short version';

  @override
  String get legalShortBody =>
      'Avahanaa never reveals your phone number, email or name to whoever scans your sticker.';

  @override
  String get legalPrivacySubtitle =>
      'What we collect, why, and how long we keep it';

  @override
  String get legalTermsSubtitle => 'The rules for using Avahanaa';

  @override
  String get legalCouldNotOpen => 'Could not open the link right now.';

  @override
  String get qrScanToAlertMe => 'SCAN TO ALERT ME';

  @override
  String get qrYourWindshieldCode => 'Your windshield code';

  @override
  String get qrPaused => 'PAUSED';

  @override
  String get qrSemanticLabel => 'QR code for your vehicle';

  @override
  String get vehicleReachable => 'Reachable — your number stays hidden';

  @override
  String get vehiclePaused => 'Paused — scans are not reaching you';

  @override
  String get vehicleYourVehicle => 'Your vehicle';

  @override
  String vehicleCountOf(int index, int count) {
    return 'Vehicle $index of $count';
  }

  @override
  String vehicleShowNumber(int index) {
    return 'Show vehicle $index';
  }

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homeVehicleReachable => 'Your vehicle is reachable';

  @override
  String get homeQrPaused => 'Your QR code is paused';

  @override
  String get homeAddFirstVehicle => 'Add your first vehicle';

  @override
  String get homeAddVehicleBody =>
      'Avahanaa needs a vehicle before it can create the code for your windshield.';

  @override
  String get homeGoToProfile => 'Go to Profile';

  @override
  String get homeCreatingQr => 'Creating your QR code';

  @override
  String get homeCreatingQrBody => 'This usually takes a few seconds.';

  @override
  String get homeSettingUpVehicle => 'Setting up your vehicle';

  @override
  String get homeSettingUpBody => 'Moving your details over. One moment.';

  @override
  String get homeAccountMissing => 'Account details missing';

  @override
  String get homeAccountMissingBody =>
      'We could not load your profile. Sign out and back in to fix it.';

  @override
  String get homeCannotReach => 'Cannot reach your account';

  @override
  String get homeCannotReachBody =>
      'Check your connection — your QR code keeps working for anyone who scans it, this screen just cannot refresh.';

  @override
  String get homePrint => 'Print';

  @override
  String get homeCopyLink => 'Copy link';

  @override
  String get homeDesign => 'Design';

  @override
  String get homeScanLinkCopied => 'Scan link copied';

  @override
  String get homePrinterFailed =>
      'Could not open the printer. Try Design to save the sheet instead.';

  @override
  String get homePreparing => 'Preparing…';

  @override
  String get homeUnreadAlert => 'Unread alert';

  @override
  String get homeUnreadAlerts => 'Unread alerts';

  @override
  String get homeVehicle => 'Vehicle';

  @override
  String get homeVehicles => 'Vehicles';

  @override
  String get homeProtection => 'Protection';

  @override
  String get homeGettingSetUp => 'Getting set up';

  @override
  String get homeHowItWorks => 'How it works';

  @override
  String get homeStepPrint => 'Print the sticker';

  @override
  String get homeStepPrintBody =>
      'Share or save it, then print on plain white paper.';

  @override
  String get homeStepStick => 'Put it on your windshield';

  @override
  String get homeStepStickBody =>
      'Inside the glass, driver-side corner, facing out.';

  @override
  String get homeStepAlert => 'Get alerted in seconds';

  @override
  String get homeStepAlertBody => 'A scan rings your phone, even on silent.';

  @override
  String get homeNumberStaysYours => 'Your number stays yours';

  @override
  String get homeNumberStaysYoursBody =>
      'Whoever scans your code can tell you something is wrong — and that is all. They never see your phone number, your email, or your name.';

  @override
  String get navHome => 'Home';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get studioTitle => 'Sticker studio';

  @override
  String get studioChooseALook => 'Choose a look';

  @override
  String get studioStickerDesign => 'Sticker design';

  @override
  String get studioPutItOnPaper => 'Put it on paper';

  @override
  String get studioPrintASheet => 'Print a sheet';

  @override
  String get studioPaper => 'Paper';

  @override
  String get studioPerSheet => 'Per sheet';

  @override
  String get studioPrintThisSheet => 'Print this sheet';

  @override
  String get studioSendPdf => 'Send PDF to a print shop';

  @override
  String get studioOrSendPicture => 'Or send it as a picture';

  @override
  String get studioShareTheImage => 'Share the image';

  @override
  String get studioShareOrSave => 'Share or save image';

  @override
  String get studioCopyScanLink => 'Copy scan link';

  @override
  String get studioMakeItLast => 'Make it last';

  @override
  String get studioGettingItPrinted => 'Getting it printed';

  @override
  String get studioAnyoneCanScan => 'Anyone can scan it';

  @override
  String get studioAnyoneCanScanBody =>
      'No app required — a phone camera or Google Lens is enough. Keep the white border around the code clean and the sticker flat.';

  @override
  String get studioLaminate => 'Laminate it';

  @override
  String get studioLaminateBody =>
      'A clear sleeve works too. Bangalore sun fades ink fast.';

  @override
  String get studioFixInside => 'Fix it inside the windshield';

  @override
  String get studioFixInsideBody =>
      'Driver-side corner, code facing out, nothing covering it.';

  @override
  String get studioCutAtMarks => 'Cut at the corner marks';

  @override
  String get studioCutAtMarksBody =>
      'They sit outside the sticker, so nothing gets clipped.';

  @override
  String get studioPrintFullSize => 'Print at 100%';

  @override
  String get studioPrintFullSizeBody =>
      'Turn off \"fit to page\" or \"shrink to fit\". The sheet is already sized.';

  @override
  String get studioPaperTooSmall => 'This paper is too small for a sticker.';

  @override
  String get studioStickerTooSmall =>
      'This small a sticker is hard to scan from outside the car. Fewer per sheet, or bigger paper, reads better through glass.';

  @override
  String get studioPdfFailed => 'Could not create the PDF.';

  @override
  String get studioImageFailed => 'Could not create the sticker image.';

  @override
  String get studioPrinterFailed =>
      'Could not reach a printer. Try sending the PDF instead.';

  @override
  String get studioShareSubject => 'My Avahanaa QR sticker';

  @override
  String get studioShareText =>
      'Scan this Avahanaa code to reach me about my vehicle.';

  @override
  String get studioShareImage => 'Share sticker image';

  @override
  String get studioScanLinkCopied => 'Scan link copied';

  @override
  String get studioPreparing => 'Preparing…';

  @override
  String studioPreviewOf(String style, String plate) {
    return 'Preview of your $style sticker for $plate';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileYourGarage => 'Your garage';

  @override
  String get profileYourVehicles => 'Your vehicles';

  @override
  String get profileAdd => 'Add';

  @override
  String get profileAddVehicle => 'Add a vehicle';

  @override
  String get profileEditVehicle => 'Edit vehicle';

  @override
  String get profileNoVehicles => 'No vehicles yet';

  @override
  String get profileNoVehiclesBody =>
      'Add a vehicle and Avahanaa creates its QR sticker automatically.';

  @override
  String get profileNoDetails => 'No details added yet';

  @override
  String get profileQrActive => 'QR ACTIVE';

  @override
  String get profileQrPaused => 'QR PAUSED';

  @override
  String get profilePrimary => 'PRIMARY';

  @override
  String get profileMakePrimary => 'MAKE PRIMARY';

  @override
  String get profileAlertsToday => 'Alerts today';

  @override
  String get profileAlertsAllTime => 'Alerts all time';

  @override
  String get profileProtectionOn => 'Protection is on';

  @override
  String get profileProtectionOff => 'Protection is off';

  @override
  String get profileProtectionOnBody => 'Scans reach you on every vehicle';

  @override
  String get profileProtectionOffBody =>
      'Anyone scanning your sticker will see that you cannot be reached';

  @override
  String get profileProtectionFailed => 'Could not update protection';

  @override
  String get profilePhoneNumber => 'Phone number';

  @override
  String get profilePhoneNotSet => 'Not set — only used for account recovery';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileCurrentPassword => 'Current password';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileConfirmNewPassword => 'Confirm new password';

  @override
  String get profilePasswordUpdated => 'Password updated';

  @override
  String get profilePhoneUpdated => 'Phone number updated';

  @override
  String get profilePrimaryUpdated => 'Primary vehicle updated';

  @override
  String get profileLegalPrivacy => 'Legal & privacy';

  @override
  String get profileLegalSubtitle => 'Privacy policy and terms of service';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteAccountQ => 'Delete account?';

  @override
  String get profileDeleteAccountBody =>
      'Permanently removes your QR codes and alerts';

  @override
  String get profileDeleteForever => 'Delete forever';

  @override
  String get profileDeleteVehicleQ => 'Delete vehicle?';

  @override
  String get profileDelete => 'Delete';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSave => 'Save';

  @override
  String get profileEnterPassword => 'Enter your password to confirm';

  @override
  String get profileEnterRegistration => 'Enter your registration number';

  @override
  String get profileColourModelHint =>
      'Colour and model help whoever finds your vehicle confirm they are alerting the right person.';

  @override
  String get profileQrAutoCreated => 'Its QR sticker is created automatically.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageOverline => 'LANGUAGE';

  @override
  String get profileLanguageTitle => 'What Avahanaa speaks';

  @override
  String profileVehiclesCount(int count) {
    return '$count vehicles';
  }

  @override
  String profileSinceDate(String date) {
    return 'Since $date';
  }

  @override
  String get errUnexpected => 'An unexpected error occurred. Please try again.';

  @override
  String get errCreateProfile =>
      'Failed to create user profile. Please try again.';

  @override
  String get errSignOut => 'Failed to sign out. Please try again.';

  @override
  String get errResetEmail =>
      'Failed to send password reset email. Please try again.';

  @override
  String get errNoUser => 'No user is currently signed in.';

  @override
  String get errVerifyEmail =>
      'Failed to send verification email. Please try again.';

  @override
  String get errRefreshUser => 'Failed to refresh user. Please try again.';

  @override
  String get errUpdateEmail => 'Failed to update email. Please try again.';

  @override
  String get errUpdatePassword =>
      'Failed to update password. Please try again.';

  @override
  String get errDeleteAccount => 'Failed to delete account. Please try again.';

  @override
  String get errWeakPassword =>
      'The password is too weak. Please use at least 6 characters.';

  @override
  String get errEmailInUse => 'An account already exists with this email.';

  @override
  String get errInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errUserNotFound => 'No account found with this email.';

  @override
  String get errWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get errUserDisabled => 'This account has been disabled.';

  @override
  String get errTooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String get errNotAllowed => 'This operation is not allowed.';

  @override
  String get errNeedsRecentLogin =>
      'Please sign in again to complete this action.';

  @override
  String get errSaveVehicle => 'Failed to save vehicle';

  @override
  String get errDeleteVehicle => 'Failed to delete vehicle';

  @override
  String get errSetPrimary => 'Failed to set primary vehicle';

  @override
  String get errQrStatus => 'Failed to update QR code status';

  @override
  String get errUpdateProfile => 'Failed to update profile';

  @override
  String get errDeleteNotification => 'Failed to delete alert';

  @override
  String get errMarkRead => 'Failed to mark alerts as read';

  @override
  String get errClearNotifications => 'Failed to clear alerts';

  @override
  String get valEnterRegistration => 'Please enter your registration number';

  @override
  String get valInvalidRegistration =>
      'Please enter a valid registration number';

  @override
  String get valEnterEmail => 'Enter your email address';

  @override
  String get valInvalidEmail => 'That does not look like an email address';

  @override
  String get valEnterPassword => 'Enter your password';

  @override
  String get valPasswordLength => 'Use at least 6 characters';

  @override
  String get valPasswordsDiffer => 'The passwords do not match';

  @override
  String get valEnterColour => 'Enter your vehicle colour';

  @override
  String get valEnterModel => 'Enter your vehicle model';

  @override
  String get valInvalidPhone => 'That does not look like a valid number';

  @override
  String get alertsOptions => 'Alert options';

  @override
  String get alertsMarkAllRead => 'Mark all as read';

  @override
  String get alertsClearAll => 'Clear all';

  @override
  String get alertsClearAllQ => 'Clear all alerts?';

  @override
  String get alertsClearAllBody =>
      'Every alert will be deleted from this device and your account. This cannot be undone.';

  @override
  String get alertsCleared => 'All alerts cleared';

  @override
  String get alertsDeleted => 'Alert deleted';

  @override
  String get alertsNothingToMark => 'Nothing left to mark';

  @override
  String get alertsNoLongerAvailable => 'That alert is no longer available.';

  @override
  String get alertsLoadFailed => 'Could not load your alerts';

  @override
  String get alertsLoadFailedBody =>
      'Check your connection and try again. New alerts will still ring your phone.';

  @override
  String get alertsEmptyTitle => 'Nothing to worry about';

  @override
  String get alertsEmptyBody =>
      'No one has needed to reach you about your vehicle. When someone scans your code, the alert lands here.';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonUpdating => 'Updating…';

  @override
  String get commonLive => 'LIVE';

  @override
  String get commonPaused => 'PAUSED';

  @override
  String get styleSignature => 'Signature';

  @override
  String get styleSignatureDesc => 'Branded header on white paper';

  @override
  String get styleBold => 'Bold';

  @override
  String get styleBoldDesc =>
      'High-visibility colour panel — uses a lot of ink';

  @override
  String get styleMinimal => 'Minimal';

  @override
  String get styleMinimalDesc => 'Black and white — best for scanning';

  @override
  String get styleMidnight => 'Midnight';

  @override
  String get styleMidnightDesc => 'Deep graphite panel with a white code card';

  @override
  String get styleEmber => 'Ember';

  @override
  String get styleEmberDesc => 'Warm rust header — easiest to spot at dusk';

  @override
  String get styleEmerald => 'Emerald';

  @override
  String get styleEmeraldDesc => 'Calm green header on white paper';

  @override
  String get styleIndigo => 'Indigo';

  @override
  String get styleIndigoDesc => 'Indigo panel — uses a lot of ink';

  @override
  String get styleIvory => 'Ivory';

  @override
  String get styleIvoryDesc => 'Warm cream paper with espresso ink';

  @override
  String get sizeShare => 'Share';

  @override
  String get sizeShareDesc => 'Good for WhatsApp and email';

  @override
  String get sizePrint => 'Print';

  @override
  String get sizePrintDesc => 'A5 at 300dpi — take this to a print shop';

  @override
  String get paperA4Desc => 'The default sheet at any print shop';

  @override
  String get paperA5Desc => 'Half of A4 — one sticker fills it';

  @override
  String get paperA6Desc => 'Postcard size — a small windscreen tile';

  @override
  String get paperLetterDesc => 'US office paper';

  @override
  String get profileVehicleCountOne => '1 VEHICLE';

  @override
  String get creditsTitle => 'Alert credits';

  @override
  String creditsRemaining(int count) {
    return '$count full-strength alerts left';
  }

  @override
  String creditsRemainingShort(int count) {
    return '$count alerts left';
  }

  @override
  String get creditsEmptyShort => 'Out of alerts';

  @override
  String get creditsEmptyTitle => 'You\'re out of alert credits';

  @override
  String get creditsEmptyBody =>
      'Alerts still reach you — quietly, without the alarm.';

  @override
  String creditsBreakdown(int free, int earned, int days) {
    return '$free free (resets in $days days) · $earned earned';
  }

  @override
  String get creditsEmergencyAlwaysFree =>
      'Emergencies always ring at full volume, credits or not.';

  @override
  String creditsWatchAd(int count) {
    return 'Watch $count ads';
  }

  @override
  String get creditsGoUnlimited => 'Go unlimited';

  @override
  String get creditsEarnedOne => 'Credit added';

  @override
  String get creditsAdUnavailable =>
      'No ad is available right now. Try again in a minute.';

  @override
  String get creditsAdDismissed => 'Watch the whole ad to earn a credit.';

  @override
  String get plansTitle => 'Never miss the one that matters';

  @override
  String plansSubtitle(int count) {
    return '$count full-strength alerts a month are free, forever. Top up with ads, or take the meter off entirely.';
  }

  @override
  String get plansPromiseEmergency =>
      'Emergencies are never metered. A fire, a crash or an injury rings your phone at full volume whatever your balance says.';

  @override
  String get plansPromiseNeverSilent =>
      'You are never uncontactable. At zero credits alerts still arrive — quietly, without the alarm or the reminders.';

  @override
  String get plansPromisePrivate =>
      'Whoever scans your sticker is told nothing about your plan, and still never learns who you are.';

  @override
  String get plansFreeOverline => 'FREE';

  @override
  String get plansAdTitle => 'Trade attention for alerts';

  @override
  String plansAdBody(int ads, int credits) {
    return 'Watch $ads short ads, get $credits more full-strength alerts. Each one is banked the moment it finishes — stop whenever you like.';
  }

  @override
  String plansAdProgress(int watched, int total) {
    return '$watched of $total watched this sitting';
  }

  @override
  String plansAdCapped(int count) {
    return 'You\'re holding the maximum of $count earned credits.';
  }

  @override
  String get plansAdCta => 'Watch an ad';

  @override
  String get plansPaidOverline => 'AVAHANAA PLUS';

  @override
  String get plansPaidTitle => 'Take the meter off';

  @override
  String get plansChangeTitle => 'Change your plan';

  @override
  String get plansRecommended => 'POPULAR';

  @override
  String get plansCurrent => 'CURRENT';

  @override
  String plansSaving(int percent) {
    return 'Save $percent% against weekly';
  }

  @override
  String get planWeekly => 'Weekly';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planFree => 'Free';

  @override
  String get planPerWeek => 'Billed every week';

  @override
  String get planPerMonth => 'Billed every month';

  @override
  String get planPerYear => 'Billed every year';

  @override
  String get planUnlimited => 'Unlimited';

  @override
  String get planActiveTitle => 'Avahanaa Plus is active';

  @override
  String get planActiveBody =>
      'Unlimited full-strength alerts on every vehicle you own.';

  @override
  String planRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get planActivated => 'Avahanaa Plus is active. Alerts are unlimited.';

  @override
  String get planPurchaseFailed =>
      'Google Play could not complete that purchase.';

  @override
  String get planRestore => 'Restore a previous purchase';

  @override
  String get planLegalNote =>
      'Subscriptions renew automatically until cancelled. Manage or cancel any time in Google Play. Prices include taxes.';

  @override
  String get settingsPlan => 'Alert credits & plan';

  @override
  String get reasonTest => 'Test alert';

  @override
  String get guidanceTest =>
      'You asked for this one. A real alert arrives exactly like it.';

  @override
  String get selfTestTitle => 'Test the alarm';

  @override
  String get selfTestSubtitle => 'Send yourself a real alert';

  @override
  String get selfTestSending => 'Sending…';

  @override
  String get selfTestSent =>
      'Sent. Lock your phone — it should go off within seconds.';

  @override
  String get selfTestSheetTitle => 'Send yourself a real alert';

  @override
  String get selfTestSheetBody =>
      'This walks the whole path a stranger\'s scan would: the same alarm, the same lock screen takeover, the same reminders. It costs no credits.\n\nIf nothing arrives, your phone is blocking Avahanaa in the background — the alerts screen will tell you how to fix it.';

  @override
  String get selfTestSheetCta => 'Send the test alert';

  @override
  String get selfTestLockHint =>
      'Lock your phone now, so you see what an alert really looks like.';

  @override
  String get alertsWhereTitle => 'Where your vehicle is';

  @override
  String get alertsWhereApprox => 'Approximate — tap to open in Maps';

  @override
  String alertsWhereAccuracy(int metres) {
    return 'Accurate to about $metres m — tap to open in Maps';
  }

  @override
  String get alertsOpenInMaps => 'Open in Maps';

  @override
  String get alertsNoMapApp => 'No map app could open that location.';

  @override
  String get alertsWhereOverline => 'WHERE';

  @override
  String get readinessPermissionTitle => 'Alerts can\'t reach this phone';

  @override
  String get readinessPermissionBody =>
      'Notifications are switched off for Avahanaa in your phone\'s settings. Nothing will arrive until they\'re back on — not even an emergency.';

  @override
  String get readinessPreferenceTitle => 'You\'ve paused your own alerts';

  @override
  String get readinessPreferenceBody =>
      'Alerts are turned off in Avahanaa\'s settings. Your QR code still works, but nothing will reach you.';

  @override
  String get readinessTokenTitle => 'This phone isn\'t registered yet';

  @override
  String get readinessTokenBody =>
      'Avahanaa hasn\'t been able to register this device for alerts. Reopening the app usually fixes it.';

  @override
  String get readinessFullScreenTitle =>
      'Alerts won\'t take over the lock screen';

  @override
  String get readinessFullScreenBody =>
      'They\'ll still arrive and still make a noise — they just won\'t fill the screen when your phone is locked.';

  @override
  String get readinessGrantCta => 'Turn alerts on';

  @override
  String get readinessPreferenceCta => 'Open alert settings';

  @override
  String get readinessTokenCta => 'Try again';

  @override
  String get creditsEarnedPending =>
      'Ad complete. Your credit will appear shortly.';
}
