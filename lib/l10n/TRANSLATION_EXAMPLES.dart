// Example: How to Use Translations in Screens
// ==============================================
//
// This file demonstrates how to use the generated localization strings
// throughout the Body Tracker app.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// EXAMPLE 1: Basic Usage in a Widget
// ------------------------------------
class ExampleTranslatedWidget extends StatelessWidget {
  const ExampleTranslatedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle), // "Body Tracker" or "Körper-Tracker"
      ),
      body: Column(
        children: [
          Text(l10n.dashboard),
          Text(l10n.measurements),
          Text(l10n.photos),
          Text(l10n.progress),
        ],
      ),
    );
  }
}

// EXAMPLE 2: Using Parameterized Translations
// --------------------------------------------
class ExampleParameterizedWidget extends StatelessWidget {
  final int userAge;
  
  const ExampleParameterizedWidget({
    super.key,
    required this.userAge,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      children: [
        // Using a parameterized translation
        Text(l10n.yearsOld(userAge)), // "25 years old" or "25 Jahre alt"
        
        // Another example with a named parameter
        Text(l10n.deleteCategoryConfirm('Weight')),
      ],
    );
  }
}

// EXAMPLE 3: Using in Dialog Boxes
// ---------------------------------
void showExampleDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteCategory),
      content: Text(l10n.deleteCategoryConfirm('Weight')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            // Delete logic here
            Navigator.pop(context);
          },
          child: Text(
            l10n.delete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

// EXAMPLE 4: Using in Lists and Navigation
// -----------------------------------------
class ExampleNavigationList extends StatelessWidget {
  const ExampleNavigationList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: Text(l10n.dashboard),
          subtitle: Text(l10n.overview),
        ),
        ListTile(
          leading: const Icon(Icons.straighten),
          title: Text(l10n.measure),
          subtitle: Text(l10n.newEntries),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: Text(l10n.photos),
          subtitle: Text(l10n.gallery),
        ),
      ],
    );
  }
}

// EXAMPLE 5: Conditional Text Based on Data
// ------------------------------------------
class ExampleConditionalText extends StatelessWidget {
  final double? bmi;
  
  const ExampleConditionalText({
    super.key,
    this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    String getBMICategory() {
      if (bmi == null) return l10n.noData;
      if (bmi! < 18.5) return l10n.underweight;
      if (bmi! < 25) return l10n.normal;
      if (bmi! < 30) return l10n.overweight;
      return l10n.obese;
    }
    
    return Column(
      children: [
        Text(l10n.bmi),
        Text(getBMICategory()),
      ],
    );
  }
}

// EXAMPLE 6: Using in Bottom Navigation
// --------------------------------------
class ExampleBottomNav extends StatelessWidget {
  const ExampleBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: l10n.dashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.straighten),
          label: l10n.measure,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.photo_camera),
          label: l10n.photos,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.show_chart),
          label: l10n.progress,
        ),
      ],
    );
  }
}

// HOW TO ACCESS CURRENT LOCALE
// -----------------------------
// You can access the current locale like this:
void printCurrentLocale(BuildContext context) {
  final locale = Localizations.localeOf(context);
  print('Current locale: ${locale.languageCode}'); // 'en' or 'de'
}

// TESTING WITH SPECIFIC LOCALE
// -----------------------------
// To test a specific locale in your app, you can use:
class TestLocaleWidget extends StatelessWidget {
  const TestLocaleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('de'), // Force German locale for testing
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ExampleTranslatedWidget(),
    );
  }
}
