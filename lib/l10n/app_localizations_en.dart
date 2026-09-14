// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flutter SDK Base';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get catalogTitle => 'Core Feature Catalog';

  @override
  String get catalogSubtitle =>
      'Explore integrated architectural modules, state management, and Clean Architecture in this starter base.';

  @override
  String get exploreSdkFeaturesTitle => 'Explore SDK Features';

  @override
  String get exploreSdkFeaturesSubtitle =>
      'Select an integrated module below to configure parameters and trigger live SDK verification.';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get postsFeedTitle => 'Posts & Feed Showcase';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get noPostsFound => 'No articles found';

  @override
  String get createFirstPostButton => 'Create First Post';

  @override
  String get newPostButton => 'New Post';

  @override
  String get deletePostTitle => 'Delete Post';

  @override
  String deletePostConfirmation(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String postDetailTitle(int id) {
    return 'Post #$id';
  }

  @override
  String authorIdLabel(int id) {
    return 'Author ID #$id';
  }

  @override
  String get publishedArticleLabel => 'Published article';

  @override
  String postSubtitle(int id, int userId) {
    return 'Post #$id · Author #$userId';
  }

  @override
  String get createPostTitle => 'Create New Post';

  @override
  String get postTitleFieldLabel => 'Title';

  @override
  String get postTitleFieldHint => 'Enter post title';

  @override
  String get titleRequiredValidation => 'Title is required';

  @override
  String get postBodyFieldLabel => 'Content';

  @override
  String get postBodyFieldHint => 'Enter post body content...';

  @override
  String get contentRequiredValidation => 'Content is required';

  @override
  String get publishPostButton => 'Publish Post';

  @override
  String get postCreatedSuccessMessage => 'Post created successfully!';

  @override
  String get developerSdkSettingsTitle => 'Developer & App Settings';

  @override
  String get sdkEnvironmentTitle => 'Environment Configuration';

  @override
  String get useDevServerLabel => 'Use Development Server';

  @override
  String get connectedDevEnvironment => 'Connected to Dev Environment';

  @override
  String get connectedProdEnvironment => 'Connected to Production Environment';

  @override
  String get activeBaseUrlLabel => 'Active Base URL:';

  @override
  String get mockSdkModeLabel => 'Mock API Mode';

  @override
  String get mockSdkModeDescription => 'Simulate network responses without external dependencies';

  @override
  String get credentialsTitle => 'Credentials & Overrides';

  @override
  String get credentialsDescription =>
      'Overrides the built-in sandbox credentials for this device only. Leave untouched to keep the defaults.';

  @override
  String get appTokenLabel => 'App Token';

  @override
  String get clientKeyLabel => 'Client Key';

  @override
  String credentialsActiveHint(String value) {
    return 'Currently: $value';
  }

  @override
  String get resetCredentialsButton => 'Reset to defaults';

  @override
  String get credentialsResetMessage => 'Credential overrides cleared';

  @override
  String get saveCredentialsButton => 'Save credentials';

  @override
  String get credentialsSavedMessage => 'Credentials updated';

  @override
  String get appearanceThemeTitle => 'Appearance & Theme';

  @override
  String get themeModeLabel => 'Theme Mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get aboutTitle => 'About';

  @override
  String get sdkVersionLabel => 'Base App Version:';

  @override
  String get errorNetwork => 'Could not reach the server. Check your device\'s internet connection and try again.';

  @override
  String get errorServer => 'The server could not complete this request. Please try again in a moment.';

  @override
  String get errorUnauthorized =>
      'The server rejected these credentials. Check the app token and client key under Settings.';

  @override
  String get errorPlatform => 'The native SDK could not finish the operation on this device.';

  @override
  String get errorStorage => 'Could not read the app\'s local settings.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationEmail => 'Enter a valid email address.';

  @override
  String validationMinLength(int count) {
    return 'Enter at least $count characters.';
  }

  @override
  String get offlineBannerMessage => 'You are offline. Check your connection.';

  @override
  String get closeButton => 'Close';

  @override
  String get retryButton => 'Retry';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get somethingWentWrongMessage => 'Something went wrong';

  @override
  String pageNotFoundMessage(String uri) {
    return 'Page not found: $uri';
  }
}
