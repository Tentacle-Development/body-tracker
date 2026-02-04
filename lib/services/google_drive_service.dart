import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._init();
  GoogleDriveService._init();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<auth.AuthClient?> _getAuthClient() async {
    final account = _currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          authHeaders['Authorization']!.replaceAll('Bearer ', ''),
          DateTime.now().add(const Duration(hours: 1)).toUtc(),
        ),
        null,
        [drive.DriveApi.driveAppdataScope, drive.DriveApi.driveFileScope],
      ),
    );
    return authenticateClient;
  }

  Future<bool> uploadBackup(String filePath) async {
    final client = await _getAuthClient();
    if (client == null) return false;

    try {
      final driveApi = drive.DriveApi(client);
      final file = File(filePath);
      
      final driveFile = drive.File();
      driveFile.name = path.basename(filePath);
      // We store it in appDataFolder so it's hidden from the user but accessible to the app
      driveFile.parents = ['appDataFolder'];

      final media = drive.Media(file.openRead(), file.lengthSync());
      
      // Check if file already exists to update it or create new
      final fileList = await driveApi.files.list(
        q: "name = '${driveFile.name}' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing
        final existingId = fileList.files!.first.id!;
        await driveApi.files.update(drive.File(), existingId, uploadMedia: media);
        debugPrint('Updated existing backup on Google Drive');
      } else {
        // Create new
        await driveApi.files.create(driveFile, uploadMedia: media);
        debugPrint('Created new backup on Google Drive');
      }
      return true;
    } catch (e) {
      debugPrint('Error uploading to Google Drive: $e');
      return false;
    } finally {
      client.close();
    }
  }

  Future<List<drive.File>> listBackups() async {
    final client = await _getAuthClient();
    if (client == null) return [];

    try {
      final driveApi = drive.DriveApi(client);
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        $fields: 'files(id, name, createdTime, size)',
      );
      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Error listing Google Drive backups: $e');
      return [];
    } finally {
      client.close();
    }
  }

  Future<String?> downloadBackup(String fileId, String fileName) async {
    final client = await _getAuthClient();
    if (client == null) return null;

    try {
      final driveApi = drive.DriveApi(client);
      final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      
      final tempDir = Directory.systemTemp;
      final savePath = path.join(tempDir.path, fileName);
      final file = File(savePath);
      
      final List<int> dataBytes = [];
      await for (final data in media.stream) {
        dataBytes.addAll(data);
      }
      await file.writeAsBytes(dataBytes);
      
      return savePath;
    } catch (e) {
      debugPrint('Error downloading from Google Drive: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
