import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:body_tracker/services/database_service.dart';
import 'package:body_tracker/services/goal_service.dart';
import 'package:body_tracker/models/goal.dart';
import 'mocks.mocks.dart';

void main() {
  late MockDatabase mockDatabase;
  late MockDatabaseService mockDatabaseService;
  late GoalService goalService;

  setUp(() {
    mockDatabase = MockDatabase();
    mockDatabaseService = MockDatabaseService();
    
    // Inject mock DatabaseService
    DatabaseService.instance = mockDatabaseService;
    
    // Setup DatabaseService to return mock Database
    when(mockDatabaseService.database).thenAnswer((_) async => mockDatabase);
    
    goalService = GoalService();
  });

  group('GoalService Tests', () {
    test('getGoals returns list of goals from database', () async {
      final mockMaps = [
        {
          'id': 1,
          'user_id': 1,
          'type': 'weight',
          'start_value': 80.0,
          'target_value': 75.0,
          'start_date': '2026-01-01T00:00:00.000',
          'target_date': '2026-02-01T00:00:00.000',
          'is_completed': 0,
          'created_at': '2026-01-01T00:00:00.000',
        }
      ];

      when(mockDatabase.query(
        'goals',
        where: 'user_id = ?',
        whereArgs: [1],
        orderBy: 'target_date ASC',
      )).thenAnswer((_) async => mockMaps);

      final goals = await goalService.getGoals(1);

      expect(goals.length, 1);
      expect(goals.first.id, 1);
      expect(goals.first.type, 'weight');
      expect(goals.first.targetValue, 75.0);
    });

    test('addGoal inserts goal and returns goal with id', () async {
      final goal = Goal(
        userId: 1,
        type: 'waist',
        startValue: 90.0,
        targetValue: 85.0,
        startDate: DateTime(2026, 1, 1),
        targetDate: DateTime(2026, 2, 1),
      );

      when(mockDatabase.insert('goals', any)).thenAnswer((_) async => 42);

      final savedGoal = await goalService.addGoal(goal);

      expect(savedGoal.id, 42);
      expect(savedGoal.type, 'waist');
      verify(mockDatabase.insert('goals', any)).called(1);
    });

    test('updateGoal updates goal in database', () async {
      final goal = Goal(
        id: 1,
        userId: 1,
        type: 'weight',
        startValue: 80.0,
        targetValue: 75.0,
        startDate: DateTime(2026, 1, 1),
        targetDate: DateTime(2026, 2, 1),
      );

      when(mockDatabase.update(
        'goals',
        any,
        where: 'id = ?',
        whereArgs: [1],
      )).thenAnswer((_) async => 1);

      await goalService.updateGoal(goal);

      verify(mockDatabase.update(
        'goals',
        any,
        where: 'id = ?',
        whereArgs: [1],
      )).called(1);
    });

    test('deleteGoal deletes goal from database', () async {
      when(mockDatabase.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [1],
      )).thenAnswer((_) async => 1);

      await goalService.deleteGoal(1);

      verify(mockDatabase.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [1],
      )).called(1);
    });
  });
}
