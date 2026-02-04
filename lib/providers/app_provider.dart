import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/measurement.dart';
import '../models/progress_photo.dart';
import '../models/user_settings.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';
import '../services/notification_service.dart';
import '../services/goal_service.dart';

class AppProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  UserSettings? _settings;
  List<UserProfile> _users = [];
  List<Measurement> _measurements = [];
  List<ProgressPhoto> _photos = [];
  List<Goal> _goals = [];
  List<String> _dashboardCategories = ['bmi', 'whr', 'weight', 'height'];
  bool _isLoading = true;
  bool _isFirstLaunch = true;

  UserProfile? get currentUser => _currentUser;
  UserSettings? get settings => _settings;
  List<UserProfile> get users => _users;
  List<Measurement> get measurements => _measurements;
  List<ProgressPhoto> get photos => _photos;
  List<Goal> get goals => _goals;
  List<String> get dashboardCategories => _dashboardCategories;
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseService.instance.database;
      
      // Load users
      final userMaps = await db.query('users');
      _users = userMaps.map((map) => UserProfile.fromMap(map)).toList();
      
      // Check if first launch
      _isFirstLaunch = _users.isEmpty;
      
      // Set current user to first user if exists
      if (_users.isNotEmpty) {
        _currentUser = _users.first;
        await Future.wait([
          loadMeasurements(),
          loadPhotos(),
          loadDashboardCategories(),
          loadSettings(),
          loadGoals(),
        ]);
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMeasurements() async {
    if (_currentUser == null) return;

    try {
      final db = await DatabaseService.instance.database;
      final measurementMaps = await db.query(
        'measurements',
        where: 'user_id = ?',
        whereArgs: [_currentUser!.id],
        orderBy: 'measured_at DESC',
      );
      _measurements =
          measurementMaps.map((map) => Measurement.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading measurements: $e');
    }
  }

  Future<void> loadPhotos() async {
    if (_currentUser == null || _currentUser!.id == null) return;

    try {
      _photos = await PhotoService.instance.getPhotos(_currentUser!.id!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }
  }

  Future<void> loadDashboardCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('dashboard_categories');
      if (savedCategories != null && savedCategories.isNotEmpty) {
        _dashboardCategories = savedCategories;
      } else {
        // Defaults
        _dashboardCategories = ['bmi', 'whr', 'weight', 'height'];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard categories: $e');
    }
  }

  Future<void> setDashboardCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dashboard_categories', categories);
      _dashboardCategories = categories;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving dashboard categories: $e');
    }
  }

  Future<void> loadSettings() async {
    if (_currentUser == null || _currentUser!.id == null) return;

    try {
      final db = await DatabaseService.instance.database;
      final maps = await db.query(
        'settings',
        where: 'user_id = ?',
        whereArgs: [_currentUser!.id],
      );

      if (maps.isNotEmpty) {
        _settings = UserSettings.fromMap(maps.first);
      } else {
        // Create default settings if not exist
        _settings = UserSettings(userId: _currentUser!.id!);
        await db.insert('settings', _settings!.toMap());
      }
      
      // Sync notifications
      await _syncReminders();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> loadGoals() async {
    if (_currentUser == null || _currentUser!.id == null) return;

    try {
      _goals = await GoalService.instance.getGoals(_currentUser!.id!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      final newGoal = await GoalService.instance.addGoal(goal);
      _goals.add(newGoal);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding goal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await GoalService.instance.updateGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating goal: $e');
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await GoalService.instance.deleteGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
    }
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'settings',
        newSettings.toMap(),
        where: 'user_id = ?',
        whereArgs: [newSettings.userId],
      );
      _settings = newSettings;
      
      // Resync notifications
      await _syncReminders();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  Future<void> _syncReminders() async {
    if (_settings == null) return;

    final interval = _settings!.reminderIntervalDays;
    if (interval > 0) {
      try {
        await NotificationService.instance.scheduleReminder(
          id: 1,
          title: 'Time to Measure!',
          body: "Don't forget to track your body progress today. Stay consistent!",
          intervalDays: interval,
        );
      } catch (e) {
        debugPrint('Error scheduling reminder: $e');
      }
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> createUser(UserProfile user) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('users', user.toMap());
      final newUser = user.copyWith(id: id);
      _users.add(newUser);
      _currentUser = newUser;
      _isFirstLaunch = false;
      
      // Load data for the new user
      await loadMeasurements();
      await loadPhotos();
      await loadDashboardCategories();
      await loadSettings();
      await loadGoals();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('users');
      await db.delete('measurements');
      await db.delete('settings');
      await db.delete('progress_photos');
      await db.delete('goals');
      
      _currentUser = null;
      _users = [];
      _measurements = [];
      _photos = [];
      _goals = [];
      _isFirstLaunch = true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      _users.removeWhere((u) => u.id == userId);
      
      if (_currentUser?.id == userId) {
        if (_users.isNotEmpty) {
          setCurrentUser(_users.first);
        } else {
          _currentUser = null;
          _isFirstLaunch = true;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> addMeasurement(Measurement measurement) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('measurements', measurement.toMap());
      final newMeasurement = measurement.copyWith(id: id);
      _measurements.insert(0, newMeasurement);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding measurement: $e');
      rethrow;
    }
  }

  Future<void> addPhoto(ProgressPhoto photo) async {
    try {
      final newPhoto = await PhotoService.instance.addPhoto(photo);
      _photos.insert(0, newPhoto);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding photo: $e');
      rethrow;
    }
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    try {
      await PhotoService.instance.deletePhotoRecord(photo);
      _photos.removeWhere((p) => p.id == photo.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting photo: $e');
    }
  }

  void setCurrentUser(UserProfile user) {
    _currentUser = user;
    _isFirstLaunch = false;
    loadMeasurements();
    loadPhotos();
    loadDashboardCategories();
    loadSettings();
    loadGoals();
    notifyListeners();
  }

  List<Measurement> getMeasurementsByType(String type) {
    return _measurements.where((m) => m.type == type).toList();
  }

  Measurement? getLatestMeasurement(String type) {
    final filtered = getMeasurementsByType(type);
    return filtered.isNotEmpty ? filtered.first : null;
  }

  double? calculateBMI() {
    final height = getLatestMeasurement('height');
    final weight = getLatestMeasurement('weight');

    if (height == null || weight == null) return null;

    // Convert to meters if in cm
    double heightInMeters = height.unit == 'cm' 
        ? height.value / 100 
        : height.value * 0.3048; // ft to meters

    // Convert to kg if in lbs
    double weightInKg = weight.unit == 'lbs' 
        ? weight.value * 0.453592 
        : weight.value;

    return weightInKg / (heightInMeters * heightInMeters);
  }

  double? calculateWaistToHipRatio() {
    final waist = getLatestMeasurement('waist');
    final hips = getLatestMeasurement('hips');

    if (waist == null || hips == null) return null;

    // Ensure same units
    double waistValue = waist.value;
    double hipsValue = hips.value;

    if (waist.unit != hips.unit) {
      if (waist.unit == 'in') {
        waistValue = waistValue * 2.54;
      } else {
        hipsValue = hipsValue * 2.54;
      }
    }

    return waistValue / hipsValue;
  }
}
