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
import '../../services/google_drive_service.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSyncing = false;
  String? _statusMessage;

  Future<void> _exportBackup() async {
    final appProvider = context.read<AppProvider>();
    final userId = appProvider.currentUser?.id;
    if (userId == null) {
      _showError('No user profile found');
      return;
    }

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
    int? userId = appProvider.currentUser?.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all your current data with the backup data. '
          'This action cannot be undone.\n\nContinue?',
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

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      setState(() {
        _isImporting = true;
        _statusMessage = 'Extracting backup...';
      });

      final extractPath = await _extractZip(filePath);

      setState(() => _statusMessage = 'Restoring data...');

      if (userId == null) {
        await appProvider.clearAllData();
      }
      
      await BackupService.instance.restoreBackup(extractPath, userId);
      await appProvider.initialize();

      setState(() {
        _isImporting = false;
        _statusMessage = 'Backup restored successfully!';
      });

      await Directory(extractPath).delete(recursive: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (userId == null) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = null;
      });
      _showError('Import failed: $e');
    }
  }

  Future<void> _toggleGoogleDrive(bool enabled) async {
    final provider = context.read<AppProvider>();
    
    if (enabled) {
      setState(() {
        _isSyncing = true;
        _statusMessage = 'Signing in to Google...';
      });

      try {
        final account = await GoogleDriveService.instance.signIn();
        if (account == null) {
          _showError('Google Sign-In failed or cancelled');
          return;
        }

        final newSettings = provider.settings!.copyWith(isGoogleDriveSyncEnabled: true);
        await provider.updateSettings(newSettings);
        
        setState(() => _statusMessage = 'Google Drive sync enabled!');
      } catch (e) {
        _showError('Failed to enable Google Drive sync: $e');
      } finally {
        setState(() => _isSyncing = false);
      }
    } else {
      final newSettings = provider.settings!.copyWith(isGoogleDriveSyncEnabled: false);
      await provider.updateSettings(newSettings);
      await GoogleDriveService.instance.signOut();
      setState(() => _statusMessage = 'Google Drive sync disabled.');
    }
  }

  Future<void> _syncToGoogleDrive() async {
    final provider = context.read<AppProvider>();
    final userId = provider.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Preparing backup...';
    });

    try {
      final backupPath = await BackupService.instance.createBackup(userId);
      final zipPath = await _createZipFromDirectory(backupPath);
      
      setState(() => _statusMessage = 'Uploading to Google Drive...');
      final result = await GoogleDriveService.instance.uploadBackup(zipPath);
      
      if (result.success) {
        setState(() => _statusMessage = 'Backup uploaded to Google Drive!');
      } else {
        _showError('Failed to upload backup: ${result.error}');
      }

      await Directory(backupPath).delete(recursive: true);
      await File(zipPath).delete();
    } catch (e) {
      _showError('Sync failed: $e');
    } finally {
      setState(() => _isSyncing = false);
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
    final isLoading = _isExporting || _isImporting || _isSyncing;
    final isDriveEnabled = context.select<AppProvider, bool>((p) => p.settings?.isGoogleDriveSyncEnabled ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data is stored locally. Create a backup to save your measurements, photos, and settings.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Local Backup',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              icon: Icons.upload_rounded,
              title: 'Export Backup',
              subtitle: 'Save all data as a ZIP file',
              color: AppTheme.primaryColor,
              onTap: isLoading ? null : _exportBackup,
              isLoading: _isExporting,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.download_rounded,
              title: 'Restore Backup',
              subtitle: 'Import from a backup ZIP file',
              color: AppTheme.secondaryColor,
              onTap: isLoading ? null : _importBackup,
              isLoading: _isImporting,
            ),

            const SizedBox(height: 32),
            const Text(
              'Cloud Backup',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_queue_rounded, color: Colors.blue),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Google Drive Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Store backups in your private Drive folder', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDriveEnabled,
                        onChanged: isLoading ? null : _toggleGoogleDrive,
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  if (isDriveEnabled) ...[
                    const Divider(height: 32, color: Colors.white10),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _syncToGoogleDrive,
                      icon: _isSyncing 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync_rounded),
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
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
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_statusMessage!)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup includes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildBulletPoint('User profile'),
                  _buildBulletPoint('All measurements'),
                  _buildBulletPoint('App settings'),
                  _buildBulletPoint('Progress photos'),
                  _buildBulletPoint('Goals'),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
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
}
