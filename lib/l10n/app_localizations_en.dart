// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Body Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get measure => 'Measure';

  @override
  String get photos => 'Photos';

  @override
  String get progress => 'Progress';

  @override
  String get sizes => 'Sizes';

  @override
  String get profile => 'Profile';

  @override
  String get measurements => 'Measurements';

  @override
  String get newMeasurement => 'New Measurement';

  @override
  String get settings => 'Settings';

  @override
  String get navigation => 'Navigation';

  @override
  String get customizeBottomBar => 'Customize bottom bar';

  @override
  String get reminders => 'Reminders';

  @override
  String get setupNotifications => 'Setup notifications';

  @override
  String get goals => 'Goals';

  @override
  String get trackTargets => 'Track targets';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get dataManagement => 'Data management';

  @override
  String get extraFeatures => 'Extra Features';

  @override
  String get overview => 'Overview';

  @override
  String get newEntries => 'New entries';

  @override
  String get gallery => 'Gallery';

  @override
  String get charts => 'Charts';

  @override
  String get clothingGuide => 'Clothing guide';

  @override
  String yearsOld(int age) {
    return '$age years old';
  }

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String deleteCategoryConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This will also delete all history for this category.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get bmi => 'BMI';

  @override
  String get waistHip => 'Waist/Hip';

  @override
  String get noData => 'No data';

  @override
  String get underweight => 'Underweight';

  @override
  String get normal => 'Normal';

  @override
  String get overweight => 'Overweight';

  @override
  String get obese => 'Obese';

  @override
  String get lowRisk => 'Low risk';

  @override
  String get moderateRisk => 'Moderate risk';

  @override
  String get highRisk => 'High risk';
}
