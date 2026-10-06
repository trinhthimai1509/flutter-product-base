import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('vi'),
  ];

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get commonEmpty;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested item could not be found.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some information is invalid. Please check and try again.'**
  String get errorValidation;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server had a problem. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'Could not access device storage.'**
  String get errorStorage;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnknown;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authSignInSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInButton;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String authPasswordTooShort(int min);

  /// No description provided for @authDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: any email and a password of 6+ characters works.'**
  String get authDemoHint;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get authSignOutConfirmTitle;

  /// No description provided for @authSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to continue.'**
  String get authSignOutConfirmMessage;

  /// No description provided for @authGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get authGuestName;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This base app demonstrates reusable foundation modules.'**
  String get homeSubtitle;

  /// No description provided for @homeChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat demo'**
  String get homeChatTitle;

  /// No description provided for @homeChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generic chat engine with a mock provider'**
  String get homeChatSubtitle;

  /// No description provided for @homeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTitle;

  /// No description provided for @homeSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, language and app info'**
  String get homeSettingsSubtitle;

  /// No description provided for @homeShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Foundation showcase'**
  String get homeShowcaseTitle;

  /// No description provided for @homeShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Design system components and states'**
  String get homeShowcaseSubtitle;

  /// No description provided for @homeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfileTitle;

  /// No description provided for @homeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current user and session'**
  String get homeProfileSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAppName.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get settingsAppName;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get settingsEnvironment;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get profileUserId;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileNoEmail;

  /// No description provided for @profileGuestBadge.
  ///
  /// In en, this message translates to:
  /// **'Guest session'**
  String get profileGuestBadge;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatTitle;

  /// No description provided for @chatEmptyConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatEmptyConversations;

  /// No description provided for @chatEmptyMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get chatEmptyMessages;

  /// No description provided for @chatComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatComposerHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get chatAttach;

  /// No description provided for @chatStop.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get chatStop;

  /// No description provided for @chatRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get chatRegenerate;

  /// No description provided for @chatFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Tap to retry.'**
  String get chatFailed;

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get chatCancelReply;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String chatTyping(String name);

  /// No description provided for @chatSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get chatSources;

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: include \"/fail\" in a message to simulate a failed send.'**
  String get chatDemoHint;

  /// No description provided for @chatUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get chatUploading;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get notFoundMessage;

  /// No description provided for @notFoundGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get notFoundGoHome;

  /// No description provided for @showcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Foundation showcase'**
  String get showcaseTitle;

  /// No description provided for @showcaseButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get showcaseButtons;

  /// No description provided for @showcasePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get showcasePrimary;

  /// No description provided for @showcaseSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get showcaseSecondary;

  /// No description provided for @showcaseTextButton.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get showcaseTextButton;

  /// No description provided for @showcaseInputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get showcaseInputs;

  /// No description provided for @showcaseSampleInput.
  ///
  /// In en, this message translates to:
  /// **'Sample input'**
  String get showcaseSampleInput;

  /// No description provided for @showcaseStates.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get showcaseStates;

  /// No description provided for @showcaseFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get showcaseFeedback;

  /// No description provided for @showcaseShowDialog.
  ///
  /// In en, this message translates to:
  /// **'Show dialog'**
  String get showcaseShowDialog;

  /// No description provided for @showcaseDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a reusable confirmation dialog.'**
  String get showcaseDialogMessage;

  /// No description provided for @showcaseShowSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Show snackbar'**
  String get showcaseShowSnackbar;

  /// No description provided for @showcaseSnackbarMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a reusable snackbar.'**
  String get showcaseSnackbarMessage;

  /// No description provided for @showcaseSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send in-app notification'**
  String get showcaseSendNotification;

  /// No description provided for @showcaseNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello from the notification center'**
  String get showcaseNotificationTitle;

  /// No description provided for @showcaseNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications are delivered through a replaceable service.'**
  String get showcaseNotificationBody;

  /// No description provided for @showcaseAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get showcaseAttachments;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
