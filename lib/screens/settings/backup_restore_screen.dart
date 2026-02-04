import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_drive_service.dart';
import '../../utils/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final AuthService _authService = AuthService();
  final GoogleDriveService _driveService = GoogleDriveService.instance;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSyncing = false;
  String? _statusMessage;

  Future<void> _toggleGoogleDriveSync(bool enabled) async {
    final appProvider = context.read<AppProvider>();
    if (enabled) {
      try {
        final account = await _driveService.signIn();
        if (account != null) {
          final settings = appProvider.settings!.copyWith(isGoogleDriveSyncEnabled: true);
          await appProvider.updateSettings(settings);
          setState(() => _statusMessage = 'Google Drive sync enabled for ${account.email}');
        } else {
          setState(() => _statusMessage = 'Google Sign-In cancelled');
        }
      } catch (e) {
        _showError('Google Drive setup failed: $e');
      }
    } else {
      await _driveService.signOut();
      final settings = appProvider.settings!.copyWith(isGoogleDriveSyncEnabled: false);
      await appProvider.updateSettings(settings);
      setState(() => _statusMessage = 'Google Drive sync disabled');
    }
  }

  Future<void> _syncToGoogleDrive() async {
    final appProvider = context.read<AppProvider>();
    final userId = appProvider.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Uploading to Google Drive...';
    });

    try {
      final backupPath = await BackupService.instance.createBackup(userId);
      final zipPath = await _createZipFromDirectory(backupPath);
      
      final success = await _driveService.uploadBackup(zipPath);
      
      // Cleanup
      await Directory(backupPath).delete(recursive: true);
      await File(zipPath).delete();

      setState(() {
        _isSyncing = false;
        _statusMessage = success ? 'Uploaded to Google Drive!' : 'Upload failed';
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Sync failed: $e';
      });
    }
  }

  Future<void> _restoreFromGoogleDrive() async {
    final appProvider = context.read<AppProvider>();
    
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Fetching backups from Google Drive...';
    });

    try {
      final files = await _driveService.listBackups();
      if (files.isEmpty) {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'No backups found on Google Drive';
        });
        return;
      }

      // In a real app, we'd show a picker. For now, take the latest.
      final latest = files.first;
      final localPath = await _driveService.downloadBackup(latest.id!, latest.name!);
      
      if (localPath != null) {
        setState(() => _statusMessage = 'Extracting Google Drive backup...');
        final extractPath = await _extractZip(localPath);
        
        final userId = appProvider.currentUser?.id ?? -1;
        await BackupService.instance.restoreBackup(extractPath, userId);
        await appProvider.initialize();

        await Directory(extractPath).delete(recursive: true);
        await File(localPath).delete();

        setState(() {
          _isSyncing = false;
          _statusMessage = 'Restored from Google Drive!';
        });
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Restore failed: $e';
      });
    }
  }

  Future<void> _toggleCloudSync(bool enabled) async {
    final appProvider = context.read<AppProvider>();
    if (enabled) {
      try {
        final user = await _authService.signInWithGoogle();
        if (user != null) {
          final settings = appProvider.settings!.copyWith(isCloudSyncEnabled: true);
          await appProvider.updateSettings(settings);
          
          setState(() {
            _isSyncing = true;
            _statusMessage = 'Syncing data to cloud...';
          });
          
          await appProvider.syncAllToCloud();
          
          setState(() {
            _isSyncing = false;
            _statusMessage = 'Cloud sync active for ${user.email}';
          });
        } else {
          setState(() => _statusMessage = 'Login cancelled');
        }
      } catch (e) {
        _showError('Cloud sync failed: $e');
      }
    } else {
      await _authService.signOut();
      final settings = appProvider.settings!.copyWith(isCloudSyncEnabled: false);
      await appProvider.updateSettings(settings);
      setState(() => _statusMessage = 'Cloud sync disabled');
    }
  }

  Future<void> _exportBackup() async {
    final appProvider = context.read<AppProvider>();
    final userId = appProvider.currentUser?.id;
    if (userId == null) {
      // If no user profile found, try to use the first user if available
      if (appProvider.users.isNotEmpty) {
        final firstUser = appProvider.users.first;
        _exportWithId(firstUser.id!);
      } else {
        _showError('No user profile found to backup');
      }
      return;
    }
    _exportWithId(userId);
  }

  Future<void> _exportWithId(int userId) async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Creating backup...';
    });

    try {
      // Create backup folder
      final backupPath = await BackupService.instance.createBackup(userId);
      
      setState(() => _statusMessage = 'Compressing backup...');
      
      // Create ZIP file
      final zipPath = await _createZipFromDirectory(backupPath);
      
      setState(() => _statusMessage = 'Ready to share!');
      
      // Share the ZIP file
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: 'Body Tracker Backup',
        text: 'My Body Tracker backup file',
      );

      setState(() {
        _isExporting = false;
        _statusMessage = 'Backup exported successfully!';
      });

      // Clean up temp backup folder
      await Directory(backupPath).delete(recursive: true);
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = null;
      });
      _showError('Export failed: $e');
    }
  }

  Future<String> _createZipFromDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final archive = Archive();
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: dirPath);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }
    
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to create ZIP');
    
    final tempDir = await getTemporaryDirectory();
    final zipPath = path.join(tempDir.path, '${path.basename(dirPath)}.zip');
    await File(zipPath).writeAsBytes(zipData);
    
    return zipPath;
  }

  Future<void> _importBackup() async {
    final appProvider = context.read<AppProvider>();
    
    // Pick ZIP file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    // Confirm before import
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will restore data from the backup file. '
          'Existing data might be affected.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isImporting = true;
      _statusMessage = 'Extracting backup...';
    });

    try {
      // Extract ZIP
      final extractPath = await _extractZip(filePath);

      setState(() => _statusMessage = 'Restoring data...');

      // Restore from backup
      // If we don't have a userId yet, we pass -1 and the service should handle it (create a new user)
      final userId = appProvider.currentUser?.id ?? -1;
      await BackupService.instance.restoreBackup(extractPath, userId);

      // Reload app data
      await appProvider.initialize();

      setState(() {
        _isImporting = false;
        _statusMessage = 'Backup restored successfully!';
      });

      // Clean up
      await Directory(extractPath).delete(recursive: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = null;
      });
      _showError('Import failed: $e');
    }
  }

  Future<String> _extractZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    final tempDir = await getTemporaryDirectory();
    final extractPath = path.join(
      tempDir.path,
      'restore_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    for (final file in archive) {
      final filePath = path.join(extractPath, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
    
    return extractPath;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isExporting || _isImporting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data is stored locally on this device. '
                    'Create a backup to save your measurements, photos, and settings.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cloud Sync Section
            _buildCloudSyncCard(),
            const SizedBox(height: 16),
            _buildGoogleDriveCard(),
            const SizedBox(height: 24),

            // Export button
            _buildActionCard(
              icon: Icons.upload_rounded,
              title: 'Export Backup',
              subtitle: 'Save all data as a ZIP file',
              color: AppTheme.primaryColor,
              onTap: isLoading ? null : _exportBackup,
              isLoading: _isExporting,
            ),
            const SizedBox(height: 16),

            // Import button
            _buildActionCard(
              icon: Icons.download_rounded,
              title: 'Restore Backup',
              subtitle: 'Import from a backup ZIP file',
              color: AppTheme.secondaryColor,
              onTap: isLoading ? null : _importBackup,
              isLoading: _isImporting,
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_statusMessage!)),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Backup contents info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup includes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('User profile'),
                  _buildBulletPoint('All measurements'),
                  _buildBulletPoint('App settings'),
                  _buildBulletPoint('Progress photos'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleDriveCard() {
    final appProvider = context.watch<AppProvider>();
    final isEnabled = appProvider.settings?.isGoogleDriveSyncEnabled ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? Colors.blue.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isEnabled ? Colors.blue : Colors.grey).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_to_drive_rounded,
                  color: isEnabled ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Drive',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Personal Drive Backup',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: _isSyncing ? null : _toggleGoogleDriveSync,
                activeColor: Colors.blue,
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _isSyncing ? null : _syncToGoogleDrive,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Backup Now'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _isSyncing ? null : _restoreFromGoogleDrive,
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('Restore'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildCloudSyncCard() {
    final appProvider = context.watch<AppProvider>();
    final isEnabled = appProvider.settings?.isCloudSyncEnabled ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppTheme.primaryColor.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isEnabled ? AppTheme.primaryColor : Colors.grey).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEnabled ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isEnabled ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Sync',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Auto-backup to Firebase',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: _isSyncing ? null : _toggleCloudSync,
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Last synced: Just now',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                TextButton.icon(
                  onPressed: _isSyncing ? null : () => _toggleCloudSync(true),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
