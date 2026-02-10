import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_tracker/providers/app_provider.dart';
import 'package:body_tracker/services/database_service.dart';
import 'package:body_tracker/services/goal_service.dart';
import 'package:body_tracker/services/photo_service.dart';
import 'package:body_tracker/services/notification_service.dart';
import 'package:body_tracker/models/measurement.dart';
import 'mocks.mocks.dart';

void main() {
  late MockDatabase mockDatabase;
  late MockDatabaseService mockDatabaseService;
  late MockGoalService mockGoalService;
  late MockPhotoService mockPhotoService;
  late MockNotificationService mockNotificationService;
  late AppProvider appProvider;

  setUp(() async {
    mockDatabase = MockDatabase();
    mockDatabaseService = MockDatabaseService();
    mockGoalService = MockGoalService();
    mockPhotoService = MockPhotoService();
    mockNotificationService = MockNotificationService();

    // Inject mock services
    DatabaseService.instance = mockDatabaseService;
    GoalService.instance = mockGoalService;
    PhotoService.instance = mockPhotoService;
    NotificationService.instance = mockNotificationService;

    when(mockDatabaseService.database).thenAnswer((_) async => mockDatabase);
    
    // Stub insert for settings and other tables
    when(mockDatabase.insert(any, any,
            nullColumnHack: anyNamed('nullColumnHack'),
            conflictAlgorithm: anyNamed('conflictAlgorithm')))
        .thenAnswer((_) async => 1);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    appProvider = AppProvider();
  });

  group('AppProvider Calculation Tests', () {
    test('calculateBMI returns correct value for metric units', () async {
      // Mock database response for initial users and measurements
      when(mockDatabase.query('users')).thenAnswer((_) async => [
        {
          'id': 1,
          'name': 'Test User',
          'gender': 'male',
          'date_of_birth': '1990-01-01',
          'created_at': '2026-01-01',
          'updated_at': '2026-01-01',
        }
      ]);
      
      when(mockDatabase.query(
        'measurements',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
      )).thenAnswer((_) async => [
        {
          'id': 1,
          'user_id': 1,
          'type': 'height',
          'value': 180.0,
          'unit': 'cm',
          'measured_at': '2026-01-01',
          'created_at': '2026-01-01',
        },
        {
          'id': 2,
          'user_id': 1,
          'type': 'weight',
          'value': 81.0,
          'unit': 'kg',
          'measured_at': '2026-01-01',
          'created_at': '2026-01-01',
        }
      ]);

      when(mockDatabase.query(
        'settings',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => []); // Return empty for default settings

      when(mockGoalService.getGoals(any)).thenAnswer((_) async => []);
      when(mockPhotoService.getPhotos(any)).thenAnswer((_) async => []);

      await appProvider.initialize();

      final bmi = appProvider.calculateBMI();
      // BMI = 81 / (1.8 * 1.8) = 25.0
      expect(bmi, closeTo(25.0, 0.1));
    });

    test('calculateWaistToHipRatio returns correct value', () async {
      // Setup similar to above but with waist and hips
       when(mockDatabase.query('users')).thenAnswer((_) async => [
        {'id': 1, 'name': 'User', 'gender': 'male', 'date_of_birth': '1990-01-01', 'created_at': '2026-01-01', 'updated_at': '2026-01-01'}
      ]);
      
      when(mockDatabase.query(
        'measurements',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
      )).thenAnswer((_) async => [
        {'id': 1, 'user_id': 1, 'type': 'waist', 'value': 80.0, 'unit': 'cm', 'measured_at': '2026-01-01', 'created_at': '2026-01-01'},
        {'id': 2, 'user_id': 1, 'type': 'hips', 'value': 100.0, 'unit': 'cm', 'measured_at': '2026-01-01', 'created_at': '2026-01-01'}
      ]);
      
      when(mockDatabase.query('settings', where: anyNamed('where'), whereArgs: anyNamed('whereArgs'))).thenAnswer((_) async => []);
      when(mockGoalService.getGoals(any)).thenAnswer((_) async => []);
      when(mockPhotoService.getPhotos(any)).thenAnswer((_) async => []);

      await appProvider.initialize();

      final ratio = appProvider.calculateWaistToHipRatio();
      expect(ratio, 0.8);
    });
  });
}
