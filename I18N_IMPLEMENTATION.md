# Internationalization (i18n) Implementation

This document describes the internationalization setup for the Body Tracker app, supporting English (EN) and German (DE) locales.

## Setup Overview

The app uses Flutter's official localization system with ARB (Application Resource Bundle) files for translations.

### Files Modified/Created

1. **pubspec.yaml** - Added dependencies and enabled code generation
2. **l10n.yaml** - Configuration for localization generation
3. **lib/l10n/app_en.arb** - English translations
4. **lib/l10n/app_de.arb** - German translations
5. **lib/main.dart** - Updated to support localizations
6. **lib/screens/home/home_screen.dart** - Example usage of translations
7. **lib/l10n/TRANSLATION_EXAMPLES.dart** - Code examples for developers

## Configuration Details

### 1. pubspec.yaml Changes

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # ... other dependencies

flutter:
  uses-material-design: true
  generate: true  # Enable code generation
```

**Note:** Updated `intl` from `^0.19.0` to `^0.20.2` to match the version required by `flutter_localizations`.

### 2. l10n.yaml Configuration

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

This tells Flutter where to find ARB files and what to name the generated file.

### 3. ARB Files Structure

**app_en.arb** (English - Template)
- Contains all translation keys with their English values
- Includes metadata (`@key` entries) with descriptions
- Defines placeholders for parameterized translations

**app_de.arb** (German)
- Contains German translations for all keys
- Does not need metadata (inherited from template)

Example structure:
```json
{
  "@@locale": "en",
  "appTitle": "Body Tracker",
  "@appTitle": {
    "description": "The title of the application"
  },
  "yearsOld": "{age} years old",
  "@yearsOld": {
    "description": "User age display",
    "placeholders": {
      "age": {
        "type": "int",
        "example": "25"
      }
    }
  }
}
```

### 4. main.dart Integration

Added imports:
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

Added to MaterialApp:
```dart
MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'), // English
    Locale('de'), // German
  ],
  // ... rest of config
)
```

## Usage in Code

### Basic Usage

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In your build method:
final l10n = AppLocalizations.of(context)!;

Text(l10n.dashboard)  // Shows "Dashboard" or "Dashboard" (DE)
Text(l10n.measurements)  // Shows "Measurements" or "Messungen" (DE)
```

### Parameterized Translations

```dart
final l10n = AppLocalizations.of(context)!;

// With integer parameter
Text(l10n.yearsOld(25))  // "25 years old" or "25 Jahre alt"

// With string parameter
Text(l10n.deleteCategoryConfirm('Weight'))
// "Are you sure you want to delete "Weight"?..." or German equivalent
```

### Checking Current Locale

```dart
final locale = Localizations.localeOf(context);
print('Current locale: ${locale.languageCode}'); // 'en' or 'de'
```

## Translation Keys Added

### Navigation & Tabs
- `appTitle` - Application title
- `dashboard` - Dashboard tab
- `measure` - Measure tab
- `photos` - Photos tab
- `progress` - Progress tab
- `sizes` - Sizes tab
- `profile` - Profile tab

### Screen Titles
- `measurements` - Measurements screen
- `settings` - Settings section
- `extraFeatures` - Extra features section

### Actions & Buttons
- `newMeasurement` - New measurement button
- `cancel` - Cancel button
- `delete` - Delete button
- `deleteCategory` - Delete category dialog title
- `deleteCategoryConfirm` - Delete confirmation message (parameterized)

### Settings Items
- `navigation` - Navigation settings
- `customizeBottomBar` - Navigation subtitle
- `reminders` - Reminders settings
- `setupNotifications` - Reminders subtitle
- `goals` - Goals settings
- `trackTargets` - Goals subtitle
- `backupAndRestore` - Backup settings
- `dataManagement` - Backup subtitle

### Descriptions
- `overview` - Dashboard subtitle
- `newEntries` - Measure subtitle
- `gallery` - Photos subtitle
- `charts` - Progress subtitle
- `clothingGuide` - Sizes subtitle

