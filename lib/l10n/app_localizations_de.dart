// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Körper-Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get measure => 'Messen';

  @override
  String get photos => 'Fotos';

  @override
  String get progress => 'Fortschritt';

  @override
  String get sizes => 'Größen';

  @override
  String get profile => 'Profil';

  @override
  String get measurements => 'Messungen';

  @override
  String get newMeasurement => 'Neue Messung';

  @override
  String get settings => 'Einstellungen';

  @override
  String get navigation => 'Navigation';

  @override
  String get customizeBottomBar => 'Untere Leiste anpassen';

  @override
  String get reminders => 'Erinnerungen';

  @override
  String get setupNotifications => 'Benachrichtigungen einrichten';

  @override
  String get goals => 'Ziele';

  @override
  String get trackTargets => 'Ziele verfolgen';

  @override
  String get backupAndRestore => 'Sichern & Wiederherstellen';

  @override
  String get dataManagement => 'Datenverwaltung';

  @override
  String get extraFeatures => 'Zusätzliche Funktionen';

  @override
  String get overview => 'Übersicht';

  @override
  String get newEntries => 'Neue Einträge';

  @override
  String get gallery => 'Galerie';

  @override
  String get charts => 'Diagramme';

  @override
  String get clothingGuide => 'Kleidergrößen-Leitfaden';

  @override
  String yearsOld(int age) {
    return '$age Jahre alt';
  }

  @override
  String get deleteCategory => 'Kategorie löschen';

  @override
  String deleteCategoryConfirm(String title) {
    return 'Möchten Sie \"$title\" wirklich löschen? Dies löscht auch den gesamten Verlauf für diese Kategorie.';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get bmi => 'BMI';

  @override
  String get waistHip => 'Taille/Hüfte';

  @override
  String get noData => 'Keine Daten';

  @override
  String get underweight => 'Untergewicht';

  @override
  String get normal => 'Normal';

  @override
  String get overweight => 'Übergewicht';

  @override
  String get obese => 'Fettleibig';

  @override
  String get lowRisk => 'Niedriges Risiko';

  @override
  String get moderateRisk => 'Mittleres Risiko';

  @override
  String get highRisk => 'Hohes Risiko';
}
