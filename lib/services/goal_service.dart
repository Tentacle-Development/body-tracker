import '../models/goal.dart';
import 'database_service.dart';

class GoalService {
  static final GoalService instance = GoalService._init();
  GoalService._init();

  Future<List<Goal>> getGoals(int userId) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'target_date ASC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<Goal> addGoal(Goal goal) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert('goals', goal.toMap());
    return goal.copyWith(id: id);
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(int goalId) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}
