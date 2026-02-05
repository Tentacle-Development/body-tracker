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
    
    // Check if we have a user, if not we need to handle it during onboarding
    int? userId = appProvider.currentUser?.id;

    // Confirm before import
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
      // Pick ZIP file
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

      // Extract ZIP
      final extractPath = await _extractZip(filePath);

      setState(() => _statusMessage = 'Restoring data...');

      // If we don't have a user (onboarding), we perform a "clean restore"
      if (userId == null) {
        await appProvider.clearAllData();
      }
      
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
        
        // If we were in onboarding, go to home
        if (userId == null) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen()),
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
