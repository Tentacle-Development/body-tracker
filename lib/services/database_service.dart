import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:meta/meta.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Database? _database;
  static DatabaseService _instance = DatabaseService._init();
  static DatabaseService get instance => _instance;

  @visibleForTesting
  static set instance(DatabaseService newInstance) => _instance = newInstance;

  DatabaseService._init();

  @visibleForTesting
  DatabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Measurements table
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        reminder_interval_days INTEGER DEFAULT 30,
        preferred_unit_system TEXT DEFAULT 'metric',
        enabled_tabs TEXT DEFAULT 'dashboard,measure,photos,progress,sizes,profile',
        is_cloud_sync_enabled INTEGER DEFAULT 0,
        is_google_drive_sync_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Progress photos table
    await db.execute('''
      CREATE TABLE progress_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        category TEXT,
        notes TEXT,
        weight REAL,
        taken_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        start_value REAL NOT NULL,
        target_value REAL NOT NULL,
        start_date TEXT NOT NULL,
        target_date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_measurements_user_id ON measurements (user_id)');
    await db.execute(
        'CREATE INDEX idx_measurements_type ON measurements (type)');
    await db.execute(
        'CREATE INDEX idx_measurements_measured_at ON measurements (measured_at)');
    await db.execute(
        'CREATE INDEX idx_progress_photos_user_id ON progress_photos (user_id)');
    await db.execute(
        'CREATE INDEX idx_progress_photos_taken_at ON progress_photos (taken_at)');
    await db.execute(
        'CREATE INDEX idx_goals_user_id ON goals (user_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add progress_photos table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS progress_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          category TEXT,
          notes TEXT,
          taken_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON progress_photos (user_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON progress_photos (taken_at)');
    }

    if (oldVersion < 3) {
      // Add weight column to progress_photos
      await db.execute('ALTER TABLE progress_photos ADD COLUMN weight REAL');
    }

    if (oldVersion < 4) {
      // Add goals table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          start_value REAL NOT NULL,
          target_value REAL NOT NULL,
          start_date TEXT NOT NULL,
          target_date TEXT NOT NULL,
          is_completed INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals (user_id)');
    }

    if (oldVersion < 5) {
      // Add enabled_tabs column to settings
      await db.execute(
          'ALTER TABLE settings ADD COLUMN enabled_tabs TEXT DEFAULT "dashboard,measure,photos,progress,sizes,profile"');
    }

    if (oldVersion < 6) {
      // Add is_google_drive_sync_enabled column to settings
      await db.execute(
          'ALTER TABLE settings ADD COLUMN is_google_drive_sync_enabled INTEGER DEFAULT 0');
    }

    if (oldVersion < 7) {
      // Ensure enabled_tabs exists and has correct default
      try {
        await db.execute('ALTER TABLE settings ADD COLUMN enabled_tabs TEXT DEFAULT "dashboard,measure,photos,progress,sizes,profile"');
      } catch (e) {
        // Column might already exist
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
