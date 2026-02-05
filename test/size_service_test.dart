import 'package:flutter_test/flutter_test.dart';
import 'package:body_tracker/services/size_service.dart';

void main() {
  group('SizeService Tests', () {
    test('getCategories returns correct list for gender', () {
      final menCategories = SizeService.getCategories('Male');
      expect(menCategories, equals(SizeService.menSizes));
      expect(menCategories.first.title, contains('T-Shirts'));

      final womenCategories = SizeService.getCategories('Female');
      expect(womenCategories, equals(SizeService.womenSizes));
      expect(womenCategories.first.title, contains('Tops'));
    });

    test('getCategories defaults to Male', () {
      final categories = SizeService.getCategories(null);
      expect(categories, equals(SizeService.menSizes));
    });

    group('SizeCategory getSize', () {
      final category = SizeService.menSizes.first; // T-Shirts / Sweaters (XS: 86-91)

      test('returns null for null value', () {
        expect(category.getSize(null), isNull);
      });

      test('returns correct label for value in range', () {
        expect(category.getSize(88), equals('XS'));
        expect(category.getSize(93), equals('S'));
      });

      test('returns edge case labels', () {
        expect(category.getSize(85), equals('< XS'));
        expect(category.getSize(125), equals('> 3XL'));
      });
    });
  });
}
