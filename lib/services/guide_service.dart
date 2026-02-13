import 'package:sqflite/sqflite.dart';
import 'package:body_tracker/models/measurement_guide.dart';
import 'database_service.dart';

class GuideService {
  static final GuideService instance = GuideService._init();
  static Database? _database;

  GuideService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await DatabaseService.instance.database;
    return _database!;
  }

  Future<List<MeasurementGuide>> getCustomGuides(int userId) async {
    final db = await database;
    final result = await db.query(
      'custom_guides',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'title ASC',
    );

    return result.map((json) => MeasurementGuide.fromMap(json)).toList();
  }

  Future<MeasurementGuide> addCustomGuide(MeasurementGuide guide, int userId) async {
    final db = await database;
    
    // Create map for insertion, ensure user_id and created_at are set
    final map = guide.toMap();
    map['user_id'] = userId;
    map['created_at'] = DateTime.now().toIso8601String();
    map['is_custom'] = 1;
    
    // Remove ID if present (should be null for new items)
    map.remove('id');

    final id = await db.insert('custom_guides', map);
    
    // Return a copy with the new ID
    return MeasurementGuide(
      id: id,
      type: guide.type,
      title: guide.title,
      description: guide.description,
      instruction: guide.instruction,
      icon: guide.icon,
      color: guide.color,
      unit: guide.unit,
      minValue: guide.minValue,
      maxValue: guide.maxValue,
      isCustom: true,
    );
  }

  Future<int> deleteCustomGuide(int id) async {
    final db = await database;
    return await db.delete(
      'custom_guides',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCustomGuide(MeasurementGuide guide) async {
    if (guide.id == null) return 0;
    final db = await database;
    return await db.update(
      'custom_guides',
      guide.toMap(),
      where: 'id = ?',
      whereArgs: [guide.id],
    );
  }
}
