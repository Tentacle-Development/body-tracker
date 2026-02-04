class SizeRange {
  final String label;
  final double min;
  final double max;

  const SizeRange(this.label, this.min, this.max);

  bool contains(double value) => value >= min && value <= max;
}

class SizeCategory {
  final String title;
  final String measurementType;
  final List<SizeRange> ranges;

  const SizeCategory({
    required this.title,
    required this.measurementType,
    required this.ranges,
  });

  String? getSize(double? value) {
    if (value == null) return null;
    for (final range in ranges) {
      if (range.contains(value)) return range.label;
    }
    if (value < ranges.first.min) return '< ${ranges.first.label}';
    if (value > ranges.last.max) return '> ${ranges.last.label}';
    return null;
  }
}

class SizeService {
  static final List<SizeCategory> menSizes = [
    SizeCategory(
      title: 'T-Shirts / Sweaters',
      measurementType: 'chest',
      ranges: [
        SizeRange('XS', 86, 91),
        SizeRange('S', 91, 96),
        SizeRange('M', 96, 101),
        SizeRange('L', 101, 106),
        SizeRange('XL', 106, 111),
        SizeRange('XXL', 111, 116),
        SizeRange('3XL', 116, 121),
      ],
    ),
    SizeCategory(
      title: 'Pants / Jeans',
      measurementType: 'waist',
      ranges: [
        SizeRange('28', 70, 72),
        SizeRange('30', 75, 77),
        SizeRange('32', 80, 82),
        SizeRange('34', 85, 87),
        SizeRange('36', 90, 92),
        SizeRange('38', 95, 97),
        SizeRange('40', 100, 102),
      ],
    ),
  ];

  static final List<SizeCategory> womenSizes = [
    SizeCategory(
      title: 'Tops / Dresses',
      measurementType: 'chest',
      ranges: [
        SizeRange('XS (34)', 80, 84),
        SizeRange('S (36)', 84, 88),
        SizeRange('M (38-40)', 88, 96),
        SizeRange('L (42-44)', 96, 104),
        SizeRange('XL (46-48)', 104, 116),
        SizeRange('XXL (50+)', 116, 130),
      ],
    ),
    SizeCategory(
      title: 'Skirts / Trousers',
      measurementType: 'waist',
      ranges: [
        SizeRange('XS (34)', 62, 66),
        SizeRange('S (36)', 66, 70),
        SizeRange('M (38-40)', 70, 78),
        SizeRange('L (42-44)', 78, 86),
        SizeRange('XL (46-48)', 86, 98),
        SizeRange('XXL (50+)', 98, 110),
      ],
    ),
  ];

  static List<SizeCategory> getCategories(String? gender) {
    if (gender == 'Female') return womenSizes;
    return menSizes;
  }
}
