import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/measurement.dart';
import '../models/progress_photo.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';

class AppProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  List<UserProfile> _users = [];
  List<Measurement> _measurements = [];
  List<ProgressPhoto> _photos = [];
  bool _isLoading = true;
  bool _isFirstLaunch = true;

  UserProfile? get currentUser => _currentUser;
  List<UserProfile> get users => _users;
  List<Measurement> get measurements => _measurements;
  List<ProgressPhoto> get photos => _photos;
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
        await loadMeasurements();
        await loadPhotos();
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

  Future<void> createUser(UserProfile user) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('users', user.toMap());
      final newUser = user.copyWith(id: id);
      _users.add(newUser);
      _currentUser = newUser;
      _isFirstLaunch = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
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

  void setCurrentUser(UserProfile user) {
    _currentUser = user;
    loadMeasurements();
    loadPhotos();
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
