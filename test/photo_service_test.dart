import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:body_tracker/services/database_service.dart';
import 'package:body_tracker/services/photo_service.dart';
import 'package:body_tracker/models/progress_photo.dart';
import 'mocks.mocks.dart';

void main() {
  late MockDatabase mockDatabase;
  late MockDatabaseService mockDatabaseService;
  late PhotoService photoService;

  setUp(() {
    mockDatabase = MockDatabase();
    mockDatabaseService = MockDatabaseService();
    
    DatabaseService.instance = mockDatabaseService;
    when(mockDatabaseService.database).thenAnswer((_) async => mockDatabase);
    
    photoService = PhotoService();
  });

  group('PhotoService Tests', () {
    test('getPhotos returns list of photos', () async {
      final mockMaps = [
        {
          'id': 1,
          'user_id': 1,
          'image_path': '/path/to/image.jpg',
          'category': 'front',
          'notes': 'Test note',
          'weight': 80.0,
          'taken_at': '2026-01-01T00:00:00.000',
          'created_at': '2026-01-01T00:00:00.000',
        }
      ];

      when(mockDatabase.query(
        'progress_photos',
        where: 'user_id = ?',
        whereArgs: [1],
        orderBy: 'taken_at DESC',
      )).thenAnswer((_) async => mockMaps);

      final photos = await photoService.getPhotos(1);

      expect(photos.length, 1);
      expect(photos.first.category, 'front');
    });

    test('addPhoto inserts photo and returns with id', () async {
      final photo = ProgressPhoto(
        userId: 1,
        imagePath: '/path/image.jpg',
        takenAt: DateTime.now(),
      );

      when(mockDatabase.insert('progress_photos', any)).thenAnswer((_) async => 10);

      final savedPhoto = await photoService.addPhoto(photo);

      expect(savedPhoto.id, 10);
      verify(mockDatabase.insert('progress_photos', any)).called(1);
    });
  });
}
