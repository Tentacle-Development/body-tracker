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

    // Export goals
    await _exportGoals(userId, backupDir.path);
    
    return backupDir.path;
  }

  Future<void> _exportGoals(int userId, String backupPath) async {
    final db = await DatabaseService.instance.database;
    final goals = await db.query('goals', where: 'user_id = ?', whereArgs: [userId]);

    if (goals.isEmpty) return;

    final csvLines = <String>[];
    csvLines.add('id,user_id,type,start_value,target_value,start_date,target_date,is_completed,created_at');

    for (final g in goals) {
      csvLines.add([
        g['id'],
        g['user_id'],
        _escapeCsv(g['type'] as String),
        g['start_value'],
        g['target_value'],
        g['start_date'],
        g['target_date'],
        g['is_completed'],
        g['created_at'],
      ].join(','));
    }

    final file = File(path.join(backupPath, 'goals.csv'));
    await file.writeAsString(csvLines.join('\n'));
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
    
    if (settings.isEmpty) return;
    
    final header = settings.first.keys.toList();
    final csvLines = <String>[];
    csvLines.add(header.join(','));
    
    for (final s in settings) {
      csvLines.add(header.map((key) => _escapeCsv(s[key]?.toString() ?? '')).join(','));
    }
    
    final file = File(path.join(backupPath, 'settings.csv'));
    await file.writeAsString(csvLines.join('\n'));
  }

  Future<void> _exportPhotos(int userId, String backupPath) async {
    final photos = await PhotoService.instance.getPhotos(userId);
    
    final csvLines = <String>[];
    csvLines.add('original_id,filename,category,notes,weight,taken_at,created_at');
    
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
        photo.weight ?? '',
        photo.takenAt.toIso8601String(),
        photo.createdAt.toIso8601String(),
      ].join(','));
    }
    
    final file = File(path.join(backupPath, 'photos.csv'));
    await file.writeAsString(csvLines.join('\n'));
  }

  /// Import/restore from a backup directory
  Future<void> restoreBackup(String backupPath, int? userId) async {
    int targetUserId;
    
    if (userId == null) {
      // Onboarding restore: we need to recreate the user first
      targetUserId = await _restoreUserFromBackup(backupPath);
    } else {
      targetUserId = userId;
      // Update existing user profile
      await _importUserProfile(backupPath, targetUserId);
    }
    
    // Import measurements
    await _importMeasurements(backupPath, targetUserId);
    
    // Import settings
    await _importSettings(backupPath, targetUserId);
    
    // Import photos
    await _importPhotos(backupPath, targetUserId);

    // Import goals
    await _importGoals(backupPath, targetUserId);
  }

  Future<void> _importGoals(String backupPath, int userId) async {
    final file = File(path.join(backupPath, 'goals.csv'));
    if (!await file.exists()) return;

    final lines = await file.readAsLines();
    if (lines.length < 2) return;

    final db = await DatabaseService.instance.database;
    await db.delete('goals', where: 'user_id = ?', whereArgs: [userId]);

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = _parseCsvLine(lines[i]);
      if (values.length < 9) continue;

      await db.insert('goals', {
        'user_id': userId,
        'type': values[2],
        'start_value': double.tryParse(values[3]) ?? 0.0,
        'target_value': double.tryParse(values[4]) ?? 0.0,
        'start_date': values[5],
        'target_date': values[6],
        'is_completed': int.tryParse(values[7]) ?? 0,
        'created_at': values[8],
      });
    }
  }

  Future<int> _restoreUserFromBackup(String backupPath) async {
    final file = File(path.join(backupPath, 'user_profile.csv'));
    if (!await file.exists()) throw Exception('Backup profile not found');
    
    final lines = await file.readAsLines();
    if (lines.length < 2) throw Exception('Backup profile empty');
    
    final values = _parseCsvLine(lines[1]);
    if (values.length < 6) throw Exception('Invalid backup profile');
    
    final db = await DatabaseService.instance.database;
    
    // Create the user
    final id = await db.insert('users', {
      'name': values[1],
      'gender': values[2],
      'date_of_birth': values[3],
      'created_at': values[4],
      'updated_at': values[5],
    });
    
    return id;
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
    
    final header = _parseCsvLine(lines[0]);
    final values = _parseCsvLine(lines[1]);
    
    final db = await DatabaseService.instance.database;
    
    // Map headers to values
    final Map<String, dynamic> settingsData = {};
    for (int i = 0; i < header.length; i++) {
      if (i < values.length) {
        settingsData[header[i]] = values[i];
      }
    }

    // Prepare map for DB
    final Map<String, dynamic> dbMap = {
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (settingsData.containsKey('reminder_interval_days')) {
      dbMap['reminder_interval_days'] = int.tryParse(settingsData['reminder_interval_days'].toString()) ?? 30;
    }
    if (settingsData.containsKey('preferred_unit_system')) {
      dbMap['preferred_unit_system'] = settingsData['preferred_unit_system'];
    }
    if (settingsData.containsKey('enabled_tabs')) {
      dbMap['enabled_tabs'] = settingsData['enabled_tabs'];
    }
    if (settingsData.containsKey('is_google_drive_sync_enabled')) {
      dbMap['is_google_drive_sync_enabled'] = (settingsData['is_google_drive_sync_enabled'].toString() == '1') ? 1 : 0;
    }

    final existing = await db.query('settings', where: 'user_id = ?', whereArgs: [userId]);
    
    if (existing.isEmpty) {
      dbMap['created_at'] = settingsData['created_at'] ?? DateTime.now().toIso8601String();
      await db.insert('settings', dbMap);
    } else {
      await db.update('settings', dbMap, where: 'user_id = ?', whereArgs: [userId]);
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
      
      // Handle legacy backups without weight column
      double? weight;
      DateTime takenAt;
      DateTime createdAt;
      
      if (values.length >= 7) {
        weight = double.tryParse(values[4]);
        takenAt = DateTime.tryParse(values[5]) ?? DateTime.now();
        createdAt = DateTime.tryParse(values[6]) ?? DateTime.now();
      } else {
        takenAt = DateTime.tryParse(values[4]) ?? DateTime.now();
        createdAt = DateTime.tryParse(values[5]) ?? DateTime.now();
      }
      
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
          'weight': weight,
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
