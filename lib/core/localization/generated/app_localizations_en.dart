// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonEmpty => 'Nothing here yet';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get errorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do this.';

  @override
  String get errorNotFound => 'The requested item could not be found.';

  @override
  String get errorValidation =>
      'Some information is invalid. Please check and try again.';

  @override
  String get errorServer => 'The server had a problem. Please try again later.';

  @override
  String get errorStorage => 'Could not access device storage.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get authSignInTitle => 'Welcome';

  @override
  String get authSignInSubtitle => 'Sign in to continue';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String authPasswordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get authDemoHint =>
      'Demo mode: any email and a password of 6+ characters works.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSignOutConfirmTitle => 'Sign out?';

  @override
  String get authSignOutConfirmMessage =>
      'You will need to sign in again to continue.';

  @override
  String get authGuestName => 'Guest';

  @override
  String get homeTitle => 'Home';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeSubtitle =>
      'This base app demonstrates reusable foundation modules.';

  @override
  String get homeChatTitle => 'Chat demo';

  @override
  String get homeChatSubtitle => 'Generic chat engine with a mock provider';

  @override
  String get homeSettingsTitle => 'Settings';

  @override
  String get homeSettingsSubtitle => 'Theme, language and app info';

  @override
  String get homeShowcaseTitle => 'Foundation showcase';

  @override
  String get homeShowcaseSubtitle => 'Design system components and states';

  @override
  String get homeProfileTitle => 'Profile';

  @override
  String get homeProfileSubtitle => 'Current user and session';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppName => 'App name';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsEnvironment => 'Environment';

  @override
  String get settingsAccount => 'Account';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUserId => 'User ID';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileNoEmail => 'Not provided';

  @override
  String get profileGuestBadge => 'Guest session';

  @override
  String get chatTitle => 'Conversations';

  @override
  String get chatEmptyConversations => 'No conversations yet';

  @override
  String get chatEmptyMessages => 'No messages yet. Say hello!';

  @override
  String get chatComposerHint => 'Type a message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAttach => 'Attach file';

  @override
  String get chatStop => 'Stop generating';

  @override
  String get chatRegenerate => 'Regenerate';

  @override
  String get chatFailed => 'Not sent. Tap to retry.';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatReply => 'Reply';

  @override
  String get chatCancelReply => 'Cancel reply';

  @override
  String chatTyping(String name) {
    return '$name is typing…';
  }

  @override
  String get chatSources => 'Sources';

  @override
  String get chatYou => 'You';

  @override
  String get chatDemoHint =>
      'Tip: include \"/fail\" in a message to simulate a failed send.';

  @override
  String get chatUploading => 'Uploading…';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'The page you are looking for does not exist.';

  @override
  String get notFoundGoHome => 'Go to home';

  @override
  String get showcaseTitle => 'Foundation showcase';

  @override
  String get showcaseButtons => 'Buttons';

  @override
  String get showcasePrimary => 'Primary';

  @override
  String get showcaseSecondary => 'Secondary';

  @override
  String get showcaseTextButton => 'Text';

  @override
  String get showcaseInputs => 'Inputs';

  @override
  String get showcaseSampleInput => 'Sample input';

  @override
  String get showcaseStates => 'States';

  @override
  String get showcaseFeedback => 'Feedback';

  @override
  String get showcaseShowDialog => 'Show dialog';

  @override
  String get showcaseDialogMessage => 'This is a reusable confirmation dialog.';

  @override
  String get showcaseShowSnackbar => 'Show snackbar';

  @override
  String get showcaseSnackbarMessage => 'This is a reusable snackbar.';

  @override
  String get showcaseSendNotification => 'Send in-app notification';

  @override
  String get showcaseNotificationTitle => 'Hello from the notification center';

  @override
  String get showcaseNotificationBody =>
      'In-app notifications are delivered through a replaceable service.';

  @override
  String get showcaseAttachments => 'Attachments';

  @override
  String get offlineBanner => 'You\'re offline. Some features may not work.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Get started';

  @override
  String onboardingPageIndicator(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get onboardingPage1Title => 'A foundation, not a product';

  @override
  String get onboardingPage1Body =>
      'Auth, networking, chat, settings and more, ready to build on.';

  @override
  String get onboardingPage2Title => 'Pick what you need';

  @override
  String get onboardingPage2Body =>
      'Ads, billing, notifications and telemetry are opt-in packages.';

  @override
  String get onboardingPage3Title => 'Runs offline';

  @override
  String get onboardingPage3Body =>
      'Fakes stand in for every backend and store until yours are ready.';

  @override
  String get premiumTitle => 'Pro';

  @override
  String get premiumHeadline => 'Go Pro';

  @override
  String get premiumSubtitle => 'One purchase, yours forever.';

  @override
  String get premiumBenefitNoAds => 'No ads';

  @override
  String get premiumBenefitFeatures => 'Every premium feature';

  @override
  String get premiumBenefitSupport => 'Support future development';

  @override
  String get premiumFootnote => 'One-time purchase. No subscription.';

  @override
  String premiumBuy(String price) {
    return 'Get Pro for $price';
  }

  @override
  String get premiumUnavailable => 'Not available right now';

  @override
  String get premiumRestore => 'Restore purchase';

  @override
  String get premiumOwned => 'You have Pro. Thank you!';

  @override
  String get premiumPending =>
      'Payment pending. Pro unlocks when it completes.';

  @override
  String get premiumMsgCompleted => 'Welcome to Pro!';

  @override
  String get premiumMsgPending => 'Payment pending.';

  @override
  String get premiumMsgAlreadyOwned => 'You already own Pro.';

  @override
  String get premiumMsgRestored => 'Purchase restored.';

  @override
  String get premiumMsgNothingToRestore => 'No previous purchase found.';

  @override
  String get premiumMsgCouldNotCheck => 'Couldn\'t reach the store. Try again.';

  @override
  String get premiumMsgFailed => 'Purchase failed. You were not charged.';

  @override
  String get settingsDynamicColor => 'Dynamic color';

  @override
  String get settingsDynamicColorSubtitle => 'Use colors from your wallpaper';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Reminders and updates';

  @override
  String get settingsNotificationsDenied =>
      'Notifications are blocked. Allow them in system settings.';

  @override
  String get settingsPremium => 'Get Pro';

  @override
  String get settingsPremiumSubtitle => 'Remove ads and unlock everything';

  @override
  String get settingsPremiumActive => 'Pro is active';

  @override
  String get settingsPrivacyOptions => 'Privacy options';

  @override
  String get settingsRateApp => 'Rate this app';

  @override
  String get settingsShareApp => 'Share this app';

  @override
  String settingsShareMessage(String appName) {
    return 'I\'m using $appName.';
  }

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsReplayOnboarding => 'Replay introduction';

  @override
  String get settingsLinkFailed => 'Couldn\'t open the link.';

  @override
  String get homeCapabilitiesTitle => 'Capabilities';

  @override
  String get homeCapabilitiesSubtitle =>
      'Ads, billing, notifications, review, telemetry';

  @override
  String get notificationChannelReminders => 'Reminders';

  @override
  String get notificationChannelRemindersDescription =>
      'Reminders you schedule in the app';

  @override
  String get notificationDemoTitle => 'Hello from Flutter Base';

  @override
  String get notificationDemoBody => 'Tap to open the capabilities demo.';

  @override
  String get capConnectivity => 'Connectivity';

  @override
  String get capOnline => 'Online';

  @override
  String get capOffline => 'Offline';

  @override
  String get capTelemetry => 'Telemetry';

  @override
  String capTelemetryBackend(String name) {
    return 'Backend: $name';
  }

  @override
  String get capLogEvent => 'Log a test event';

  @override
  String get capEventLogged => 'Event logged.';

  @override
  String capPermissionStatus(String status) {
    return 'Permission: $status';
  }

  @override
  String get capPermissionGranted => 'granted';

  @override
  String get capPermissionNotGranted => 'not granted';

  @override
  String get capRequestPermission => 'Request permission';

  @override
  String get capShowNow => 'Show now';

  @override
  String get capScheduleReminder => 'Remind me in 10 seconds';

  @override
  String get capReminderScheduled => 'Reminder scheduled.';

  @override
  String get capReview => 'In-app review';

  @override
  String get capRequestReview => 'Request a review';

  @override
  String get capReviewUnavailable => 'Review is not available here.';

  @override
  String get capAds => 'Ads';

  @override
  String capAdsStatus(String available) {
    return 'Ads available: $available';
  }

  @override
  String get capShowInterstitial => 'Show interstitial';

  @override
  String get capShowRewarded => 'Show rewarded';

  @override
  String get capRecordAction => 'Record qualifying action';

  @override
  String capAdResult(String result) {
    return 'Result: $result';
  }

  @override
  String capPremiumStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get capOpenPaywall => 'Open paywall';

  @override
  String get capResetPurchase => 'Reset demo purchase';

  @override
  String get capOnboarding => 'Onboarding';

  @override
  String get commonYes => 'yes';

  @override
  String get commonNo => 'no';
}
