import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Body Tracker'**
  String get appTitle;

  /// Dashboard tab label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Measure tab label
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measure;

  /// Photos tab label
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// Progress tab label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Sizes tab label
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get sizes;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Measurements screen title
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// New measurement button label
  ///
  /// In en, this message translates to:
  /// **'New Measurement'**
  String get newMeasurement;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Navigation settings title
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// Navigation settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Customize bottom bar'**
  String get customizeBottomBar;

  /// Reminders settings title
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Reminders settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Setup notifications'**
  String get setupNotifications;

  /// Goals settings title
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// Goals settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Track targets'**
  String get trackTargets;

  /// Backup settings title
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// Backup settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get dataManagement;

  /// Extra features section title
  ///
  /// In en, this message translates to:
  /// **'Extra Features'**
  String get extraFeatures;

  /// Dashboard subtitle
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// Measure subtitle
  ///
  /// In en, this message translates to:
  /// **'New entries'**
  String get newEntries;

  /// Photos subtitle
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Progress subtitle
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// Sizes subtitle
  ///
  /// In en, this message translates to:
  /// **'Clothing guide'**
  String get clothingGuide;

  /// User age display
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOld(int age);

  /// Delete category dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// Delete category confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This will also delete all history for this category.'**
  String deleteCategoryConfirm(String title);

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// BMI label
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// Waist to hip ratio label
  ///
  /// In en, this message translates to:
  /// **'Waist/Hip'**
  String get waistHip;

  /// No data available
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// BMI category: underweight
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get underweight;

  /// BMI category: normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// BMI category: overweight
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get overweight;

  /// BMI category: obese
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get obese;

  /// Health risk: low
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get lowRisk;

  /// Health risk: moderate
  ///
  /// In en, this message translates to:
  /// **'Moderate risk'**
  String get moderateRisk;

  /// Health risk: high
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get highRisk;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
