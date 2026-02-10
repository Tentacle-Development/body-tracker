import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:body_tracker/main.dart';
import 'package:body_tracker/providers/app_provider.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';
import 'package:body_tracker/services/database_service.dart';
import 'package:body_tracker/services/goal_service.dart';
import 'package:body_tracker/services/photo_service.dart';
import 'package:body_tracker/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App splash screen shows title', (WidgetTester tester) async {
    // Setup mocks
    final mockDatabase = MockDatabase();
    final mockDatabaseService = MockDatabaseService();
    final mockGoalService = MockGoalService();
    final mockPhotoService = MockPhotoService();
    final mockNotificationService = MockNotificationService();

    DatabaseService.instance = mockDatabaseService;
    GoalService.instance = mockGoalService;
    PhotoService.instance = mockPhotoService;
    NotificationService.instance = mockNotificationService;

    when(mockDatabaseService.database).thenAnswer((_) async => mockDatabase);
    when(mockDatabase.query(any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy')))
        .thenAnswer((_) async => []);
    
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that Splash Screen is shown with the app title
    expect(find.text('Body Tracker'), findsOneWidget);
    expect(find.text('Track your progress'), findsOneWidget);
  });
}
