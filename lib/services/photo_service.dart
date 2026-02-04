import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/progress_photo.dart';
import 'database_service.dart';

class PhotoService {
  static final PhotoService instance = PhotoService._init();
  PhotoService._init();

  /// Get the app's photo storage directory
  Future<Directory> get _photoDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, 'progress_photos'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  /// Save a photo to app storage and return the path
  Future<String> savePhoto(File imageFile, {String? category}) async {
    final photoDir = await _photoDirectory;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final categoryPrefix = category ?? 'photo';
    final extension = path.extension(imageFile.path);
    final fileName = '${categoryPrefix}_$timestamp$extension';
    final savedPath = path.join(photoDir.path, fileName);
    
    await imageFile.copy(savedPath);
    return savedPath;
  }

  /// Delete a photo from storage
  Future<void> deletePhoto(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get all photos for a user
  Future<List<ProgressPhoto>> getPhotos(int userId) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'progress_photos',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => ProgressPhoto.fromMap(map)).toList();
  }

  /// Get photos by category
  Future<List<ProgressPhoto>> getPhotosByCategory(int userId, String category) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'progress_photos',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => ProgressPhoto.fromMap(map)).toList();
  }

  /// Get photos within a date range
  Future<List<ProgressPhoto>> getPhotosInRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'progress_photos',
      where: 'user_id = ? AND taken_at >= ? AND taken_at <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => ProgressPhoto.fromMap(map)).toList();
  }

  /// Add a photo record to the database
  Future<ProgressPhoto> addPhoto(ProgressPhoto photo) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert('progress_photos', photo.toMap());
    return photo.copyWith(id: id);
  }

  /// Update a photo record
  Future<void> updatePhoto(ProgressPhoto photo) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'progress_photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  /// Delete a photo record and file
  Future<void> deletePhotoRecord(ProgressPhoto photo) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'progress_photos',
      where: 'id = ?',
      whereArgs: [photo.id],
    );
    await deletePhoto(photo.imagePath);
  }

  /// Get the count of photos for a user
  Future<int> getPhotoCount(int userId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM progress_photos WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
}
