import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'photo_service.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  /// Create a full backup of all user data
  Future<String> createBackup(int userId) async {
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final backupName = 'body_tracker_backup_$timestamp';
    
    // Get temp directory for creating backup
    final tempDir = await getTemporaryDirectory();
    final backupDir = Directory(path.join(tempDir.path, backupName));
    await backupDir.create(recursive: true);
    
    // Create photos subdirectories
    final photosDir = Directory(path.join(backupDir.path, 'photos'));
    await Directory(path.join(photosDir.path, 'front')).create(recursive: true);
    await Directory(path.join(photosDir.path, 'side')).create(recursive: true);
    await Directory(path.join(photosDir.path, 'back')).create(recursive: true);
    
    // Export user profile
    await _exportUserProfile(userId, backupDir.path);
    
    // Export measurements
    await _exportMeasurements(userId, backupDir.path);
    
    // Export settings
    await _exportSettings(userId, backupDir.path);
    
    // Export photos with metadata
    await _exportPhotos(userId, backupDir.path);
    
    return backupDir.path;
  }

  Future<void> _exportUserProfile(int userId, String backupPath) async {
    final db = await DatabaseService.instance.database;
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    
    if (users.isEmpty) return;
    
    final csvLines = <String>[];
    csvLines.add('id,name,gender,date_of_birth,created_at,updated_at');
    
    for (final user in users) {
      csvLines.add([
        user['id'],
        _escapeCsv(user['name'] as String),
        _escapeCsv(user['gender'] as String),
        user['date_of_birth'],
        user['created_at'],
        user['updated_at'],
      ].join(','));
    }
    
    final file = File(path.join(backupPath, 'user_profile.csv'));
    await file.writeAsString(csvLines.join('\n'));
  }

  Future<void> _exportMeasurements(int userId, String backupPath) async {
    final db = await DatabaseService.instance.database;
    final measurements = await db.query(
      'measurements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measured_at ASC',
    );
    
    final csvLines = <String>[];
    csvLines.add('id,user_id,type,value,unit,measured_at,created_at');
    
    for (final m in measurements) {
      csvLines.add([
        m['id'],
        m['user_id'],
        _escapeCsv(m['type'] as String),
        m['value'],
        _escapeCsv(m['unit'] as String),
        m['measured_at'],
        m['created_at'],
      ].join(','));
    }
    
    final file = File(path.join(backupPath, 'measurements.csv'));
    await file.writeAsString(csvLines.join('\n'));
  }

  Future<void> _exportSettings(int userId, String backupPath) async {
    final db = await DatabaseService.instance.database;
    final settings = await db.query('settings', where: 'user_id = ?', whereArgs: [userId]);
    
    final csvLines = <String>[];
    csvLines.add('id,user_id,reminder_interval_days,preferred_unit_system,created_at,updated_at');
    
    for (final s in settings) {
      csvLines.add([
        s['id'],
        s['user_id'],
        s['reminder_interval_days'],
        _escapeCsv(s['preferred_unit_system'] as String? ?? 'metric'),
        s['created_at'],
        s['updated_at'],
      ].join(','));
    }
    
    final file = File(path.join(backupPath, 'settings.csv'));
    await file.writeAsString(csvLines.join('\n'));
  }

  Future<void> _exportPhotos(int userId, String backupPath) async {
    final photos = await PhotoService.instance.getPhotos(userId);
    
    final csvLines = <String>[];
    csvLines.add('original_id,filename,category,notes,taken_at,created_at');
    
    int frontCount = 0;
    int sideCount = 0;
    int backCount = 0;
    int otherCount = 0;
    
    for (final photo in photos) {
      final category = photo.category ?? 'other';
      final dateStr = DateFormat('yyyy-MM-dd').format(photo.takenAt);
      
      // Generate sequential filename
      int count;
      switch (category) {
        case 'front':
          frontCount++;
          count = frontCount;
          break;
        case 'side':
          sideCount++;
          count = sideCount;
          break;
        case 'back':
          backCount++;
          count = backCount;
          break;
        default:
          otherCount++;
          count = otherCount;
      }
      
      final extension = path.extension(photo.imagePath);
      final newFilename = '${category}_${dateStr}_${count.toString().padLeft(3, '0')}$extension';
      
      // Copy photo to backup
      final sourceFile = File(photo.imagePath);
      if (await sourceFile.exists()) {
        final categoryDir = category == 'other' ? 'photos' : 'photos/$category';
        final destPath = path.join(backupPath, categoryDir, newFilename);
        await sourceFile.copy(destPath);
      }
      
      csvLines.add([
        photo.id,
        newFilename,
        _escapeCsv(category),
        _escapeCsv(photo.notes ?? ''),
        photo.takenAt.toIso8601String(),
        photo.createdAt.toIso8601String(),
      ].join(','));
    }
    
    final file = File(path.join(backupPath, 'photos.csv'));
    await file.writeAsString(csvLines.join('\n'));
  }

  /// Import/restore from a backup directory
  Future<void> restoreBackup(String backupPath, int userId) async {
    // Import user profile (update existing)
    await _importUserProfile(backupPath, userId);
    
    // Import measurements
    await _importMeasurements(backupPath, userId);
    
    // Import settings
    await _importSettings(backupPath, userId);
    
    // Import photos
    await _importPhotos(backupPath, userId);
  }

  Future<void> _importUserProfile(String backupPath, int userId) async {
    final file = File(path.join(backupPath, 'user_profile.csv'));
    if (!await file.exists()) return;
    
    final lines = await file.readAsLines();
    if (lines.length < 2) return;
    
    final values = _parseCsvLine(lines[1]);
    if (values.length < 6) return;
    
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      {
        'name': values[1],
        'gender': values[2],
        'date_of_birth': values[3],
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> _importMeasurements(String backupPath, int userId) async {
    final file = File(path.join(backupPath, 'measurements.csv'));
    if (!await file.exists()) return;
    
    final lines = await file.readAsLines();
    if (lines.length < 2) return;
    
    final db = await DatabaseService.instance.database;
    
    // Clear existing measurements for this user
    await db.delete('measurements', where: 'user_id = ?', whereArgs: [userId]);
    
    for (int i = 1; i < lines.length; i++) {
      final values = _parseCsvLine(lines[i]);
      if (values.length < 7) continue;
      
      await db.insert('measurements', {
        'user_id': userId,
        'type': values[2],
        'value': double.tryParse(values[3]) ?? 0,
        'unit': values[4],
        'measured_at': values[5],
        'created_at': values[6],
      });
    }
  }

  Future<void> _importSettings(String backupPath, int userId) async {
    final file = File(path.join(backupPath, 'settings.csv'));
    if (!await file.exists()) return;
    
    final lines = await file.readAsLines();
    if (lines.length < 2) return;
    
    final values = _parseCsvLine(lines[1]);
    if (values.length < 6) return;
    
    final db = await DatabaseService.instance.database;
    
    // Update or insert settings
    final existing = await db.query('settings', where: 'user_id = ?', whereArgs: [userId]);
    
    if (existing.isEmpty) {
      await db.insert('settings', {
        'user_id': userId,
        'reminder_interval_days': int.tryParse(values[2]) ?? 30,
        'preferred_unit_system': values[3],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'settings',
        {
          'reminder_interval_days': int.tryParse(values[2]) ?? 30,
          'preferred_unit_system': values[3],
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  Future<void> _importPhotos(String backupPath, int userId) async {
    final file = File(path.join(backupPath, 'photos.csv'));
    if (!await file.exists()) {
      debugPrint('Backup: photos.csv not found');
      return;
    }
    
    final lines = await file.readAsLines();
    if (lines.length < 2) return;
    
    final db = await DatabaseService.instance.database;
    
    // Clear existing photos for this user
    final existingPhotos = await PhotoService.instance.getPhotos(userId);
    for (final photo in existingPhotos) {
      await PhotoService.instance.deletePhotoRecord(photo);
    }
    
    int importedCount = 0;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      
      final values = _parseCsvLine(lines[i]);
      if (values.length < 6) {
        debugPrint('Backup: Skipping photo line $i due to insufficient columns');
        continue;
      }
      
      final filename = values[1];
      final category = values[2];
      final notes = values[3].isEmpty ? null : values[3];
      final takenAt = DateTime.tryParse(values[4]) ?? DateTime.now();
      final createdAt = DateTime.tryParse(values[5]) ?? DateTime.now();
      
      // Find the photo file
      String? sourcePath;
      final categoryDir = category == 'other' ? 'photos' : 'photos/$category';
      final possiblePath = path.join(backupPath, categoryDir, filename);
      
      if (await File(possiblePath).exists()) {
        sourcePath = possiblePath;
      } else {
        // Try fallback without category dir just in case
        final fallbackPath = path.join(backupPath, 'photos', filename);
        if (await File(fallbackPath).exists()) {
          sourcePath = fallbackPath;
        }
      }
      
      if (sourcePath == null) {
        debugPrint('Backup: Photo file not found: $possiblePath');
        continue;
      }
      
      try {
        // Copy photo to app storage
        final savedPath = await PhotoService.instance.savePhoto(
          File(sourcePath),
          category: category,
        );
        
        // Add to database
        await db.insert('progress_photos', {
          'user_id': userId,
          'image_path': savedPath,
          'category': category,
          'notes': notes,
          'taken_at': takenAt.toIso8601String(),
          'created_at': createdAt.toIso8601String(),
        });
        importedCount++;
      } catch (e) {
        debugPrint('Backup: Failed to import photo $filename: $e');
      }
    }
    debugPrint('Backup: Imported $importedCount photos');
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    
    return result;
  }
}
