import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_tracker/providers/app_provider.dart';
import 'package:body_tracker/services/database_service.dart';
import 'package:body_tracker/services/goal_service.dart';
import 'package:body_tracker/services/photo_service.dart';
import 'package:body_tracker/services/notification_service.dart';
import 'package:body_tracker/models/user_settings.dart';
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

    DatabaseService.instance = mockDatabaseService;
    GoalService.instance = mockGoalService;
    PhotoService.instance = mockPhotoService;
    NotificationService.instance = mockNotificationService;

    when(mockDatabaseService.database).thenAnswer((_) async => mockDatabase);
    when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
        .thenAnswer((_) async => 1);
    
    // Mock user query to return a user so provider initializes fully
    when(mockDatabase.query('users')).thenAnswer((_) async => [
      {'id': 1, 'name': 'User', 'gender': 'male', 'date_of_birth': '1990-01-01', 'created_at': '2026-01-01', 'updated_at': '2026-01-01'}
    ]);
    
    when(mockDatabase.query('settings', where: anyNamed('where'), whereArgs: anyNamed('whereArgs'))).thenAnswer((_) async => [
      {'id': 1, 'user_id': 1, 'enabled_tabs': 'dashboard,measure,photos', 'created_at': '2026-01-01', 'updated_at': '2026-01-01'}
    ]);

    when(mockDatabase.query('measurements', where: anyNamed('where'), whereArgs: anyNamed('whereArgs'), orderBy: anyNamed('orderBy'))).thenAnswer((_) async => []);
    when(mockGoalService.getGoals(any)).thenAnswer((_) async => []);
    when(mockPhotoService.getPhotos(any)).thenAnswer((_) async => []);

    SharedPreferences.setMockInitialValues({});
    appProvider = AppProvider();
    await appProvider.initialize();
  });

  test('updateSettings should update activeTabId if current tab is removed', () async {
    // Set active tab to 'measure'
    appProvider.setActiveTab('measure');
    expect(appProvider.activeTabId, 'measure');

    // Update settings to remove 'measure'
    final newSettings = appProvider.settings!.copyWith(
      enabledTabs: ['dashboard', 'photos'],
    );

    await appProvider.updateSettings(newSettings);

    // Verify activeTabId is reset to first available tab
    // Fails currently because logic is missing in provider
    expect(appProvider.activeTabId, 'dashboard');
    expect(appProvider.settings!.enabledTabs, ['dashboard', 'photos']);
  });
}
