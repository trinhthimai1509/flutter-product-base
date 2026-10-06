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
}
