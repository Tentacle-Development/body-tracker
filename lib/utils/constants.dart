class AppConstants {
  // App Info
  static const String appName = 'Body Tracker';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'body_tracker.db';
  static const int dbVersion = 2;

  // Photo Categories
  static const List<String> photoCategories = ['front', 'side', 'back'];

  // Measurement Types
  static const List<String> measurementTypes = [
    'height',
    'weight',
    'chest',
    'waist',
    'hips',
    'neck',
    'shoulders',
    'biceps',
    'forearm',
    'thigh',
    'calf',
  ];

  // Measurement Units
  static const Map<String, List<String>> units = {
    'height': ['cm', 'ft/in'],
    'weight': ['kg', 'lbs'],
    'chest': ['cm', 'in'],
    'waist': ['cm', 'in'],
    'hips': ['cm', 'in'],
    'neck': ['cm', 'in'],
    'shoulders': ['cm', 'in'],
    'biceps': ['cm', 'in'],
    'forearm': ['cm', 'in'],
    'thigh': ['cm', 'in'],
    'calf': ['cm', 'in'],
  };

  // Default Reminder Intervals (in days)
  static const List<int> reminderIntervals = [7, 14, 30, 60, 90];

  // Gender Options
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];

  // Clothing Size Regions
  static const List<String> sizeRegions = ['EU', 'US', 'UK', 'Asian'];
}
