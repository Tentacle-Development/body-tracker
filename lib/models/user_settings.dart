class UserSettings {
  final int? id;
  final int userId;
  final int reminderIntervalDays;
  final String preferredUnitSystem;
  final bool isCloudSyncEnabled;
  final bool isGoogleDriveSyncEnabled;
  final List<String> enabledTabs;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    this.id,
    required this.userId,
    this.reminderIntervalDays = 30,
    this.preferredUnitSystem = 'metric',
    this.isCloudSyncEnabled = false,
    this.isGoogleDriveSyncEnabled = false,
    this.enabledTabs = const ['dashboard', 'measure', 'photos', 'progress', 'sizes', 'profile'],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'reminder_interval_days': reminderIntervalDays,
      'preferred_unit_system': preferredUnitSystem,
      'is_cloud_sync_enabled': isCloudSyncEnabled ? 1 : 0,
      'is_google_drive_sync_enabled': isGoogleDriveSyncEnabled ? 1 : 0,
      'enabled_tabs': enabledTabs.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final tabsString = map['enabled_tabs'] as String? ?? 'dashboard,measure,photos,progress,sizes,profile';
    return UserSettings(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      reminderIntervalDays: map['reminder_interval_days'] as int? ?? 30,
      preferredUnitSystem: map['preferred_unit_system'] as String? ?? 'metric',
      isCloudSyncEnabled: (map['is_cloud_sync_enabled'] as int? ?? 0) == 1,
      isGoogleDriveSyncEnabled: (map['is_google_drive_sync_enabled'] as int? ?? 0) == 1,
      enabledTabs: tabsString.split(',').where((t) => t.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UserSettings copyWith({
    int? id,
    int? userId,
    int? reminderIntervalDays,
    String? preferredUnitSystem,
    bool? isCloudSyncEnabled,
    bool? isGoogleDriveSyncEnabled,
    List<String>? enabledTabs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reminderIntervalDays: reminderIntervalDays ?? this.reminderIntervalDays,
      preferredUnitSystem: preferredUnitSystem ?? this.preferredUnitSystem,
      isCloudSyncEnabled: isCloudSyncEnabled ?? this.isCloudSyncEnabled,
      isGoogleDriveSyncEnabled: isGoogleDriveSyncEnabled ?? this.isGoogleDriveSyncEnabled,
      enabledTabs: enabledTabs ?? this.enabledTabs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
