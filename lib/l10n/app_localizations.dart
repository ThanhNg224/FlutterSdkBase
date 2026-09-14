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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('vi')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Flutter SDK Base'**
  String get appName;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Core Feature Catalog'**
  String get catalogTitle;

  /// No description provided for @catalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore integrated architectural modules, state management, and Clean Architecture in this starter base.'**
  String get catalogSubtitle;

  /// No description provided for @exploreSdkFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore SDK Features'**
  String get exploreSdkFeaturesTitle;

  /// No description provided for @exploreSdkFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an integrated module below to configure parameters and trigger live SDK verification.'**
  String get exploreSdkFeaturesSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @postsFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts & Feed Showcase'**
  String get postsFeedTitle;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No articles found'**
  String get noPostsFound;

  /// No description provided for @createFirstPostButton.
  ///
  /// In en, this message translates to:
  /// **'Create First Post'**
  String get createFirstPostButton;

  /// No description provided for @newPostButton.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPostButton;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePostTitle;

  /// No description provided for @deletePostConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deletePostConfirmation(String title);

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @postDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post #{id}'**
  String postDetailTitle(int id);

  /// No description provided for @authorIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Author ID #{id}'**
  String authorIdLabel(int id);

  /// No description provided for @publishedArticleLabel.
  ///
  /// In en, this message translates to:
  /// **'Published article'**
  String get publishedArticleLabel;

  /// No description provided for @postSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post #{id} · Author #{userId}'**
  String postSubtitle(int id, int userId);

  /// No description provided for @createPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Post'**
  String get createPostTitle;

  /// No description provided for @postTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get postTitleFieldLabel;

  /// No description provided for @postTitleFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Enter post title'**
  String get postTitleFieldHint;

  /// No description provided for @titleRequiredValidation.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequiredValidation;

  /// No description provided for @postBodyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get postBodyFieldLabel;

  /// No description provided for @postBodyFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Enter post body content...'**
  String get postBodyFieldHint;

  /// No description provided for @contentRequiredValidation.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequiredValidation;

  /// No description provided for @publishPostButton.
  ///
  /// In en, this message translates to:
  /// **'Publish Post'**
  String get publishPostButton;

  /// No description provided for @postCreatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully!'**
  String get postCreatedSuccessMessage;

  /// No description provided for @developerSdkSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer & App Settings'**
  String get developerSdkSettingsTitle;

  /// No description provided for @sdkEnvironmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Environment Configuration'**
  String get sdkEnvironmentTitle;

  /// No description provided for @useDevServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Use Development Server'**
  String get useDevServerLabel;

  /// No description provided for @connectedDevEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Connected to Dev Environment'**
  String get connectedDevEnvironment;

  /// No description provided for @connectedProdEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Connected to Production Environment'**
  String get connectedProdEnvironment;

  /// No description provided for @activeBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Base URL:'**
  String get activeBaseUrlLabel;

  /// No description provided for @mockSdkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mock API Mode'**
  String get mockSdkModeLabel;

  /// No description provided for @mockSdkModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulate network responses without external dependencies'**
  String get mockSdkModeDescription;

  /// No description provided for @credentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials & Overrides'**
  String get credentialsTitle;

  /// No description provided for @credentialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Overrides the built-in sandbox credentials for this device only. Leave untouched to keep the defaults.'**
  String get credentialsDescription;

  /// No description provided for @appTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'App Token'**
  String get appTokenLabel;

  /// No description provided for @clientKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Client Key'**
  String get clientKeyLabel;

  /// No description provided for @credentialsActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Currently: {value}'**
  String credentialsActiveHint(String value);

  /// No description provided for @resetCredentialsButton.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetCredentialsButton;

  /// No description provided for @credentialsResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Credential overrides cleared'**
  String get credentialsResetMessage;

  /// No description provided for @saveCredentialsButton.
  ///
  /// In en, this message translates to:
  /// **'Save credentials'**
  String get saveCredentialsButton;

  /// No description provided for @credentialsSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Credentials updated'**
  String get credentialsSavedMessage;

  /// No description provided for @appearanceThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get appearanceThemeTitle;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeLabel;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @sdkVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Base App Version:'**
  String get sdkVersionLabel;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your device\'s internet connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete this request. Please try again in a moment.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The server rejected these credentials. Check the app token and client key under Settings.'**
  String get errorUnauthorized;

  /// No description provided for @errorPlatform.
  ///
  /// In en, this message translates to:
  /// **'The native SDK could not finish the operation on this device.'**
  String get errorPlatform;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'Could not read the app\'s local settings.'**
  String get errorStorage;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmail;

  /// No description provided for @validationMinLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {count} characters.'**
  String validationMinLength(int count);

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Check your connection.'**
  String get offlineBannerMessage;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @somethingWentWrongMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrongMessage;

  /// No description provided for @pageNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {uri}'**
  String pageNotFoundMessage(String uri);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

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