### Health Metrics
- `bmi` - BMI label
- `waistHip` - Waist to hip ratio
- `noData` - No data available
- `underweight`, `normal`, `overweight`, `obese` - BMI categories
- `lowRisk`, `moderateRisk`, `highRisk` - Health risk levels

### User Info
- `yearsOld` - Age display (parameterized with `{age}`)

## Examples in home_screen.dart

The `home_screen.dart` file demonstrates various translation use cases:

1. **Tab labels** - Bottom navigation items use localized strings
2. **Screen titles** - Dashboard, Measurements, Profile titles are translated
3. **Buttons** - "New Measurement" button uses translation
4. **Settings items** - All settings rows use localized titles and subtitles
5. **Dialogs** - Delete confirmation dialog is fully localized
6. **Dynamic text** - BMI/WHR categories use translated strings
7. **Parameterized text** - User age display uses `yearsOld(age)`

## How Locale is Determined

Flutter automatically determines the locale based on:
1. Device system language
2. Fallback to first supported locale if device language not supported
3. Falls back to English if no match

## Adding New Translations

1. **Add to app_en.arb** (template):
   ```json
   "myNewKey": "My English Text",
   "@myNewKey": {
     "description": "Description for translators"
   }
   ```

2. **Add to app_de.arb**:
   ```json
   "myNewKey": "Mein deutscher Text"
   ```

3. **Run code generation**:
   ```bash
   flutter gen-l10n
   # or
   flutter pub get  # This also triggers generation
   ```

4. **Use in code**:
   ```dart
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.myNewKey)
   ```

## Adding a New Language

1. Create `lib/l10n/app_XX.arb` (where XX is the language code)
2. Copy all keys from `app_en.arb`
3. Translate the values
4. Add to `supportedLocales` in `main.dart`:
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('de'),
     Locale('XX'),  // Your new language
   ],
   ```

## Generated Files

After running `flutter gen-l10n`, these files are auto-generated in `.dart_tool/flutter_gen/gen_l10n/`:
- `app_localizations.dart` - Main localizations class
- `app_localizations_en.dart` - English implementation
- `app_localizations_de.dart` - German implementation

**Never edit these files manually!** They are regenerated on each build.

## Testing Different Locales

### Method 1: Change Device Language
Set your device/emulator to German (DE) to see German translations.

### Method 2: Force Locale in Code (for testing)
```dart
MaterialApp(
  locale: const Locale('de'), // Force German
  localizationsDelegates: ...,
  supportedLocales: ...,
)
```

### Method 3: Use Flutter DevTools
Use the locale selector in Flutter DevTools to switch locales at runtime.

## Best Practices

1. **Always provide context descriptions** in the template ARB file
2. **Use meaningful key names** that describe the content
3. **Group related keys** with prefixes (e.g., `settings_`, `dialog_`)
4. **Keep translations short** for UI elements like buttons and tabs
5. **Test with both locales** to ensure UI doesn't break with longer German text
6. **Use placeholders** for dynamic content instead of string concatenation
7. **Avoid hardcoded strings** - always use localization keys

## Common Issues & Solutions

### Issue: "AppLocalizations.of(context) returns null"
**Solution:** Ensure `MaterialApp` has `localizationsDelegates` and `supportedLocales` configured.

### Issue: "The getter 'myKey' isn't defined"
**Solution:** Run `flutter pub get` or `flutter gen-l10n` to regenerate localization files.

### Issue: "intl version conflict"
**Solution:** Use `intl: ^0.20.2` to match flutter_localizations requirements.

### Issue: "Locale not changing"
**Solution:** Hot reload may not work. Try hot restart or rebuild the app.

## Resources

- [Official Flutter Internationalization Guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle)
- [Intl Package Documentation](https://pub.dev/packages/intl)

## Summary

The Body Tracker app now fully supports English and German localization:
- ✅ Configuration files in place (`pubspec.yaml`, `l10n.yaml`)
- ✅ ARB files created with comprehensive translations
- ✅ Main app configured for localization
- ✅ Example implementations in `home_screen.dart`
- ✅ Developer examples in `TRANSLATION_EXAMPLES.dart`
- ✅ Documentation complete

The app will automatically display in German for German-speaking users and English for others.
