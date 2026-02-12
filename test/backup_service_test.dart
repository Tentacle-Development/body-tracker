import 'package:flutter_test/flutter_test.dart';
import 'package:body_tracker/services/backup_service.dart';

void main() {
  group('BackupService CSV Utility Tests', () {
    final backupService = BackupService.instance;

    test('escapeCsv escapes strings with commas', () {
      expect(backupService.escapeCsv('hello, world'), equals('"hello, world"'));
      expect(backupService.escapeCsv('normal'), equals('normal'));
    });

    test('escapeCsv escapes strings with quotes', () {
      expect(backupService.escapeCsv('He said "Hello"'), equals('"He said ""Hello"""'));
    });

    test('parseCsvLine parses normal lines', () {
      final line = '1,John,Male';
      final result = backupService.parseCsvLine(line);
      expect(result, equals(['1', 'John', 'Male']));
    });

    test('parseCsvLine parses quoted lines', () {
      final line = '1,"John, Doe",Male';
      final result = backupService.parseCsvLine(line);
      expect(result, equals(['1', 'John, Doe', 'Male']));
    });

    test('parseCsvLine parses escaped quotes', () {
      final line = '1,"He said ""Hello""",Male';
      final result = backupService.parseCsvLine(line);
      expect(result, equals(['1', 'He said "Hello"', 'Male']));
    });
  });
}
